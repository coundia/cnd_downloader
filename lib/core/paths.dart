import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> defaultDownloadDir() async {
  try {
    final d = await getDownloadsDirectory();
    if (d != null) return d.path;
  } catch (_) {}
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null) {
    final dl = Directory('$home/Downloads');
    if (await dl.exists()) return dl.path;
  }
  final docs = await getApplicationDocumentsDirectory();
  return docs.path;
}
