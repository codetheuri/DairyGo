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

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
