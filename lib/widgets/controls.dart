import 'package:flutter/material.dart';

class Controls extends StatelessWidget {
  const Controls({
    super.key,
    required this.isInitialized,
    required this.isRecording,
    required this.onOpenLibrary,
    required this.onToggleRecording,
    required this.onTogglePreview,
  });

  final bool isInitialized;
  final bool isRecording;
  final VoidCallback onOpenLibrary;
  final VoidCallback onToggleRecording;
  final VoidCallback onTogglePreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: 'library_button',
            onPressed: isInitialized ? onOpenLibrary : null,
            backgroundColor: Colors.blue.shade900,
            child: const Icon(Icons.video_library, color: Colors.white),
          ),
          FloatingActionButton.large(
            heroTag: 'record_button',
            onPressed: isInitialized ? onToggleRecording : null,
            backgroundColor: isRecording ? Colors.orange : Colors.blue,
            child: Icon(
              isRecording ? Icons.stop : Icons.fiber_manual_record,
              size: 40,
              color: Colors.white,
            ),
          ),
          FloatingActionButton(
            heroTag: 'preview_button',
            onPressed: isInitialized ? onTogglePreview : null,
            backgroundColor: Colors.blue.shade900,
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
