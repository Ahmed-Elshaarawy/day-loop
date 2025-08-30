import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Daily Card (stub)', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/morning'),
              child: const Text('Morning Brief'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => context.push('/evening'),
              child: const Text('Evening Debrief'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => context.push('/history'),
              child: const Text('History / Journal'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.push('/detail/42'),
              child: const Text('Open Detail (id=42)'),
            ),
          ],
        ),
      ),
    );
  }
}
