import 'package:camera/camera.dart';

class AppConfig {
  // Camera
  static const ResolutionPreset cameraResolutionPreset = ResolutionPreset.medium;

  // Recording
  static const int maxRecordingDuration = 60 * 5;

  // Upload timeouts
  static const int uploadTimeoutSecondsPerMB = 2;
  static const int uploadTimeoutBaseSeconds = 30;
  static const int uploadTimeoutMinSeconds = 30;
  static const int uploadTimeoutMaxSeconds = 60 * 5;

  // Video player
  static const int videoPlayerSkipSeconds = 5;
}
