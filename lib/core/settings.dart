class RuntimeSettings {
  int segmentsPerFile;
  int partSizeBytes;
  int maxActiveFiles;
  String defaultUserAgent;
  String? defaultReferer;
  String? downloadDir;
  int connectTimeoutMs;
  int receiveTimeoutMs;
  double speedSmoothing;

  // NEW
  String? omdbApiKey;

  RuntimeSettings({
    this.segmentsPerFile = 1,
    this.partSizeBytes = 10 * 1024 * 1024,
    this.maxActiveFiles = 2,
    this.defaultUserAgent = 'VLC/3.0.21 LibVLC/3.0.21',
    this.defaultReferer,
    this.downloadDir,
    this.connectTimeoutMs = 10000,
    this.receiveTimeoutMs = 30000,
    this.speedSmoothing = 0.2,
    this.omdbApiKey = '7cbf4e64',
  });

  // NEW: renvoie la clé paramétrée ou celle passée en --dart-define
  String get omdbKeyOrEnv {
    final k = omdbApiKey?.trim();
    if (k != null && k.isNotEmpty) return k;
    const fromEnv = String.fromEnvironment('OMDB_API_KEY', defaultValue: '');
    return fromEnv;
  }

  RuntimeSettings copyWith({
    int? segmentsPerFile,
    int? partSizeBytes,
    int? maxActiveFiles,
    String? defaultUserAgent,
    String? defaultReferer,
    String? downloadDir,
    int? connectTimeoutMs,
    int? receiveTimeoutMs,
    double? speedSmoothing,
    String? omdbApiKey, // NEW
  }) {
    return RuntimeSettings(
      segmentsPerFile: segmentsPerFile ?? this.segmentsPerFile,
      partSizeBytes: partSizeBytes ?? this.partSizeBytes,
      maxActiveFiles: maxActiveFiles ?? this.maxActiveFiles,
      defaultUserAgent: defaultUserAgent ?? this.defaultUserAgent,
      defaultReferer: defaultReferer ?? this.defaultReferer,
      downloadDir: downloadDir ?? this.downloadDir,
      connectTimeoutMs: connectTimeoutMs ?? this.connectTimeoutMs,
      receiveTimeoutMs: receiveTimeoutMs ?? this.receiveTimeoutMs,
      speedSmoothing: speedSmoothing ?? this.speedSmoothing,
      omdbApiKey: omdbApiKey ?? this.omdbApiKey, // NEW
    );
  }

  static RuntimeSettings from(RuntimeSettings s) => s.copyWith();
}

// inchangé
final settings = RuntimeSettings();
