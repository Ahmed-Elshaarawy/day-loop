import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/language_selection_dialog.dart';
import '../auth/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../repositories/task_repository.dart';
import '../widgets/setting_tile.dart';
import '../view_models/settings_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<TaskRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: uid == null
          ? Center(child: Text(l10n.toastSignInRequired))
          : ChangeNotifierProvider(
        create: (_) => SettingsViewModel(repo: repo, userId: uid),
        child: const _SettingsBody(),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<SettingsViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSettingsSection(
            context,
            title: l10n.generalSectionTitle,
            items: [
              SettingTile(
                icon: Icons.language,
                title: l10n.languageTitle,
                subtitle: l10n.languageSubtitle,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const LanguageSelectionDialog(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsSection(
            context,
            title: l10n.accountSectionTitle,
            items: [
              SettingTile(
                icon: Icons.delete_sweep_outlined,
                title: l10n.clearHistoryTitle,
                subtitle: l10n.clearHistorySubtitle,
                isDestructive: true,
                onTap: vm.clearing ? null : () => _confirmClearHistory(context),
                trailing: vm.clearing
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : null,
              ),
              SettingTile(
                icon: Icons.logout,
                title: l10n.logoutButton,
                isDestructive: true,
                onTap: () async {
                  await AuthService.instance.signOut();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.clearHistoryDialogTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.clearHistoryDialogContent,
          style: const TextStyle(color: Color(0xFFCCCCCC)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.deleteButton,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<SettingsViewModel>().clearHistory();
      // toast
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.toastHistoryCleared)));
    }
  }

  Widget _buildSettingsSection(
      BuildContext context, {
        required String title,
        required List<Widget> items,
      }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...items,
        ],
      ),
    );
  }
}
