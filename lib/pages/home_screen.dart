import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
<<<<<<< Updated upstream

=======
import 'package:firebase_auth/firebase_auth.dart';
>>>>>>> Stashed changes
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
=======
    final int currentHour = DateTime.now().hour;
    final String timeOfDayText = (currentHour < 12) ? 'Morning' : 'Evening';

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
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
=======
            const SizedBox(height: 40),
            const Text(
              'VoiceLoop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Journey - $timeOfDayText',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTaskItem('📝', 'Complete project presentation'),
                          _buildTaskItem('🏋️', '30-minute workout'),
                          _buildTaskItem('📖', 'Read 20 pages'),
                          _buildTaskItem('🥗', 'Eat healthy lunch'),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.only(top: 20),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFF333333), width: 1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Today • 8/29/2025',
                                  style: TextStyle(
                                    color: Color(0xFF888888),
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5722),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '🔥 7 Day Streak',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (timeOfDayText == 'Morning') {
                                  context.go('/home/morning');
                                } else {
                                  context.go('/home/evening');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Record Journey',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
>>>>>>> Stashed changes
            ),
          ],
        ),
      ),
    );
  }
}
