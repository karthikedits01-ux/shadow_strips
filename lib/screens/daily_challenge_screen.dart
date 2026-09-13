import 'package:flutter/material.dart';
import '../controllers/flow_controller.dart';

class DailyChallengeScreen extends StatelessWidget {
  final FlowController flowController;

  const DailyChallengeScreen({super.key, required this.flowController});

  @override
  Widget build(BuildContext context) {
    // Basic date formatting without intl package to keep dependencies light
    final now = DateTime.now();
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final dateStr = '${now.day} ${months[now.month - 1]}';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C1E)),
          onPressed: () => flowController.goHome(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),
              const Text(
                'DAILY CHALLENGE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4.0,
                  color: Color(0xFF6B6B6B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dateStr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'One Puzzle',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () {
                        // For the prototype, we just load level_1 as the daily challenge.
                        // In production, we derive a seed from the date and procedurally generate.
                        flowController.playLevel('level_1'); 
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Text(
                          'PLAY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
