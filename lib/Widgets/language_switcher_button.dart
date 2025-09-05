import 'package:flutter/material.dart';
import 'package:day_loop/Widgets/language_selection_dialog.dart';

class LanguageSwitcherButton extends StatelessWidget {
  const LanguageSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.language, color: Color(0xFF888888)),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return const LanguageSelectionDialog();
          },
        );
      },
    );
  }
}
