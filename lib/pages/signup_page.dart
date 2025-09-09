import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../widgets/language_switcher_button.dart';
import '../widgets/gradient_elevated_button.dart';
import '../widgets/custom_text_field.dart';
import '../l10n/app_localizations.dart';
import '../auth/auth_localization.dart';
import '../auth/auth_service.dart';
import '../view_models/signup_view_model.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ChangeNotifierProvider<SignUpViewModel>(
      create: (_) => SignUpViewModel(),
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
                child: Consumer<SignUpViewModel>(
                  builder: (context, vm, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.appTitle,
                          style: const TextStyle(
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
                              Text(
                                l10n.createAccount,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              CustomTextField(
                                labelText: l10n.name,
                                icon: Icons.person,
                                onChanged: vm.setName,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                labelText: l10n.email,
                                icon: Icons.email,
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
                                colors: const [
                                  Color(0xFF4CAF50),
                                  Color(0xFF2E7D32)
                                ],
                                onPressed: vm.loading
                                    ? null
                                    : () async {
                                  final ok = await vm.signUpWithEmail();
                                  if (!context.mounted) return;
                                  if (ok) {
                                    context.go('/home');
                                  } else {
                                    // map to localized text
                                    final err = AuthException(
                                      vm.error ?? '',
                                      code: vm.errorCode,
                                    );
                                    final msg = vm.errorCode ==
                                        'missing-credentials'
                                        ? l10n.authGenericFailure
                                        : authErrorText(l10n, err);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(content: Text(msg)),
                                    );
                                  }
                                },
                                child: vm.loading
                                    ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                    : Text(
                                  l10n.signUp,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: Text(
                                  l10n.signInLink,
                                  style: const TextStyle(
                                    color: Color(0xFFFF5722),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
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
