// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:day_loop/main.dart'; // exposes DayLoopApp

void main() {
  testWidgets('auth flow smoke test: login -> signup -> back to login', (tester) async {
    // Launch app
    await tester.pumpWidget(const DayLoopApp());
    await tester.pumpAndSettle();

    // Login page is the start
    expect(find.text('Login'), findsOneWidget);
    expect(find.text("Don't have an account? Sign up"), findsOneWidget);

    // Go to Sign Up
    await tester.tap(find.text("Don't have an account? Sign up"));
    await tester.pumpAndSettle();

    // Sign Up page visible
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Already have an account? Sign in'), findsOneWidget);

    // Back to Login
    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pumpAndSettle();

    // Login page again
    expect(find.text('Login'), findsOneWidget);
  });
}
