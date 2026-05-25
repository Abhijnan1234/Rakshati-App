// ignore_for_file: avoid_print

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  const SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  static const String _tokenKey = 'rakshati_jwt';
  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) async {
    print('[Rakshati][Storage] Saving JWT token');
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readToken() async {
    print('[Rakshati][Storage] Reading JWT token');
    return _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    print('[Rakshati][Storage] Deleting JWT token');
    await _storage.delete(key: _tokenKey);
  }

  Future<void> writeString({
    required String key,
    required String value,
  }) async {
    print('[Rakshati][Storage] Writing key=$key');
    await _storage.write(key: key, value: value);
  }

  Future<String?> readString(String key) async {
    print('[Rakshati][Storage] Reading key=$key');
    return _storage.read(key: key);
  }

  Future<void> deleteKey(String key) async {
    print('[Rakshati][Storage] Deleting key=$key');
    await _storage.delete(key: key);
  }
}
