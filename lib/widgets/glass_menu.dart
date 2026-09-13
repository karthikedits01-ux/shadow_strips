import 'dart:ui';
import 'package:flutter/material.dart';

class GlassMenu extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onLevels;
  final VoidCallback onDaily;
  final VoidCallback onSettings;
  final VoidCallback onHome;

  const GlassMenu({
    super.key,
    required this.onResume,
    required this.onLevels,
    required this.onDaily,
    required this.onSettings,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: const Color(0xFFFFFFFF).withAlpha(200),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuButton(label: 'RESUME', onTap: onResume, isPrimary: true),
              const SizedBox(height: 24),
              _MenuButton(label: 'HOME', onTap: onHome),
              const SizedBox(height: 24),
              _MenuButton(label: 'LEVELS', onTap: onLevels),
              const SizedBox(height: 24),
              _MenuButton(label: 'DAILY CHALLENGE', onTap: onDaily),
              const SizedBox(height: 24),
              _MenuButton(label: 'SETTINGS', onTap: onSettings),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _MenuButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isPrimary ? 20 : 16,
            fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 3.0,
            color: isPrimary ? const Color(0xFF1C1C1E) : const Color(0xFF6B6B6B),
          ),
        ),
      ),
    );
  }
}
