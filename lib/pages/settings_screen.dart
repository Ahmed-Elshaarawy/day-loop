import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
            subtitle: Text('Arabic / English (add toggle later)'),
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy'),
            subtitle: Text('On-device, backups, etc.'),
          ),
          ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Notifications & streaks'),
          ),
        ],
      ),
    );
  }
}
