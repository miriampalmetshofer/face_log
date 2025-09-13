import 'package:flutter/material.dart';

class Controls extends StatelessWidget {
  const Controls({
    super.key,
    required this.isInitialized,
    required this.isRecording,
    required this.onToggleLibrary,
    required this.onToggleRecording,
  });

  final bool isInitialized;
  final bool isRecording;
  final VoidCallback onToggleLibrary;
  final VoidCallback onToggleRecording;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: isInitialized ? onToggleLibrary : null,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.video_library, color: Colors.white),
          ),
          FloatingActionButton.large(
            onPressed: isInitialized ? onToggleRecording : null,
            backgroundColor: isRecording ? Colors.red : Colors.green,
            child: Icon(
              isRecording ? Icons.stop : Icons.fiber_manual_record,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
