class NetworkConfig {
  static const String _defaultApiBaseUrl = 'http://10.0.2.2:5000';
  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'NETWORK_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );

  static String get apiBaseUrl => _normalizeUrl(_configuredApiBaseUrl);
  static String get socketUrl => apiBaseUrl;
  static String get healthPath => '/health';
  static String get pingPath => '/ping';

  static String _normalizeUrl(String rawUrl) {
    return rawUrl.endsWith('/')
        ? rawUrl.substring(0, rawUrl.length - 1)
        : rawUrl;
  }
}
