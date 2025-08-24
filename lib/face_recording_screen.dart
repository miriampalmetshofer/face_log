import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:face_log/video_library.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _statusMessage = 'No cameras available on this device';
        });
        return;
      }

      // Find front camera
      CameraDescription? selectedCamera;
      try {
        selectedCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        // If no front camera found, use the first available camera
        selectedCamera = cameras.first;
        debugPrint(
          'Front camera not found, using ${selectedCamera.lensDirection} camera',
        );
      }

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      setState(() {
        _isInitialized = true;
        _statusMessage =
            'Camera ready (${selectedCamera?.lensDirection == CameraLensDirection.front ? "Front" : "Back"})';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to initialize camera: $e';
      });
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isInitialized || _cameraController == null) return;

    try {
      if (_isRecording) {
        // Stop recording
        final videoFile = await _cameraController!.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _statusMessage = 'Saving video...';
        });

        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'face_recording_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final savedPath = '${directory.path}/$fileName';
        await File(videoFile.path).copy(savedPath);

        setState(() {
          _statusMessage = 'Video saved!';
        });

        // Reset status message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _statusMessage = 'Camera ready';
            });
          }
        });
      } else {
        // Start recording
        setState(() {
          _statusMessage = 'Recording...';
        });

        await _cameraController!.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  void _toggleVideoLibrary() {
    setState(() {
      _showVideoLibrary = !_showVideoLibrary;
    });
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
          // Status message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isRecording
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            child: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _isRecording ? Colors.red : Colors.green,
              ),
            ),
          ),

          // Camera preview (hidden during recording as requested)
          if (_isInitialized && !_isRecording && !_showVideoLibrary)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: CameraPreview(_cameraController!),
              ),
            )
          else if (_isRecording)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red, width: 3),
                  color: Colors.black,
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam, size: 80, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Recording...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Click button again to stop',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_showVideoLibrary)
            Expanded(
              child: VideoLibrary(onToggleLibrary: _toggleVideoLibrary),
            )
          else
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  color: Colors.grey.shade100,
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Camera not ready',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Recording button
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Library button
                FloatingActionButton(
                  onPressed: _isInitialized ? _toggleVideoLibrary : null,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.video_library, color: Colors.white),
                ),

                // Recording button
                FloatingActionButton.large(
                  onPressed: _isInitialized ? _toggleRecording : null,
                  backgroundColor: _isRecording ? Colors.red : Colors.green,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.fiber_manual_record,
                    size: 40,
                    color: Colors.white,
                  ),
                ),

                // Placeholder for symmetry
                const SizedBox(width: 56),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
