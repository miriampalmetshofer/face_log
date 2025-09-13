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
  String _statusMessage = 'Initializing camera...';
  bool _showVideoLibrary = false;
  bool _showBrowser = false;
  String _browserUrl = '';

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

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
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
        title: const Text('FaceLog - Face Recording'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            StatusBanner(message: _statusMessage, isRecording: _isRecording),
            Expanded(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (_isRecording)
                    _decorated(
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
                    )
                  else if (_showVideoLibrary)
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