class AppSettings {
  String defaultUserAgent = 'fastdown/1.0';
  String? defaultReferer;
  int maxActiveFiles = 3;
  int segmentsPerFile = 8;
  int partSizeBytes = 2 * 1024 * 1024;
  int connectTimeoutMs = 20000;
  int receiveTimeoutMs = 60000;
  int retries = 5;
  double speedSmoothing = 0.3;
}

final settings = AppSettings();
