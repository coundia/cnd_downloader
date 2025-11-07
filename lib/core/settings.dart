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

  RuntimeSettings({
    this.segmentsPerFile = 1,
    this.partSizeBytes = 10 * 1024 * 1024,
    this.maxActiveFiles = 2,
    this.defaultUserAgent = 'FastDown/1.0',
    this.defaultReferer,
    this.downloadDir,
    this.connectTimeoutMs = 10000,
    this.receiveTimeoutMs = 30000,
    this.speedSmoothing = 0.2,
  });

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
    );
  }

  static RuntimeSettings from(RuntimeSettings s) => s.copyWith();
}

final settings = RuntimeSettings();
