import 'dart:async';
import 'package:camera/camera.dart';
import 'package:face_log/config.dart';
import 'package:face_log/services/camera_io.dart';

class CameraManager {
  CameraController? _controller;
  Timer? _recordingTimer;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  // Callbacks
  Function(String message)? onStatusChange;
  Function(bool isRecording)? onRecordingStateChange;
  Function(int seconds)? onTimerTick;
  Function(XFile videoFile)? onRecordingComplete;
  Function()? onMaxDurationReached;

  Future<void> initialize() async {
    final selectedCamera = await CameraIO.pickFrontOrFirst();
    if (selectedCamera == null) {
      onStatusChange?.call('Keine Kameras auf diesem Gerät verfügbar');
      return;
    }

    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: CameraIO.platformImageFormat(),
    );

    await _controller!.initialize();

    // Pause preview to prevent buffer warnings on Android
    await _controller!.pausePreview();

    final lensType = selectedCamera.lensDirection == CameraLensDirection.front ? "Front" : "Rück";
    onStatusChange?.call('Kamera bereit (${lensType}kamera)');
  }

  Future<void> startRecording() async {
    if (_controller == null || !isInitialized) return;

    await _controller!.resumePreview();
    await _controller!.startVideoRecording();

    onStatusChange?.call('Aufnahme...');
    onRecordingStateChange?.call(true);

    // Start countdown timer
    int remainingSeconds = AppConfig.maxRecordingDuration;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      remainingSeconds--;
      onTimerTick?.call(remainingSeconds);

      if (remainingSeconds <= 0) {
        timer.cancel();
        final videoFile = await stopRecording(autoStopped: true);
        if (videoFile != null) {
          onRecordingComplete?.call(videoFile);
        }
      }
    });
  }

  Future<XFile?> stopRecording({bool autoStopped = false}) async {
    if (_controller == null || !isInitialized) return null;

    _recordingTimer?.cancel();
    final videoFile = await _controller!.stopVideoRecording();

    onRecordingStateChange?.call(false);
    onStatusChange?.call('Video wird gespeichert...');

    // Pause preview to save resources
    await _controller!.pausePreview();

    if (autoStopped) {
      onMaxDurationReached?.call();
    }

    return videoFile;
  }

  Future<void> resumePreview() async {
    await _controller?.resumePreview();
  }

  Future<void> pausePreview() async {
    await _controller?.pausePreview();
  }

  void dispose() {
    _recordingTimer?.cancel();
    _controller?.dispose();
  }
}
