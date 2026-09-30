import 'package:dairy_sacco_mobile/core/cache/response_cache.dart';
import 'package:dairy_sacco_mobile/core/errors/failure.dart';
import 'package:dairy_sacco_mobile/core/network/dio_client.dart';
import 'package:dairy_sacco_mobile/core/storage/secure_storage_service.dart';
import 'package:dairy_sacco_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:dairy_sacco_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:dairy_sacco_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = UserEntity(id: 3, email: 'c@x.io', username: 'col');

class _Storage extends SecureStorageService {
  _Storage() : super(const FlutterSecureStorage());
  @override
  Future<String?> getToken() async => 'token';
}

class _Repo extends Fake implements AuthRepository {
  bool idleExpired = false;
  bool serverReachable = false;
  final loggedOut = <bool>[];

  @override
  Future<bool> sessionIdleExpired() async => idleExpired;
  @override
  Future<UserEntity?> savedUser() async => _user;
  @override
  Future<UserEntity?> getCurrentUser() async =>
      serverReachable ? _user : throw const ServerUnreachableException();
  @override
  Future<void> logout({bool notifyServer = true}) async =>
      loggedOut.add(notifyServer);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerFor(_Repo repo) => ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      secureStorageServiceProvider.overrideWithValue(_Storage()),
      responseCacheProvider.overrideWithValue(null),
    ],
  );

  test('opens at once from the saved profile, even with no signal', () async {
    final repo = _Repo();
    final c = containerFor(repo);
    addTearDown(c.dispose);
    final state = await c.read(authControllerProvider.future);
    expect(state.isAuthenticated, isTrue);
    expect(state.user?.id, 3);
    await Future<void>.delayed(Duration.zero); // background check runs
    expect(c.read(authControllerProvider).value?.isAuthenticated, isTrue);
    expect(repo.loggedOut, isEmpty);
  });

  test('a session idle past the limit opens on login with a reason', () async {
    final repo = _Repo()..idleExpired = true;
    final c = containerFor(repo);
    addTearDown(c.dispose);
    final state = await c.read(authControllerProvider.future);
    expect(state.isAuthenticated, isFalse);
    expect(state.errorMessage, contains('not used for a long time'));
    expect(repo.loggedOut, [false], reason: 'cleared locally, no request');
  });

  test(
    'clearing saved data is safe without storage (tests, first run)',
    () async {
      await ResponseCache.clearAll();
    },
  );
}
