import 'package:day_loop/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:day_loop/widgets/language_switcher_button.dart';
import 'package:day_loop/widgets/gradient_elevated_button.dart';

import '../widgets/custom_text_field.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  String name = '';
  String email = '';
  String password = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 16.0),
              child: LanguageSwitcherButton(),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'DayLoop',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Create Your Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          labelText: 'Name',
                          icon: Icons.person,
                          onChanged: (v) => name = v.trim(),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          labelText: 'Email',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (v) => email = v.trim(),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          labelText: 'Password',
                          icon: Icons.lock,
                          obscureText: true,
                          onChanged: (v) => password = v,
                        ),
                        const SizedBox(height: 24),
                        GradientElevatedButton(
                          colors: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                          onPressed: _loading
                              ? null
                              : () async {
                            if (email.trim().isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter email and password')),
                              );
                              return;
                            }
                            setState(() => _loading = true);
                            try {
                              final cred = await AuthService.instance.signUpWithEmail(email: email, password: password);
                              if (!context.mounted) return;
                              if (cred.user != null) {
                                context.go('/home');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sign-up failed.')),
                                );
                              }
                            } on AuthException catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          },
                          child: _loading
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text(
                            'Create Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text(
                            'Already have an account? Sign in',
                            style: TextStyle(
                              color: Color(0xFFFF5722),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}