import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:shop_stock_app/models/profile.dart';
import 'package:shop_stock_app/models/user_role.dart';
import 'package:shop_stock_app/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

class MockSupabaseClient extends Mock implements SupabaseClient {}

/// Test double for [AuthRepository]. Overrides every public member so
/// that the underlying (mocked, never-initialized) SupabaseClient is
/// never actually touched — tests exercise the app's auth *wiring*
/// (providers, router redirects) without making real network calls.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({
    this.signedIn = false,
    this.profile,
    this.profileError,
  }) : super(client: MockSupabaseClient());

  bool signedIn;
  Profile? profile;
  Object? profileError;

  final _controller = StreamController<AuthState>.broadcast();

  void emitAuthChange(AuthState state) => _controller.add(state);

  @override
  Stream<AuthState> get authStateChanges => _controller.stream;

  @override
  bool get isAuthenticated => signedIn;

  @override
  User? get currentUser => null;

  @override
  Future<void> signInWithPassword({
    required String phoneOrEmail,
    required String password,
  }) async {
    if (phoneOrEmail.isEmpty || password.isEmpty) {
      throw AuthException('Incorrect phone/email or password.');
    }
    signedIn = true;
  }

  @override
  Future<void> signOut() async {
    signedIn = false;
  }

  @override
  Future<Profile> fetchCurrentProfile() async {
    if (profileError != null) {
      throw profileError!;
    }
    return profile ??
        Profile(
          id: 'fake-user',
          name: 'Test User',
          role: UserRole.staff,
          isActive: true,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        );
  }

  void dispose() => _controller.close();
}
