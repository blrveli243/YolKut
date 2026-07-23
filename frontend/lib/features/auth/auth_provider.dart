import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

enum AuthState { initial, loading, success, error }

class AuthNotifier extends Notifier<AuthState> {
  String? errorMessage;

  @override
  AuthState build() {
    return AuthState.initial;
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading;
    errorMessage = null;
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.login(email, password);
      state = AuthState.success;
    } catch (e) {
      errorMessage = 'Giriş başarısız. Lütfen bilgilerinizi kontrol edin.';
      state = AuthState.error;
    }
  }

  Future<void> register(String email, String password) async {
    state = AuthState.loading;
    errorMessage = null;
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.register(email, password);
      state = AuthState.success;
    } catch (e) {
      errorMessage =
          'Kayıt başarısız. E-posta adresi sistemde kayıtlı olabilir.';
      state = AuthState.error;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

final authCheckProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  return await repo.verifyToken();
});
