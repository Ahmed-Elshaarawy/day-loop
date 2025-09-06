import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Listenable that triggers router refreshes when auth changes.
class AuthStateNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _sub;

  bool _ready = false;
  bool get isReady => _ready;
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  AuthStateNotifier() {
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