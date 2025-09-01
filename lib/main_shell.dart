import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// import 'l10n/app_localizations.dart';

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
    // Get the AppLocalizations instance
    // final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2A2A2A),
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: const Color(0xFF888888),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'Home', // Use the localized string
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: 'History', // Use the localized string
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: 'Settings', // Use the localized string
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
