import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import '../services/isolate_parser.dart';
import 'iptv_models.dart';
import 'db.dart';
import '../core/settings.dart';

class IptvRepository {
  final Isar _isar = AppDb.isar;
  final Dio _dio;

  IptvRepository(this._dio);

  // Deprecated: watchLive/watchMovies/watchSeries cause full re-renders of large lists.
  // Use paginated methods instead. 
  
  Future<List<IptvItem>> findItems({
    required String kind,
    int offset = 0,
    int limit = 50,
    String query = '',
    String? group,
    String? host,
    String sortKey = 'Name',
    bool sortAsc = true,
  }) async {
    var q = _isar.iptvItems.filter().kindEqualTo(kind);

    if (query.trim().isNotEmpty) {
      final term = query.trim();
      q = q.and().group((q) => q
          .nameContains(term, caseSensitive: false)
          .or()
          .groupTitleContains(term, caseSensitive: false));
    }
    
    if (group != null && group.isNotEmpty) {
      q = q.and().groupTitleEqualTo(group);
    }

    if (host != null && host.isNotEmpty) {
      q = q.and().hostEqualTo(host);
    }
    
    // Sorting
    QueryBuilder<IptvItem, IptvItem, QAfterSortBy> sorted;
    switch (sortKey) {
      case 'Group':
        sorted = sortAsc 
            ? q.sortByGroupTitle() 
            : q.sortByGroupTitleDesc();
        break;
      case 'Host':
        sorted = sortAsc 
            ? q.sortByHost() 
            : q.sortByHostDesc();
        break;
      case 'Rating':
         sorted = sortAsc 
            ? q.sortByImdbRating() 
            : q.sortByImdbRatingDesc();
        break;
      case 'Name':
      default:
        sorted = sortAsc 
            ? q.sortByName() 
            : q.sortByNameDesc();
        break;
    }
    
    return sorted.offset(offset).limit(limit).findAll();
  }

  Future<List<String>> getGroups(String kind) async {
    final groups = await _isar.iptvItems
        .filter()
        .kindEqualTo(kind)
        .groupTitleProperty()
        .findAll();
    // Filter nulls and empty and distinct
    return groups
        .where((e) => e != null && e.isNotEmpty)
        .map((e) => e!)
        .toSet()
        .toList()
      ..sort();
  }

  Future<List<String>> getHosts(String kind) async {
    final hosts = await _isar.iptvItems
        .filter()
        .kindEqualTo(kind)
        .hostProperty()
        .findAll();
    return hosts
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<int> addM3uSource(String name, String url) async {
    final src = IptvSource()
      ..name = name
      ..type = 'm3u'
      ..url = url;
    return await _isar.writeTxn(() async => await _isar.iptvSources.put(src));
  }

  Future<int> addXtream(
    String name,
    String server,
    String username,
    String password,
  ) async {
    final m3u = _buildXtreamM3u(server, username, password);
    final src = IptvSource()
      ..name = name
      ..type = 'xtream'
      ..server = server
      ..username = username
      ..password = password
      ..url = m3u;
    return await _isar.writeTxn(() async => await _isar.iptvSources.put(src));
  }

  Future<void> refreshSource(int sourceId) async {
    final src = await _isar.iptvSources.get(sourceId);
    if (src == null || src.url == null) return;

    final data = await _fetch(src.url!);
    // M3uParser logic moved to isolate helper
    
    // Need access to settings, passing them as arguments
    final items = await parseM3uInIsolate(
      data, 
      sourceId, 
      defaultUserAgent: settings.defaultUserAgent,
      defaultReferer: settings.defaultReferer
    );

    await _isar.writeTxn(() async {
      final oldIds = await _isar.iptvItems
          .filter()
          .sourceIdEqualTo(sourceId)
          .idProperty()
          .findAll();
      await _isar.iptvItems.deleteAll(oldIds);
      await _isar.iptvItems.putAll(items);
      src.updatedAt = DateTime.now();
      await _isar.iptvSources.put(src);
    });
  }

  Future<List<IptvSource>> listSources() => _isar.iptvSources.where().findAll();

  Future<void> deleteSource(int id) async {
    await _isar.writeTxn(() async {
      final ids = await _isar.iptvItems
          .filter()
          .sourceIdEqualTo(id)
          .idProperty()
          .findAll();
      await _isar.iptvItems.deleteAll(ids);
      await _isar.iptvSources.delete(id);
    });
  }

  Future<String> _fetch(String url) async {
    final r = await _dio.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        followRedirects: true,
        maxRedirects: 10,
        headers: {
          if ((settings.defaultUserAgent).trim().isNotEmpty)
            'user-agent': settings.defaultUserAgent.trim(),
          if ((settings.defaultReferer ?? '').trim().isNotEmpty)
            'referer': settings.defaultReferer!.trim(),
        },
      ),
    );
    return r.data ?? '';
  }

  String _buildXtreamM3u(String server, String u, String p) {
    final s = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;
    return '$s/get.php?username=$u&password=$p&type=m3u_plus&output=ts';
  }
}
