import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/profile.dart';
import '../../../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Raw Supabase auth state stream (signed in / signed out / token
/// refreshed). The router and app shell listen to this to decide
/// whether the protected area is reachable at all.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// The current user's profile (role + active status), loaded once a
/// session exists. This is deliberately a *separate* async step from
/// "is authenticated" — a valid session with no active profile must
/// NOT be treated as access to the app.
final currentProfileProvider = FutureProvider<Profile>((ref) async {
  // Re-fetch whenever the auth state changes (login/logout/refresh).
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).fetchCurrentProfile();
});

/// Convenience bool the UI can use without unwrapping AsyncValue
/// everywhere.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider).isAuthenticated;
});
