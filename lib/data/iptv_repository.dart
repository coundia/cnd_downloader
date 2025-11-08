import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import '../services/m3u_parser.dart';
import 'iptv_models.dart';
import 'db.dart';
import '../core/settings.dart';

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
    final doc = _parser.parseDocument(data);

    src.urlTvg = doc.header['url-tvg'] ?? src.urlTvg;
    src.provider = doc.header['provider-name'] ?? src.provider;

    final items = <IptvItem>[];
    for (final e in doc.entries) {
      final u = Uri.tryParse(e.url);
      final host = u?.host ?? '';
      final scheme = u?.scheme;
      final path = u?.path;
      final ext = path != null && path.contains('.')
          ? path.split('.').last.toLowerCase()
          : null;

      final headers = <String, String>{};
      if ((e.userAgent ?? '').isNotEmpty) headers['user-agent'] = e.userAgent!;
      if ((e.referer ?? '').isNotEmpty) headers['referer'] = e.referer!;
      if ((settings.defaultUserAgent).trim().isNotEmpty &&
          headers['user-agent'] == null) {
        headers['user-agent'] = settings.defaultUserAgent.trim();
      }
      if ((settings.defaultReferer ?? '').trim().isNotEmpty &&
          headers['referer'] == null) {
        headers['referer'] = settings.defaultReferer!.trim();
      }
      final headersJson = headers.isEmpty ? null : jsonEncode(headers);

      final it = IptvItem()
        ..sourceId = sourceId
        ..kind = e.kind
        ..name = e.name
        ..nameOriginal = e.nameOriginal
        ..groupTitle = e.group
        ..tvgId = e.tvgId
        ..tvgName = e.tvgName
        ..logo = e.logo
        ..country = e.country
        ..language = e.language
        ..chno = e.chno
        ..catchup = e.catchup
        ..catchupSource = e.catchupSource
        ..catchupDays = e.catchupDays
        ..epgShift = e.epgShift
        ..userAgent = e.userAgent
        ..referer = e.referer
        ..headersJson = headersJson
        ..host = host
        ..scheme = scheme
        ..path = path
        ..ext = ext
        ..imdbId = e.imdbId
        ..imdbRating = e.imdbRating
        ..imdbDescription = e.imdbDescription
        ..streamUrl = e.url;

      items.add(it);
    }

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
