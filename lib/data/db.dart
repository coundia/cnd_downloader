import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'download_models.dart';
import 'iptv_models.dart';

class AppDb {
  static late Isar isar;

  static Future<void> open() async {
    final dir = await getApplicationSupportDirectory();
    isar = await Isar.open(
      [
        DownloadTaskSchema,
        DownloadPartSchema,
        DownloadLogSchema,
        IptvSourceSchema,
        IptvItemSchema,
      ],
      directory: dir.path,
      inspector: true,
    );
  }
}
