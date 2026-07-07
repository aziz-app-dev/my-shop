import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../services/firebase/firebase_auth_service.dart';

/// UI state for the login / register screens.
class AuthState {
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.isLoading = false, this.errorMessage});

  AuthState copyWith({bool? isLoading, String? errorMessage}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      // Pass errorMessage explicitly (including null) to clear it.
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  bool get isSignedIn => _authService.isSignedIn;
  User? get currentUser => _authService.currentUser;

  /// Register and return the new user, or null on failure (error surfaced in
  /// state.errorMessage).
  Future<User?> register({
    required String email,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      final user = await _authService.register(
        email: email,
        password: password,
      );
      state = const AuthState();
      return user;
    } on AuthFailure catch (e) {
      state = AuthState(errorMessage: e.message);
      return null;
    } catch (e) {
      state = AuthState(errorMessage: e.toString());
      return null;
    }
  }

  /// Login and return the user, or null on failure.
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      final user = await _authService.login(email: email, password: password);
      state = const AuthState();
      return user;
    } on AuthFailure catch (e) {
      state = AuthState(errorMessage: e.message);
      return null;
    } catch (e) {
      state = AuthState(errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AuthState(isLoading: true);
    try {
      await _authService.sendPasswordReset(email);
      state = const AuthState();
      return true;
    } on AuthFailure catch (e) {
      state = AuthState(errorMessage: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (ref) => FirebaseAuthService(),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(firebaseAuthServiceProvider)),
);

/// Streams Firebase auth-state changes (sign-in / sign-out). Used by the splash
/// to decide whether to route to home or the login screen.
final authStateChangesProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthServiceProvider).authStateChanges(),
);
