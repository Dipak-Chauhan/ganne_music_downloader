import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage() : _storage = const FlutterSecureStorage();

  static const String _keyAppId = 'qobuz_app_id';
  static const String _keyAppSecret = 'qobuz_app_secret';
  static const String _keyUserAuthToken = 'qobuz_user_auth_token';

  Future<void> saveCredentials({
    required String appId,
    required String appSecret,
    required String userAuthToken,
  }) async {
    await _storage.write(key: _keyAppId, value: appId);
    await _storage.write(key: _keyAppSecret, value: appSecret);
    await _storage.write(key: _keyUserAuthToken, value: userAuthToken);
  }

  Future<Map<String, String?>> getCredentials() async {
    final appId = await _storage.read(key: _keyAppId);
    final appSecret = await _storage.read(key: _keyAppSecret);
    final userAuthToken = await _storage.read(key: _keyUserAuthToken);
    
    return {
      'appId': appId,
      'appSecret': appSecret,
      'userAuthToken': userAuthToken,
    };
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyAppId);
    await _storage.delete(key: _keyAppSecret);
    await _storage.delete(key: _keyUserAuthToken);
  }

  // ── Generic read/write for app settings ──
  Future<void> writeKey(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> readKey(String key) async {
    return await _storage.read(key: key);
  }

  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}
