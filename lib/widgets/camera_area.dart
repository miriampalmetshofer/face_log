import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:face_log/video_library.dart';

class CameraArea extends StatelessWidget {
  const CameraArea({
    super.key,
    required this.isInitialized,
    required this.isRecording,
    required this.showVideoLibrary,
    required this.controller,
    required this.onToggleLibrary,
  });

  final bool isInitialized;
  final bool isRecording;
  final bool showVideoLibrary;
  final CameraController? controller;
  final VoidCallback onToggleLibrary;

  Widget _decorated(Widget child, {Color? borderColor, Color? bg}) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (borderColor ?? Colors.grey.shade300), width: 2),
        color: bg,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isInitialized && !isRecording && !showVideoLibrary) {
      return _decorated(CameraPreview(controller!));
    }

    if (isRecording) {
      return _decorated(
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, size: 80, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Recording...',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              SizedBox(height: 8),
              Text('Click button again to stop', style: TextStyle(fontSize: 16, color: Colors.white70)),
            ],
          ),
        ),
        borderColor: Colors.red,
        bg: Colors.black,
      );
    }

    if (showVideoLibrary) {
      return VideoLibrary(onToggleLibrary: onToggleLibrary);
    }

    return _decorated(
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Camera not ready', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
      bg: Colors.grey.shade100,
    );
  }
}