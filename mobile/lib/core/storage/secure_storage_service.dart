import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});

/// SecureStorageService provides encrypted OS storage (Keychain / Keystore).
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.accessToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: StorageKeys.accessToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: StorageKeys.accessToken);
  }

  /// Saves the tokens and expiry times returned by login or refresh.
  Future<void> saveSession(SessionTokens tokens) async {
    await _storage.write(
      key: StorageKeys.accessToken,
      value: tokens.accessToken,
    );
    await _storage.write(
      key: StorageKeys.refreshToken,
      value: tokens.refreshToken,
    );
    await _storage.write(
      key: StorageKeys.accessExpiresAt,
      value: tokens.accessExpiresAt?.toIso8601String(),
    );
    await _storage.write(
      key: StorageKeys.sessionExpiresAt,
      value: tokens.sessionExpiresAt?.toIso8601String(),
    );
  }

  Future<String?> getRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken);

  Future<DateTime?> getAccessExpiresAt() async => DateTime.tryParse(
    await _storage.read(key: StorageKeys.accessExpiresAt) ?? '',
  );

  Future<DateTime?> getSessionExpiresAt() async => DateTime.tryParse(
    await _storage.read(key: StorageKeys.sessionExpiresAt) ?? '',
  );

  /// Removes everything that keeps the user signed in.
  Future<void> clearSession() async {
    for (final key in [
      StorageKeys.accessToken,
      StorageKeys.refreshToken,
      StorageKeys.accessExpiresAt,
      StorageKeys.sessionExpiresAt,
      StorageKeys.userPayload,
    ]) {
      await _storage.delete(key: key);
    }
  }

  /// The signed-in user's profile, kept so the app can start offline.
  Future<void> saveUserJson(String json) async {
    await _storage.write(key: StorageKeys.userPayload, value: json);
  }

  Future<String?> getUserJson() async {
    return await _storage.read(key: StorageKeys.userPayload);
  }

  Future<void> deleteUserJson() async {
    await _storage.delete(key: StorageKeys.userPayload);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

/// Tokens from a login or refresh response.
class SessionTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime? accessExpiresAt;
  final DateTime? sessionExpiresAt;

  const SessionTokens({
    required this.accessToken,
    required this.refreshToken,
    this.accessExpiresAt,
    this.sessionExpiresAt,
  });

  /// Reads `data` of a login or refresh response.
  factory SessionTokens.fromJson(Map<String, dynamic> data) => SessionTokens(
    accessToken: (data['access_token'] ?? data['token']) as String,
    refreshToken: (data['refresh_token'] ?? '') as String,
    accessExpiresAt: DateTime.tryParse('${data['access_expires_at'] ?? ''}'),
    sessionExpiresAt: DateTime.tryParse('${data['session_expires_at'] ?? ''}'),
  );
}
