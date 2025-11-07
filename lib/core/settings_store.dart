import 'package:shared_preferences/shared_preferences.dart';
import 'settings.dart';

class SettingsStore {
  static const _kSegments = 'segments_per_file';
  static const _kPartSize = 'part_size_bytes';
  static const _kMaxActive = 'max_active_files';
  static const _kUA = 'default_user_agent';
  static const _kRef = 'default_referer';
  static const _kDir = 'download_dir';
  static const _kConn = 'connect_timeout_ms';
  static const _kRecv = 'receive_timeout_ms';
  static const _kSmooth = 'speed_smoothing';

  Future<RuntimeSettings> load() async {
    final sp = await SharedPreferences.getInstance();
    return RuntimeSettings(
      segmentsPerFile: sp.getInt(_kSegments) ?? settings.segmentsPerFile,
      partSizeBytes: sp.getInt(_kPartSize) ?? settings.partSizeBytes,
      maxActiveFiles: sp.getInt(_kMaxActive) ?? settings.maxActiveFiles,
      defaultUserAgent: sp.getString(_kUA) ?? settings.defaultUserAgent,
      defaultReferer: sp.getString(_kRef) == '' ? null : sp.getString(_kRef),
      downloadDir: sp.getString(_kDir),
      connectTimeoutMs: sp.getInt(_kConn) ?? settings.connectTimeoutMs,
      receiveTimeoutMs: sp.getInt(_kRecv) ?? settings.receiveTimeoutMs,
      speedSmoothing: sp.getDouble(_kSmooth) ?? settings.speedSmoothing,
    );
  }

  Future<void> save(RuntimeSettings s) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kSegments, s.segmentsPerFile);
    await sp.setInt(_kPartSize, s.partSizeBytes);
    await sp.setInt(_kMaxActive, s.maxActiveFiles);
    await sp.setString(_kUA, s.defaultUserAgent);
    await sp.setString(_kRef, s.defaultReferer ?? '');
    if (s.downloadDir == null || s.downloadDir!.isEmpty) {
      await sp.remove(_kDir);
    } else {
      await sp.setString(_kDir, s.downloadDir!);
    }
    await sp.setInt(_kConn, s.connectTimeoutMs);
    await sp.setInt(_kRecv, s.receiveTimeoutMs);
    await sp.setDouble(_kSmooth, s.speedSmoothing);
  }
}
