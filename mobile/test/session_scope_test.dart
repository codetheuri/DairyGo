import 'package:dairy_sacco_mobile/core/network/dio_client.dart';
import 'package:dairy_sacco_mobile/features/auth/domain/entities/auth_state.dart';
import 'package:dairy_sacco_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:dairy_sacco_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuth extends AuthController {
  @override
  Future<AuthState> build() async => AuthState.unauthenticated();

  void signIn(int id) => state = AsyncValue.data(
    AuthState.authenticated(
      user: UserEntity(id: id, email: 'u$id@x', username: 'u$id'),
      token: 't',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('data client is rebuilt when the signed-in user changes', () async {
    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(_FakeAuth.new)],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    final auth = container.read(authControllerProvider.notifier) as _FakeAuth;

    auth.signIn(1);
    final first = container.read(dioClientProvider);
    expect(
      container.read(dioClientProvider),
      same(first),
      reason: 'stable within a session',
    );

    auth.signIn(2);
    expect(container.read(dioClientProvider), isNot(same(first)));
  });

  test('expireSession signs out once with a message', () async {
    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(_FakeAuth.new)],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    final auth = container.read(authControllerProvider.notifier) as _FakeAuth;

    auth.signIn(1);
    auth.expireSession();
    final state = container.read(authControllerProvider).value!;
    expect(state.isAuthenticated, isFalse);
    expect(state.errorMessage, isNotNull);
    expect(container.read(sessionUserIdProvider), isNull);
  });
}
