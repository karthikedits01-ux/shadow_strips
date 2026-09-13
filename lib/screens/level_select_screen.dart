import 'package:flutter/material.dart';
import '../controllers/flow_controller.dart';

class LevelSelectScreen extends StatelessWidget {
  final FlowController flowController;

  const LevelSelectScreen({super.key, required this.flowController});

  @override
  Widget build(BuildContext context) {
    final progress = flowController.progressService;
    final highestUnlockedStr = progress.highestUnlockedLevel.split('_').last;
    final highestUnlocked = int.tryParse(highestUnlockedStr) ?? 1;
    final completed = progress.completedLevels;
    
    // In a real game, this would be based on LevelRepository.getTotalLevels()
    const totalLevels = 50; 

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C1E)),
          onPressed: () => flowController.goHome(),
        ),
        title: const Text(
          'LEVELS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
            color: Color(0xFF1C1C1E),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(24.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: totalLevels,
          itemBuilder: (context, index) {
            final levelNum = index + 1;
            final levelId = 'level_$levelNum';
            
            final isUnlocked = levelNum <= highestUnlocked;
            final isCompleted = completed.contains(levelId);
            final isCurrent = levelId == progress.currentLevel;

            return _LevelTile(
              levelNum: levelNum,
              isUnlocked: isUnlocked,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              onTap: isUnlocked ? () {
                flowController.playLevel(levelId);
              } : null,
            );
          },
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int levelNum;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.levelNum,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = const Color(0xFFF7F7F7);
    Color textColor = const Color(0xFF1C1C1E);
    Color borderColor = const Color(0xFFE8E8E8);

    if (!isUnlocked) {
      textColor = const Color(0xFFB0B0B0);
    }
    
    if (isCurrent) {
      borderColor = const Color(0xFF1C1C1E);
      bgColor = const Color(0xFFFFFFFF);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: borderColor, width: isCurrent ? 2.0 : 1.0),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                levelNum.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (isCompleted && !isCurrent)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Icon(Icons.check, size: 12, color: Color(0xFF6B6B6B)),
                ),
              if (!isUnlocked)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Icon(Icons.lock_outline, size: 12, color: Color(0xFFB0B0B0)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
