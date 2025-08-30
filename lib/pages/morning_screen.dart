import 'package:flutter/material.dart';

class MorningScreen extends StatelessWidget {
  const MorningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Morning Brief')),
      body: const Center(child: Text('Mic UI + 90s capture (stub)')),
    );
  }
}
