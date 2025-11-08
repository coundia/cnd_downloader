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
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

@collection
class IptvItem {
  Id id = Isar.autoIncrement;
  late int sourceId;
  late String kind;
  late String name;
  String? groupTitle;
  String? logo;
  late String streamUrl;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
