import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/m3u_parser.dart';
import '../data/iptv_models.dart';
import '../core/settings.dart';

Future<List<IptvItem>> parseM3uInIsolate(String content, int sourceId, {
  required String defaultUserAgent,
  required String? defaultReferer,
}) async {
  return compute(_parseM3uIsolateEntryPoint, _ParseArgs(
    content: content,
    sourceId: sourceId,
    defaultUserAgent: defaultUserAgent,
    defaultReferer: defaultReferer,
  ));
}

class _ParseArgs {
  final String content;
  final int sourceId;
  final String defaultUserAgent;
  final String? defaultReferer;

  _ParseArgs({
    required this.content,
    required this.sourceId,
    required this.defaultUserAgent,
    required this.defaultReferer,
  });
}

List<IptvItem> _parseM3uIsolateEntryPoint(_ParseArgs args) {
  final parser = M3uParser();
  final doc = parser.parseDocument(args.content);
  
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
    
    if (args.defaultUserAgent.trim().isNotEmpty && headers['user-agent'] == null) {
      headers['user-agent'] = args.defaultUserAgent.trim();
    }
    if ((args.defaultReferer ?? '').trim().isNotEmpty && headers['referer'] == null) {
      headers['referer'] = args.defaultReferer!.trim();
    }
    
    final headersJson = headers.isEmpty ? null : jsonEncode(headers);

    final it = IptvItem()
      ..sourceId = args.sourceId
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
  return items;
}
