import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_localizations.dart';

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.child,
    required this.navigationShell,
  });

  final Widget child;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(child: child),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF2A2A2A),
          selectedItemColor: const Color(0xFFFF9800),
          unselectedItemColor: const Color(0xFF888888),
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => _onTap(context, index),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: l10n.homeTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history),
              label: l10n.historyTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: l10n.settingsTitle,
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    if (index == 1) {
      context.go('/history', extra: {'clearStack': true});
    } else {
      navigationShell.goBranch(index);
    }
  }}
