import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:day_loop/l10n/app_localizations.dart';
import 'package:day_loop/widgets/language_switcher_button.dart';
import 'package:day_loop/widgets/custom_text_field.dart';
import 'package:day_loop/widgets/gradient_elevated_button.dart';

import '../auth/auth_localization.dart';
import '../auth/auth_service.dart';
import '../view_models/login_view_model.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ChangeNotifierProvider<LoginViewModel>(
      create: (_) => LoginViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Stack(
          children: [
            const Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 16.0),
                child: LanguageSwitcherButton(),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Consumer<LoginViewModel>(
                  builder: (context, vm, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.welcomeBack,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          labelText: l10n.email,
                          icon: Icons.alternate_email,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: vm.setEmail,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          labelText: l10n.password,
                          icon: Icons.lock,
                          obscureText: true,
                          onChanged: vm.setPassword,
                        ),
                        const SizedBox(height: 24),
                        GradientElevatedButton(
                          colors: const [Color(0xFFFF9800), Color(0xFFFF5722)],
                          onPressed: vm.loading
                              ? null
                              : () async {
                            final ok = await vm.signInWithEmail();
                            if (!context.mounted) return;
                            if (ok) {
                              context.go('/home');
                            } else {
                              final err = AuthException(
                                vm.error ?? '',
                                code: vm.errorCode,
                              );
                              final msg = authErrorText(l10n, err);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            }
                          },
                          child: vm.loading
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                              : Text(
                            l10n.signIn,
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
                            l10n.dontHaveAccount,
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
                              child: Divider(
                                  color: Color(0xFF333333), thickness: 1),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or', // add to l10n if you want
                                style: TextStyle(
                                    color: Color(0xFF888888), fontSize: 14),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                  color: Color(0xFF333333), thickness: 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: vm.loading
                                ? null
                                : () async {
                              final ok = await vm.signInWithGoogle();
                              if (!context.mounted) return;
                              if (ok) {
                                context.go('/home');
                              } else {
                                final err = AuthException(
                                  vm.error ?? '',
                                  code: vm.errorCode,
                                );
                                final msg = authErrorText(l10n, err);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(content: Text(msg)),
                                );
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
                                  l10n.continueWithGoogle,
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
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
