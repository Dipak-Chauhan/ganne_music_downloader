import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  AuthState({this.isAuthenticated = false, this.isLoading = true, this.error});
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkStatus();
    return AuthState(isLoading: true);
  }

  Future<void> _checkStatus() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final creds = await storage.getCredentials();

      if ((creds['appId']?.isNotEmpty ?? false) &&
          (creds['userAuthToken']?.isNotEmpty ?? false) &&
          (creds['appSecret']?.isNotEmpty ?? false)) {
        state = AuthState(isAuthenticated: true, isLoading: false);
      } else {
        state = AuthState(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: 'Unable to access saved credentials: $e',
      );
    }
  }

  Future<bool> login(String appId, String appSecret, String token) async {
    state = AuthState(isLoading: true);
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.saveCredentials(
        appId: appId,
        appSecret: appSecret,
        userAuthToken: token,
      );

      // Perform a test API call to ensure credentials are valid
      final repo = ref.read(qobuzServiceProvider);
      // test API
      await repo.search("test", limit: 1, offset: 0);

      state = AuthState(isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      final storage = ref.read(secureStorageProvider);
      await storage.clearCredentials();
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    await storage.clearCredentials();
    state = AuthState(isAuthenticated: false, isLoading: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
