import 'package:day_loop/services/auth_state_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'main_shell.dart';
import 'pages/home_screen.dart';
import 'pages/history_screen.dart';
import 'pages/settings_screen.dart';

class AppRouter {
  static final _auth = AuthStateNotifier();

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    refreshListenable: _auth,
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
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
                builder: (context, state) => const HistoryScreen(),
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