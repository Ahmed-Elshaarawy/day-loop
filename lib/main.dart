import 'package:flutter/material.dart';
import 'app_router.dart';

void main() => runApp(const DayLoopApp());

class DayLoopApp extends StatelessWidget {
  const DayLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: 'Day Loop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
