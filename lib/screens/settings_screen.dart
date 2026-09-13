import 'package:flutter/material.dart';
import '../controllers/flow_controller.dart';

class SettingsScreen extends StatefulWidget {
  final FlowController flowController;

  const SettingsScreen({super.key, required this.flowController});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundEnabled;
  late bool _hapticsEnabled;

  @override
  void initState() {
    super.initState();
    final prefs = widget.flowController.progressService;
    _soundEnabled = prefs.isSoundEnabled;
    _hapticsEnabled = prefs.isHapticsEnabled;
  }

  void _toggleSound(bool value) async {
    setState(() => _soundEnabled = value);
    await widget.flowController.progressService.setSoundEnabled(value);
  }

  void _toggleHaptics(bool value) async {
    setState(() => _hapticsEnabled = value);
    await widget.flowController.progressService.setHapticsEnabled(value);
  }

  void _resetProgress() async {
    // Show quick dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress?'),
        content: const Text('This will lock all levels again. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Color(0xFF6B6B6B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'RESET',
              style: TextStyle(color: Color(0xFF1C1C1E)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.flowController.progressService.resetProgress();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Progress Reset')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C1E)),
          onPressed: () => widget.flowController.goHome(),
        ),
        title: const Text(
          'SETTINGS',
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
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            SwitchListTile(
              title: const Text('Sound', style: TextStyle(fontSize: 16)),
              value: _soundEnabled,
              onChanged: _toggleSound,
              activeThumbColor: const Color(0xFF1C1C1E),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(color: Color(0xFFE8E8E8)),
            SwitchListTile(
              title: const Text('Haptics', style: TextStyle(fontSize: 16)),
              value: _hapticsEnabled,
              onChanged: _toggleHaptics,
              activeThumbColor: const Color(0xFF1C1C1E),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(color: Color(0xFFE8E8E8)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Reset Progress',
                style: TextStyle(fontSize: 16, color: Color(0xFF1C1C1E)),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFF6B6B6B),
              ),
              onTap: _resetProgress,
            ),
            const Divider(color: Color(0xFFE8E8E8)),
          ],
        ),
      ),
    );
  }
}
