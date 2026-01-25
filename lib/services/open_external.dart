import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

final class ExternalPlayer {
  static Future<void> open(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) throw ArgumentError('url is empty');

    if (Platform.isMacOS) {
      if (await _openMacApp('VLC', cleanUrl)) return;
      if (await _openMacApp('IINA', cleanUrl)) return;
      await _openDefault(cleanUrl);
      return;
    }

    if (Platform.isWindows) {
      if (await _openWindowsApp(cleanUrl, ['vlc.exe', 'vlc', 'VLC'])) return;
      await _openDefault(cleanUrl);
      return;
    }

    if (Platform.isLinux) {
      if (await _openLinuxApp(cleanUrl, ['vlc'])) return;
      await _openDefault(cleanUrl);
      return;
    }

    await _openDefault(cleanUrl);
  }

  static Future<void> _openDefault(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) throw Exception('Cannot open url');
  }

  static Future<bool> _openMacApp(String appName, String url) async {
    try {
      final res = await Process.run('open', ['-a', appName, url]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _openWindowsApp(
    String url,
    List<String> candidates,
  ) async {
    for (final exe in candidates) {
      try {
        final res = await Process.run(exe, [url], runInShell: true);
        if (res.exitCode == 0) return true;
      } catch (_) {}
    }
    return false;
  }

  static Future<bool> _openLinuxApp(String url, List<String> candidates) async {
    for (final exe in candidates) {
      try {
        final res = await Process.run(exe, [url]);
        if (res.exitCode == 0) return true;
      } catch (_) {}
    }
    return false;
  }
}
