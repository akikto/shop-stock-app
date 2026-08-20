import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_strings.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/products/presentation/product_detail_screen.dart';
import '../../features/products/presentation/product_form_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/sale/presentation/sale_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/stock/presentation/stock_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';

const _loginPath = '/login';
const _homePath = '/';

/// Router provider. The redirect callback is the single enforcement
/// point that stops an unauthenticated user from ever reaching the
/// protected shell — regardless of which route they try to open.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: _homePath,
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final isLoggedIn = authRepository.isAuthenticated;
      final isGoingToLogin = state.matchedLocation == _loginPath;

      if (!isLoggedIn && !isGoingToLogin) {
        return _loginPath;
      }
      if (isLoggedIn && isGoingToLogin) {
        return _homePath;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: _loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: _homePath,
        builder: (context, state) => const _ProtectedAppShell(),
      ),
      GoRoute(
        path: '/products/new',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/products/:id/edit',
        builder: (context, state) => ProductEditScreen(productId: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Wraps [AppShell] with an additional profile-load gate: a valid auth
/// session alone is not enough to use the app — a corresponding
/// active profile row must also load successfully. This is what
/// prevents, e.g., a disabled account with a still-valid token from
/// reaching the protected area.
class _ProtectedAppShell extends ConsumerWidget {
  const _ProtectedAppShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: LoadingIndicator(message: 'Loading your account...')),
      // Note: kept in English intentionally — this appears before any
      // localization context is established and is a transient state.
      error: (error, _) => Scaffold(
        body: ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
      ),
      data: (profile) {
        if (!profile.isActive) {
          return Scaffold(
            body: ErrorView(
              message: AppStrings.accountDeactivated,
              onRetry: () async {
                await ref.read(authRepositoryProvider).signOut();
              },
            ),
          );
        }

        return AppShell(
          destinations: [
            ShellDestination(
              label: AppStrings.home,
              icon: Icons.storefront_outlined,
              selectedIcon: Icons.storefront,
              screen: const HomeScreen(),
            ),
            ShellDestination(
              label: AppStrings.products,
              icon: Icons.inventory_2_outlined,
              selectedIcon: Icons.inventory_2,
              screen: const ProductsScreen(),
            ),
            ShellDestination(
              label: AppStrings.sale,
              icon: Icons.point_of_sale_outlined,
              selectedIcon: Icons.point_of_sale,
              screen: const SaleScreen(),
            ),
            ShellDestination(
              label: AppStrings.stockIn,
              icon: Icons.add_box_outlined,
              selectedIcon: Icons.add_box,
              screen: const StockScreen(),
            ),
            ShellDestination(
              label: AppStrings.history,
              icon: Icons.history_outlined,
              selectedIcon: Icons.history,
              screen: const HistoryScreen(),
            ),
            ShellDestination(
              label: AppStrings.settings,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              screen: const SettingsScreen(),
            ),
          ],
        );
      },
    );
  }
}

/// Bridges a Stream (Supabase auth state changes) into a
/// [Listenable] that GoRouter can use to trigger re-evaluation of the
/// redirect logic whenever auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
