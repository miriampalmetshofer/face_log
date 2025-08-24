import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  // Request camera permission
  final cameraStatus = await Permission.camera.request();
  if (cameraStatus.isDenied) {
    debugPrint('Camera permission denied');
  }

  // Request microphone permission
  final microphoneStatus = await Permission.microphone.request();
  if (microphoneStatus.isDenied) {
    debugPrint('Microphone permission denied');
  }

  // Request storage permissions (Android)
  if (Platform.isAndroid) {
    final storageStatus = await Permission.storage.request();
    if (storageStatus.isDenied) {
      debugPrint('Storage permission denied');
    }
  }
}
