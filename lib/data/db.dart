import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'download_models.dart';

class AppDb {
  static Isar? _isar;
  static Future<Isar> open() async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationSupportDirectory();
    _isar = await Isar.open([
      DownloadTaskSchema,
      DownloadPartSchema,
      DownloadLogSchema,
    ], directory: dir.path);
    return _isar!;
  }

  static Isar get isar => _isar!;
}
