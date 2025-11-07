import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/settings.dart';

class SettingsVm extends StateNotifier<AppSettings> {
  SettingsVm() : super(settings);
  void setSegments(int v) {
    state.segmentsPerFile = v;
  }

  void setPartSize(int bytes) {
    state.partSizeBytes = bytes;
  }

  void setMaxActive(int v) {
    state.maxActiveFiles = v;
  }

  void setUa(String ua) {
    state.defaultUserAgent = ua;
  }

  void setReferer(String? r) {
    state.defaultReferer = r;
  }
}

final settingsVmProvider = StateNotifierProvider<SettingsVm, AppSettings>(
  (ref) => SettingsVm(),
);
