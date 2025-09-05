import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/login_page.dart';
import 'pages/signup_page.dart'; // Add this import
import 'main_shell.dart';
import 'pages/home_screen.dart';
import 'pages/history_screen.dart';
import 'pages/settings_screen.dart';

/// Listenable that triggers router refreshes when auth changes.
class _AuthStateNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _sub;

  bool _ready = false;
  bool get isReady => _ready;
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  _AuthStateNotifier() {
    // Fires once on app start, then on every auth state change.
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      _ready = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final _auth = _AuthStateNotifier();

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    refreshListenable: _auth, // re-run redirect on login/logout
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup', // Add this new route
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
      // Wait at /splash until we know auth state
      if (!_auth.isReady) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }

      final loggedIn = _auth.isLoggedIn;
      final loc = state.matchedLocation;
      final onSplash = loc == '/splash';
      final onLogin = loc == '/login';
      final onSignup = loc == '/signup'; // Add this line

      if (!loggedIn) {
        // Force unauthenticated users to /login or /signup
        return (onLogin || onSignup) ? null : '/login'; // Update this line
      }

      // Keep authenticated users away from /login, /signup, and /splash
      if (onLogin || onSplash || onSignup) return '/home'; // Update this line

      return null; // no redirect
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