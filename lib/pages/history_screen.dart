import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Example History Item 1
          _buildHistoryItem(
            '8/28/2025',
            'Evening Journey',
            'A recap of my evening, focusing on wrapping up the work day and planning for tomorrow.',
          ),
          const SizedBox(height: 16),
          // Example History Item 2
          _buildHistoryItem(
            '8/27/2025',
            'Morning Check-in',
            'Started the day with a meditation and set intentions for the tasks ahead.',
          ),
          const SizedBox(height: 16),
          // Example History Item 3
          _buildHistoryItem(
            '8/26/2025',
            'Evening Reflection',
            'Reflecting on today\'s achievements and areas for improvement. Ended with a note on gratitude.',
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String date, String title, String summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}