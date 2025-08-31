import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Automatically detect if it's morning or evening based on local time
    final int currentHour = DateTime.now().hour;
    final String timeOfDayText = (currentHour < 12) ? 'Morning' : 'Evening';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background
      body: SafeArea(
        child: Column(
          children: [
            // VoiceLoop Title
            const SizedBox(height: 40), // Increased space at the top
            const Text(
              'VoiceLoop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20), // Adjusted space after title

            // Main content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    // Today's Journey Card
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
                          // Card Header with Time of Day text
                          Text(
                            'Today\'s Journey - $timeOfDayText',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20), // Adjusted space between title and tasks

                          // Task List
                          _buildTaskItem('🎯', 'Complete project presentation'),
                          _buildTaskItem('💪', '30-minute workout'),
                          _buildTaskItem('📚', 'Read 20 pages'),
                          _buildTaskItem('🍎', 'Eat healthy lunch'),

                          const SizedBox(height: 30), // Adjusted space before card footer

                          // Card Footer
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

                    const SizedBox(height: 30), // Adjusted space between card and button

                    // Action Buttons
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
                                // Placeholder for recording logic, for now
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
                                    Icons.mic, // Placeholder icon for recording
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Record Journey', // Placeholder text
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
                    const SizedBox(height: 40), // Adjusted space below button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          border: Border(
            top: BorderSide(color: Color(0xFF333333), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF4CAF50),
          unselectedItemColor: const Color(0xFF888888),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            switch (index) {
              case 0:
                break;
              case 1:
                context.push('/history');
                break;
              case 2:
                context.push('/settings');
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildTaskItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
