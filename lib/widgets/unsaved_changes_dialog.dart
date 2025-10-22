import 'package:flutter/material.dart';

class UnsavedChangesDialog {
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ungespeicherte Änderungen'),
          content: const Text(
            'Sie haben ungespeicherte Änderungen. Möchten Sie diese verwerfen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Änderungen verwerfen',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
    },
    );

    return result ?? false;
  }
}
