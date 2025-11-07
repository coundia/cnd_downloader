import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/settings.dart';
import '../core/settings_store.dart';

final settingsVmProvider = StateNotifierProvider<SettingsVm, RuntimeSettings>(
  (ref) => SettingsVm(),
);

class SettingsVm extends StateNotifier<RuntimeSettings> {
  final SettingsStore _store = SettingsStore();

  SettingsVm() : super(RuntimeSettings()) {
    _init();
  }

  void _init() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWithRetry());
  }

  Future<void> _loadWithRetry() async {
    const delaysMs = [0, 150, 300, 600];
    for (final ms in delaysMs) {
      if (ms > 0) await Future.delayed(Duration(milliseconds: ms));
      try {
        final loaded = await _store.load();
        _apply(loaded);
        return;
      } on PlatformException {
        // réessaie sur macOS si le channel n’est pas prêt
        continue;
      } catch (_) {
        // autre erreur: on appliquera les valeurs par défaut en fin de boucle
        break;
      }
    }
    // fallback silencieux
    _apply(RuntimeSettings());
  }

  void _apply(RuntimeSettings s) {
    settings.segmentsPerFile = s.segmentsPerFile;
    settings.partSizeBytes = s.partSizeBytes;
    settings.maxActiveFiles = s.maxActiveFiles;
    settings.defaultUserAgent = s.defaultUserAgent;
    settings.defaultReferer = s.defaultReferer;
    settings.downloadDir = s.downloadDir;
    settings.connectTimeoutMs = s.connectTimeoutMs;
    settings.receiveTimeoutMs = s.receiveTimeoutMs;
    settings.speedSmoothing = s.speedSmoothing;
    state = RuntimeSettings.from(settings);
  }

  Future<void> _save() => _store.save(state);

  void setSegments(int v) {
    final nv = v.clamp(1, 64);
    state = state.copyWith(segmentsPerFile: nv);
    _apply(state);
    _save();
  }

  void setPartSize(int bytes) {
    final nv = bytes.clamp(256 * 1024, 1024 * 1024 * 1024);
    state = state.copyWith(partSizeBytes: nv);
    _apply(state);
    _save();
  }

  void setMaxActive(int v) {
    final nv = v.clamp(1, 16);
    state = state.copyWith(maxActiveFiles: nv);
    _apply(state);
    _save();
  }

  void setUa(String v) {
    final nv = v.isEmpty ? 'FastDown/1.0' : v;
    state = state.copyWith(defaultUserAgent: nv);
    _apply(state);
    _save();
  }

  void setReferer(String? v) {
    final nv = (v == null || v.trim().isEmpty) ? null : v.trim();
    state = state.copyWith(defaultReferer: nv);
    _apply(state);
    _save();
  }

  void setDownloadDir(String? v) {
    final nv = (v == null || v.trim().isEmpty) ? null : v.trim();
    state = state.copyWith(downloadDir: nv);
    _apply(state);
    _save();
  }
}
