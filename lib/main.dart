import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request permissions before running the app
  await _requestPermissions();

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  // Request camera permission
  final cameraStatus = await Permission.camera.request();
  if (cameraStatus.isDenied) {
    // Show dialog explaining why camera permission is needed
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FaceLog New',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const FaceRecordingScreen(),
    );
  }
}

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
  List<String> _recordedVideos = [];
  bool _showVideoLibrary = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadExistingVideos();
  }

  Future<void> _loadExistingVideos() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      final videoFiles = files
          .where((file) => file.path.endsWith('.mp4') && file.path.contains('face_recording_'))
          .map((file) => file.path)
          .toList();

      setState(() {
        _recordedVideos = videoFiles;
      });
      debugPrint('Loaded ${_recordedVideos.length} existing videos');
    } catch (e) {
      debugPrint('Error loading existing videos: $e');
    }
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
        debugPrint('Front camera not found, using ${selectedCamera.lensDirection} camera');
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
        _statusMessage = 'Camera ready (${selectedCamera?.lensDirection == CameraLensDirection.front ? "Front" : "Back"})';
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

        // Save to gallery
        await _saveVideoToGallery(videoFile.path);

        setState(() {
          _statusMessage = 'Video saved to gallery!';
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

  Future<void> _saveVideoToGallery(String videoPath) async {
    try {
      // Save video to app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'face_recording_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final savedPath = '${directory.path}/$fileName';

      // Copy the video file to the documents directory
      await File(videoPath).copy(savedPath);

      // Add to recorded videos list
      setState(() {
        _recordedVideos.add(savedPath);
        _statusMessage = 'Video saved! Tap to share or find in app documents.';
      });

      debugPrint('Video saved to: $savedPath');

      // Show a dialog with options to share or view the file
      _showVideoSavedDialog(savedPath);
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to save video: $e';
      });
      debugPrint('Error saving video: $e');
    }
  }

  void _showVideoSavedDialog(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Video Saved!'),
          content: Text('Your video has been saved to:\n$filePath'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Share.shareXFiles([XFile(filePath)], text: 'Face Recording Video');
              },
              child: const Text('Share Video'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showVideoLibrary = true;
                });
              },
              child: const Text('View Library'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVideo(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        setState(() {
          _recordedVideos.remove(filePath);
        });
        debugPrint('Video deleted: $filePath');
      }
    } catch (e) {
      debugPrint('Error deleting video: $e');
    }
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
            color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
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
                      Icon(
                        Icons.videocam,
                        size: 80,
                        color: Colors.red,
                      ),
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
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_showVideoLibrary)
              Expanded(
                child: _buildVideoLibrary(),
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
                        Icon(
                          Icons.camera_alt,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Camera not ready',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
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
                  onPressed: _isInitialized ? () {
                    setState(() {
                      _showVideoLibrary = true;
                    });
                  } : null,
                  backgroundColor: Colors.blue,
                  child: const Icon(
                    Icons.video_library,
                    color: Colors.white,
                  ),
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

  Widget _buildVideoLibrary() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.video_library, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Video Library',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showVideoLibrary = false;
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.blue),
                ),
              ],
            ),
          ),
          if (_recordedVideos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No videos recorded yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _recordedVideos.length,
                itemBuilder: (context, index) {
                  final videoPath = _recordedVideos[index];
                  final fileName = videoPath.split('/').last;
                  final file = File(videoPath);

                  return ListTile(
                    leading: const Icon(Icons.videocam, color: Colors.red),
                    title: Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: FutureBuilder<FileStat>(
                      future: file.stat(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final size = snapshot.data!.size;
                          final date = snapshot.data!.modified;
                          return Text(
                            '${_formatFileSize(size)} • ${_formatDate(date)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          );
                        }
                        return const Text('Loading...');
                      },
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'share':
                            Share.shareXFiles([XFile(videoPath)], text: 'Face Recording Video');
                            break;
                          case 'delete':
                            _showDeleteConfirmation(videoPath);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share),
                              SizedBox(width: 8),
                              Text('Share'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Video'),
          content: const Text('Are you sure you want to delete this video? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteVideo(filePath);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
