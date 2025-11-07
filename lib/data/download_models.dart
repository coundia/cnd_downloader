import 'package:isar/isar.dart';

part 'download_models.g.dart';

@collection
class DownloadTask {
  Id id = Isar.autoIncrement;
  late String url;
  String? referer;
  String? userAgent;
  late String fileName;
  late String savePath;
  late String tempPath;
  int total = 0;
  int downloaded = 0;
  bool acceptRanges = false;
  String state = 'queued';
  double speedBps = 0;
  int etaSeconds = 0;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

@collection
class DownloadPart {
  Id id = Isar.autoIncrement;
  late int taskId;
  late int index;
  late int start;
  late int end;
  int downloaded = 0;
  String state = 'idle';
}
