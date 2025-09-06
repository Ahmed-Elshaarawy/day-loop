import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:day_loop/auth/auth_service.dart';
import 'package:day_loop/l10n/app_localizations.dart';
import 'package:day_loop/widgets/language_switcher_button.dart';
import 'package:day_loop/widgets/custom_text_field.dart';
import 'package:day_loop/widgets/gradient_elevated_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = '';
  String password = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

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
                  Text(
                    localizations.welcomeBack,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    labelText: localizations.email,
                    icon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) => setState(() => email = v.trim()),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    labelText: localizations.password,
                    icon: Icons.lock,
                    obscureText: true,
                    onChanged: (v) => setState(() => password = v),
                  ),
                  const SizedBox(height: 24),
                  GradientElevatedButton(
                    colors: const [Color(0xFFFF9800), Color(0xFFFF5722)],
                    onPressed: _loading
                        ? null
                        : () async {
                      setState(() => _loading = true);
                      try {
                        final cred = await AuthService.instance.signInWithEmail(email: email, password: password);
                        if (!mounted) return;
                        if (cred.user != null) {
                          context.go('/home');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sign-in failed.')),
                          );
                        }
                      } on AuthException catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
                        : Text(
                      localizations.signIn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: Text(
                      localizations.dontHaveAccount,
                      style: const TextStyle(
                        color: Color(0xFFFF5722),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(
                        child: Divider(color: Color(0xFF333333), thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Color(0xFF333333), thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await AuthService.instance.signInWithGoogle();
                          if (!context.mounted) return;
                          context.go('/home');
                        } on AuthException catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 22),
                          Text(
                            localizations.continueWithGoogle,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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