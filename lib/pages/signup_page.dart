import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextField(decoration: InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              const TextField(decoration: InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              const TextField(decoration: InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  // TODO: create account, log in, save token
                  context.go('/home');
                },
                child: const Text('Create account'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
