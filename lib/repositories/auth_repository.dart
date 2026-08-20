import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../services/supabase_service.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Sole point of contact with Supabase Auth. Screens/providers should
/// never call `Supabase.instance.client.auth` directly — always go
/// through this repository so the auth surface stays testable and
/// centrally controlled.
class AuthRepository {
  AuthRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Future<void> signInWithPassword({
    required String phoneOrEmail,
    required String password,
  }) async {
    try {
      // Accounts are provisioned by the Owner with an email address
      // (phone-based OTP can be swapped in later without changing this
      // repository's public surface).
      await _client.auth.signInWithPassword(
        email: phoneOrEmail,
        password: password,
      );
    } on AuthApiException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      throw AuthException(
          'Login failed. Please check your connection and try again.');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Fetches the current user's profile row (role, active status).
  /// Throws [AuthException] if no profile exists yet — this should be
  /// rare, since a profile is created automatically on signup, but the
  /// app must never assume a logged-in user has a valid role.
  Future<Profile> fetchCurrentProfile() async {
    final user = currentUser;
    if (user == null) {
      throw AuthException('Not signed in.');
    }

    final response =
        await _client.from('profiles').select().eq('id', user.id).maybeSingle();

    if (response == null) {
      throw AuthException(
        'No profile found for this account. Contact the shop owner.',
      );
    }

    return Profile.fromJson(response);
  }

  String _mapAuthError(AuthApiException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Incorrect phone/email or password.';
    }
    if (message.contains('email not confirmed')) {
      return 'Account not yet activated. Contact the shop owner.';
    }
    return 'Login failed: ${e.message}';
  }
}
