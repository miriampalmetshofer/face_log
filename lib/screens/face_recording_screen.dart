import 'dart:async';

import 'package:face_log/config.dart';
import 'package:face_log/in_app_browser.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:face_log/video_library.dart';
import 'package:face_log/widgets/status_banner.dart';
import 'package:face_log/widgets/controls.dart';
import 'package:face_log/services/camera_io.dart';

class FaceRecordingScreen extends StatefulWidget {
  const FaceRecordingScreen({super.key});

  @override
  State<FaceRecordingScreen> createState() => _FaceRecordingScreenState();
}

class _FaceRecordingScreenState extends State<FaceRecordingScreen> {
  CameraController? _cameraController;
  bool _isRecording = false;
  bool _isInitialized = false;
  String _statusMessage = 'Kamera wird initialisiert...';
  bool _showVideoLibrary = false;
  bool _showBrowser = false;
  String _browserUrl = '';
  CameraLensDirection? _cameraLensDirectiondirection;

  Timer? _recordingTimer;
  int _remainingSeconds = AppConfig.maxRecordingDuration;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final selectedCamera = await CameraIO.pickFrontOrFirst();
      if (selectedCamera == null) {
        setState(() => _statusMessage = 'Keine Kameras auf diesem Gerät verfügbar');
        return;
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: CameraIO.platformImageFormat(),
      );

      await controller.initialize();

      setState(() {
        _cameraController = controller;
        _isInitialized = true;
        _cameraLensDirectiondirection = selectedCamera.lensDirection;
        _statusMessage = 'Kamera bereit (${_cameraLensDirectiondirection == CameraLensDirection.front ? "Front" : "Rück"}kamera)';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Kamera konnte nicht initialisiert werden: $e');
    }
  }

  Future<void> _toggleRecording() async {
    final controller = _cameraController;
    if (!_isInitialized || controller == null) return;

    try {
      if (_isRecording) {
        _recordingTimer?.cancel();
        final videoFile = await controller.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _statusMessage = 'Video wird gespeichert...';
          _remainingSeconds = AppConfig.maxRecordingDuration;
        });

        await CameraIO.saveToAppDocs(videoFile);
        setState(() => _statusMessage = 'Video gespeichert!');

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _statusMessage = '${_cameraLensDirectiondirection == CameraLensDirection.front ? "Front" : "Rück"}kamera bereit');
        });
      } else {
        setState(() => _statusMessage = 'Aufnahme...');
        await controller.startVideoRecording();
        setState(() => _isRecording = true);
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _remainingSeconds--;
          });
          if (_remainingSeconds <= 0) {
            timer.cancel();
            _toggleRecording();
            _showRecordingStoppedDialog();
          }
        });
      }
    } catch (e) {
      setState(() => _statusMessage = 'Fehler: $e');
    }
  }

  void _toggleVideoLibrary() {
    setState(() => _showVideoLibrary = !_showVideoLibrary);
  }

  void _openBrowser(String url) {
    setState(() {
      _showBrowser = true;
      _browserUrl = url;
    });
  }

  void _closeBrowser() {
    setState(() {
      _showBrowser = false;
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showRecordingStoppedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aufnahme gestoppt'),
        content: const Text('Die Aufnahme wurde nach 5 Minuten automatisch gestoppt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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

  Widget _buildAppIcon(String url, IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 40),
          color: color,
          onPressed: () => _openBrowser(url),
        ),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StatusBanner(message: _statusMessage, isRecording: _isRecording),
        backgroundColor: Colors.grey.shade200,
        actions: [
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Center(
                  child: Text(
                _formatDuration(_remainingSeconds),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              )),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (_showVideoLibrary)
                    VideoLibrary(onToggleLibrary: _toggleVideoLibrary)
                  else if (!_showBrowser)
                    Padding(
                      padding: const EdgeInsets.only(top: 30.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAppIcon('https://www.instagram.com', Icons.camera_alt, 'Instagram', Colors.pink),
                          _buildAppIcon('https://www.facebook.com', Icons.facebook, 'Facebook', Colors.blue),
                          _buildAppIcon('https://www.tiktok.com', Icons.tiktok, 'TikTok', Colors.black),
                        ],
                      ),
                    ),
                  if (_showBrowser)
                    InAppBrowser(
                      url: _browserUrl,
                      onClose: _closeBrowser,
                    ),
                ],
              ),
            ),
            if (!_showVideoLibrary && !_showBrowser)
              Controls(
                isInitialized: _isInitialized,
                isRecording: _isRecording,
                onToggleLibrary: _toggleVideoLibrary,
                onToggleRecording: _toggleRecording,
              ),
          ],
        ),
      ),
    );
  }
}