import 'package:flutter/material.dart';
import 'dart:math' as math;

class ComboTimerBar extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onPenalty;

  const ComboTimerBar({
    super.key,
    required this.durationSeconds,
    required this.onPenalty,
  });

  @override
  State<ComboTimerBar> createState() => ComboTimerBarState();
}

class ComboTimerBarState extends State<ComboTimerBar> with TickerProviderStateMixin {
  late AnimationController _timerController;
  late AnimationController _flashController;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();

    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
      value: 1.0, // Force timer to be FULL on initial mount
    );

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        // Reached 0 (reverse drains to dismissed)
        widget.onPenalty();
        if (mounted) {
          _timerController.value = 1.0;
          _timerController.reverse(from: 1.0);
        }
      }
    });

    _timerController.addListener(() {
      if (_timerController.value <= 0.25 && !_blinkController.isAnimating) {
        _blinkController.repeat(reverse: true);
      } else if (_timerController.value > 0.25 && _blinkController.isAnimating) {
        _blinkController.stop();
        _blinkController.value = 0;
      }
      setState(() {});
    });

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _flashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flashController.reverse();
      }
    });

    _flashController.addListener(() {
      setState(() {});
    });

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _blinkController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(ComboTimerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.durationSeconds != widget.durationSeconds) {
      _timerController.duration = Duration(seconds: widget.durationSeconds);
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    _flashController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  void startTimer() {
    if (!_timerController.isAnimating && _timerController.value == 1.0) {
      _timerController.reverse(from: 1.0);
    }
  }

  void stopTimer() {
    _timerController.stop();
    _blinkController.stop();
  }

  void addBonus() {
    if (!_timerController.isAnimating) return; // Don't add if stopped

    double newValue = math.min(1.0, _timerController.value + 0.25);
    _timerController.value = newValue;
    _timerController.reverse(from: newValue);
    
    _flashController.forward(from: 0.0);
  }
  
  void resetTimer() {
      _timerController.value = 1.0;
      _timerController.stop();
      _blinkController.stop();
      _blinkController.value = 0;
      setState((){});
  }

  @override
  Widget build(BuildContext context) {
    // 1. Flash color (Neon Blue)
    // 2. Panic color (Harsh Blinking Red)
    // 3. Normal color (Grey/Dark)
    
    final flashValue = _flashController.value;
    final blinkValue = _blinkController.value;
    final timerValue = _timerController.value;

    Color barColor = const Color(0xFF2C3E50); // Base color
    
    if (timerValue <= 0.25) {
      // Blinking Red
      barColor = Color.lerp(const Color(0xFF2C3E50), Colors.redAccent, blinkValue) ?? Colors.redAccent;
    }
    
    if (flashValue > 0) {
      barColor = Color.lerp(barColor, Colors.cyanAccent, flashValue) ?? Colors.cyanAccent;
    }

    return SizedBox(
      height: 4.0,
      child: Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(2.0),
        ),
      child: FractionallySizedBox(
        widthFactor: timerValue,
        child: Container(
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(2.0),
            boxShadow: flashValue > 0 ? [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.8),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ] : null,
          ),
        ),
      ),
      ),
    );
  }
}
