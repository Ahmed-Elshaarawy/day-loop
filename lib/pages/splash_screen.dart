import 'package:flutter/material.dart';

class AppSplash extends StatelessWidget {
  const AppSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: Image.asset(
          isDark ? 'assets/splashscreen/day_loop.webp' : 'assets/splashscreen/day_loop.webp',
          width: 180,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
