import 'package:day_loop/pages/splash_screen.dart';
import 'package:day_loop/route_observer.dart';
import 'package:day_loop/services/auth_state_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/history_day_details_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'main_shell.dart';
import 'pages/home_screen.dart';
import 'pages/history_screen.dart';
import 'pages/settings_screen.dart';

// 👇 add this import

class AppRouter {
  static final _auth = AuthStateNotifier();

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    refreshListenable: _auth,

    // 👇 register the global RouteObserver so RouteAware screens can subscribe
    observers: [routeObserver],

    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) =>
            const AppSplash(), // Use the custom AppSplash widget
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(
            navigationShell: navigationShell,
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                pageBuilder: (context, state) {
                  // Check if the clearStack flag is set
                  final clearStack = state.extra is Map && (state.extra as Map)['clearStack'] == true;
                  return NoTransitionPage(
                    key: clearStack ? UniqueKey() : const ValueKey('history-root'),
                    child: const HistoryScreen(),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'day/:date',
                    name: 'history-day',
                    pageBuilder: (context, state) {
                      final dateStr = state.pathParameters['date']!;
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: HistoryDayDetailsPage(dateStr: dateStr),
                        transitionDuration: const Duration(milliseconds: 180),
                        reverseTransitionDuration: const Duration(milliseconds: 160),
                        transitionsBuilder: (context, animation, secondary, child) {
                          final curve = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          );
                          return FadeTransition(
                            opacity: curve,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.98, end: 1.0).animate(curve),
                              child: child,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      if (!_auth.isReady) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }

      final loggedIn = _auth.isLoggedIn;
      final loc = state.matchedLocation;
      final onSplash = loc == '/splash';
      final onLogin = loc == '/login';
      final onSignup = loc == '/signup';

      if (!loggedIn) {
        return (onLogin || onSignup) ? null : '/login';
      }

      if (onLogin || onSplash || onSignup) return '/home';

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Routing error:\n${state.error}',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
