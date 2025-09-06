import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart' as gsi;

/// Centralized authentication service (Firebase Auth + Google Sign-In)
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// google_sign_in instance (used on Android/iOS/macOS/Windows)
  /// NOTE: This is the *package:google_sign_in* class (NOT the platform interface).
  final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  // Stream to listen to auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ---------- Email/Password ----------
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    bool sendVerificationEmail = true,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (displayName != null && displayName.isNotEmpty) {
        await cred.user!.updateDisplayName(displayName);
      }

      return cred;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFromCode(e), code: e.code);
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFromCode(e), code: e.code);
    }
  }

  // ---------- Google Sign-In (Web + Mobile/Desktop) ----------
  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web uses FirebaseAuth popup with Google provider
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');

        return await _auth.signInWithPopup(provider);
      } else {
        // Mobile/desktop uses the google_sign_in package
        final gsi.GoogleSignInAccount? gUser = await _googleSignIn.signIn();
        if (gUser == null) {
          throw const AuthException('Sign-in aborted by user', code: 'aborted');
        }

        // IMPORTANT: this returns a Future — must be awaited
        final gsi.GoogleSignInAuthentication gAuth = await gUser.authentication;

        // Both accessToken and idToken are exposed by package:google_sign_in
        final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFromCode(e), code: e.code);
    } catch (e) {
      // Handles google_sign_in runtime errors too
      throw AuthException(e.toString(), code: 'google_sign_in_error');
    }
  }

  // ---------- Common helpers ----------
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFromCode(e), code: e.code);
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        // Also sign out from Google on mobile/desktop if used
        await _googleSignIn.signOut().catchError((_) {});
      }
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFromCode(e), code: e.code);
    }
  }

  // ---------- Error mapping ----------
  String _messageFromCode(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'That password is too weak.';
      case 'popup-closed-by-user':
        return 'The sign-in popup was closed before completing.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}

// Lightweight error type for your UI
class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException(this.message, {this.code});
  @override
  String toString() => message;
}
