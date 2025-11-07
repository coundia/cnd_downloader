import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'settings.dart';

Future<String> defaultDownloadDir() async {
  final pref = settings.downloadDir;
  if (pref != null && pref.isNotEmpty) return pref;
  final d = await getDownloadsDirectory();
  if (d != null) return d.path;
  final doc = await getApplicationDocumentsDirectory();
  return '${doc.path}/Downloads';
}
