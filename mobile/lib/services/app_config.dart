class AppConfig {
  static const String _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static String? get googleServerClientId =>
      _googleServerClientId.trim().isEmpty ? null : _googleServerClientId.trim();
}
