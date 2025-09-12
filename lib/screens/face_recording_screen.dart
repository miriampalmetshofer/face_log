import 'package:face_log/in_app_browser.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:face_log/widgets/status_banner.dart';
import 'package:face_log/widgets/camera_area.dart';
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
  String _statusMessage = 'Initializing camera...';
  bool _showVideoLibrary = false;
  bool _showBrowser = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final selectedCamera = await CameraIO.pickFrontOrFirst();
      if (selectedCamera == null) {
        setState(() => _statusMessage = 'No cameras available on this device');
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
        _statusMessage =
        'Camera ready (${selectedCamera.lensDirection == CameraLensDirection.front ? "Front" : "Back"})';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Failed to initialize camera: $e');
    }
  }

  Future<void> _toggleRecording() async {
    final controller = _cameraController;
    if (!_isInitialized || controller == null) return;

    try {
      if (_isRecording) {
        final videoFile = await controller.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _statusMessage = 'Saving video...';
        });

        await CameraIO.saveToAppDocs(videoFile);
        setState(() => _statusMessage = 'Video saved!');

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _statusMessage = 'Camera ready');
        });
      } else {
        setState(() => _statusMessage = 'Recording...');
        await controller.startVideoRecording();
        setState(() => _isRecording = true);
      }
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    }
  }

  void _toggleVideoLibrary() {
    setState(() => _showVideoLibrary = !_showVideoLibrary);
  }

  void _toggleBrowser() {
    setState(() => _showBrowser = !_showBrowser);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FaceLog - Face Recording'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          StatusBanner(message: _statusMessage, isRecording: _isRecording),
          Expanded(
            child: Stack(
              children: [
                CameraArea(
                  isInitialized: _isInitialized,
                  isRecording: _isRecording,
                  showVideoLibrary: _showVideoLibrary,
                  controller: _cameraController,
                  onToggleLibrary: _toggleVideoLibrary,
                ),
                if (_showBrowser)
                  InAppBrowser(
                    url: 'https://www.instagram.com/accounts/login/?hl=en',
                    onClose: _toggleBrowser,
                  ),
              ],
            ),
          ),
          Controls(
            isInitialized: _isInitialized,
            isRecording: _isRecording,
            onToggleLibrary: _toggleVideoLibrary,
            onToggleRecording: _toggleRecording,
            onOpenBrowser: _toggleBrowser,
          ),
        ],
      ),
    );
  }
}