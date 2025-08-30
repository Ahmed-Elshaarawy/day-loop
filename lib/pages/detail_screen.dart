import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final String id;
  const DetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Card $id')),
      body: Center(
        child: Text('Full details for Daily Card $id (stub)'),
      ),
    );
  }
}
