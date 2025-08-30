import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/home_screen.dart';
import 'pages/morning_screen.dart';
import 'pages/evening_screen.dart';
import 'pages/history_screen.dart';
import 'pages/detail_screen.dart';
import 'pages/settings_screen.dart';

/// Single app-wide router. You can add guards later if you add real auth.
final router = GoRouter(
  initialLocation: '/login',
  routes: [
    // ---- Auth flow ----
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

    // ---- Main app ----
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/morning',
      name: 'morning',
      builder: (context, state) => const MorningScreen(),
    ),
    GoRoute(
      path: '/evening',
      name: 'evening',
      builder: (context, state) => const EveningScreen(),
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/detail/:id',
      name: 'detail',
      builder: (context, state) =>
          DetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
