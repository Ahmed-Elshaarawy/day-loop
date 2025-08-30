import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History / Journal')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final id = (100 - index).toString();
          return ListTile(
            title: Text('Daily Card #$id'),
            subtitle: const Text('Summary…'),
            onTap: () => context.push('/detail/$id'),
          );
        },
      ),
    );
  }
}
