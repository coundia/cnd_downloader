import 'package:isar/isar.dart';

part 'iptv_models.g.dart';

@collection
class IptvSource {
  Id id = Isar.autoIncrement;
  late String name;
  late String type;
  String? server;
  String? username;
  String? password;
  String? url;
  String? urlTvg;
  String? provider;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

@collection
class IptvItem {
  Id id = Isar.autoIncrement;

  @Index()
  late int sourceId;

  @Index()
  late String kind;

  @Index(caseSensitive: false)
  late String name;

  String? nameOriginal;
  String? groupTitle;

  String? tvgId;
  String? tvgName;
  String? logo;

  String? country;
  String? language;

  int? chno;

  String? catchup;
  String? catchupSource;
  int? catchupDays;

  String? epgShift;

  String? userAgent;
  String? referer;
  String? headersJson;

  @Index(caseSensitive: false)
  late String host;
  String? scheme;
  String? path;
  String? ext;

  // NEW: IMDb info (nullable)
  @Index(caseSensitive: false)
  String? imdbId; // e.g. tt0800369
  double? imdbRating; // 0..10
  String? imdbDescription; // short text if present in playlist
  String? realUrl;

  late String streamUrl;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
