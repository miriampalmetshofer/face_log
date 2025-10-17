import 'package:face_log/services/user_preferences_service.dart';
import 'package:flutter/material.dart';

class UserNameDisplay extends StatefulWidget {
  final String userName;
  final VoidCallback onNameChanged;

  const UserNameDisplay({
    super.key,
    required this.userName,
    required this.onNameChanged,
  });

  @override
  State<UserNameDisplay> createState() => _UserNameDisplayState();
}

class _UserNameDisplayState extends State<UserNameDisplay> {
  int _tapCount = 0;
  DateTime? _lastTapTime;

  void _handleTap() {
    final now = DateTime.now();

    // Reset counter if more than 2 seconds since last tap
    if (_lastTapTime != null && now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _tapCount = 0;
    }

    _tapCount++;
    _lastTapTime = now;

    if (_tapCount >= 5) {
      _tapCount = 0;
      _showNameEditDialog();
    }
  }

  void _showNameEditDialog() {
    final controller = TextEditingController(text: widget.userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name bearbeiten'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Geben Sie Ihren Namen ein',
          ),
          autofocus: true,
          onSubmitted: (value) async {
            if (value.isNotEmpty) {
              await UserPreferencesService.saveUserName(value);
              if (context.mounted) {
                Navigator.of(context).pop();
                widget.onNameChanged();
              }
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await UserPreferencesService.saveUserName(controller.text);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  widget.onNameChanged();
                }
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          'Hi, ${widget.userName}!',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
