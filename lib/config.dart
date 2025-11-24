import 'package:camera/camera.dart';

class AppConfig {
  // Camera
  static const ResolutionPreset cameraResolutionPreset = ResolutionPreset.medium;
  static const int cameraFrameRate = 30;

  // Recording
  static const int maxRecordingDuration = 60 * 5;

  // Upload timeout
  static const int uploadTimeoutMaxSeconds = 60 * 8;

  // Video player
  static const int videoPlayerSkipSeconds = 5;
}
