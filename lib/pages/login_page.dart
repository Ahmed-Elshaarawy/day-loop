import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              const TextField(decoration: InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  // TODO: validate, call API, store auth token
                  context.go('/home'); // replace stack (like popUpTo inclusive)
                },
                child: const Text('Sign in'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/signup'),
                child: const Text("Don't have an account? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
