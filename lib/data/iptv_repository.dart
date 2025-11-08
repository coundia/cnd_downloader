import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import '../services/m3u_parser.dart';
import 'iptv_models.dart';
import 'db.dart';

class IptvRepository {
  final Isar _isar = AppDb.isar;
  final Dio _dio;
  final M3uParser _parser = M3uParser();

  IptvRepository(this._dio);

  Stream<List<IptvItem>> watchLive() =>
      _isar.iptvItems.filter().kindEqualTo('live').watch(fireImmediately: true);
  Stream<List<IptvItem>> watchMovies() => _isar.iptvItems
      .filter()
      .kindEqualTo('movie')
      .watch(fireImmediately: true);
  Stream<List<IptvItem>> watchSeries() => _isar.iptvItems
      .filter()
      .kindEqualTo('series')
      .watch(fireImmediately: true);

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
    final entries = _parser.parse(data);
    await _isar.writeTxn(() async {
      final oldIds = await _isar.iptvItems
          .filter()
          .sourceIdEqualTo(sourceId)
          .idProperty()
          .findAll();
      await _isar.iptvItems.deleteAll(oldIds);
      final items = entries
          .map(
            (e) => IptvItem()
              ..sourceId = sourceId
              ..kind = e.kind
              ..name = e.name
              ..groupTitle = e.group
              ..logo = e.logo
              ..streamUrl = e.url,
          )
          .toList();
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
