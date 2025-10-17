import 'package:face_log/config.dart';
import 'package:face_log/in_app_browser.dart';
import 'package:face_log/screens/video_library_screen.dart';
import 'package:face_log/services/camera_io.dart';
import 'package:face_log/services/camera_manager.dart';
import 'package:face_log/utils/format_utils.dart';
import 'package:face_log/widgets/camera_preview_overlay.dart';
import 'package:face_log/widgets/controls.dart';
import 'package:face_log/widgets/social_media_shortcuts.dart';
import 'package:face_log/widgets/status_banner.dart';
import 'package:face_log/widgets/user_name_display.dart';
import 'package:face_log/services/user_preferences_service.dart';
import 'package:flutter/material.dart';

class FaceRecordingScreen extends StatefulWidget {
  const FaceRecordingScreen({super.key});

  @override
  State<FaceRecordingScreen> createState() => _FaceRecordingScreenState();
}

class _FaceRecordingScreenState extends State<FaceRecordingScreen> {
  final CameraManager _cameraManager = CameraManager();

  bool _isRecording = false;
  String _statusMessage = 'Kamera wird initialisiert...';
  bool _showBrowser = false;
  bool _showCameraPreview = false;
  String _browserUrl = '';
  int _remainingSeconds = AppConfig.maxRecordingDuration;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _setupCameraManager();
    _initializeCamera();
    _checkAndPromptForName();
  }

  Future<void> _checkAndPromptForName() async {
    final hasName = await UserPreferencesService.hasUserName();

    if (!hasName) {
      // Wait a bit for the UI to settle
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showNameInputDialog();
      }
    } else {
      final name = await UserPreferencesService.getUserName();
      setState(() {
        _userName = name;
      });
    }
  }

  void _showNameInputDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Hi!'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Wie heißt du?',
            ),
            autofocus: true,
            onSubmitted: (value) async {
              if (value.isNotEmpty) {
                await UserPreferencesService.saveUserName(value);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  setState(() {
                    _userName = value;
                  });
                }
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await UserPreferencesService.saveUserName(controller.text);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    setState(() {
                      _userName = controller.text;
                    });
                  }
                }
              },
              child: const Text('Weiter'),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshUserName() async {
    final name = await UserPreferencesService.getUserName();
    setState(() {
      _userName = name;
    });
  }

  @override
  void dispose() {
    _cameraManager.dispose();
    super.dispose();
  }

  void _setupCameraManager() {
    _cameraManager.onStatusChange = (message) {
      if (mounted) {
        setState(() => _statusMessage = message);
      }
    };

    _cameraManager.onRecordingStateChange = (isRecording) {
      if (mounted) {
        setState(() => _isRecording = isRecording);
      }
    };

    _cameraManager.onTimerTick = (seconds) {
      if (mounted) {
        setState(() => _remainingSeconds = seconds);
      }
    };

    _cameraManager.onRecordingComplete = (videoFile) async {
      await CameraIO.saveToAppDocs(videoFile);
      if (mounted) {
        setState(() {
          _statusMessage = 'Video gespeichert!';
          _remainingSeconds = AppConfig.maxRecordingDuration;
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _statusMessage = 'Kamera bereit');
          }
        });
      }
    };

    _cameraManager.onMaxDurationReached = () {
      _showRecordingStoppedDialog();
    };
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraManager.initialize();
    } catch (e) {
      setState(() => _statusMessage = 'Kamera konnte nicht initialisiert werden: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (!_cameraManager.isInitialized) return;

    try {
      if (_isRecording) {
        final videoFile = await _cameraManager.stopRecording();
        if (videoFile != null) {
          await CameraIO.saveToAppDocs(videoFile);
          setState(() {
            _statusMessage = 'Video gespeichert!';
            _remainingSeconds = AppConfig.maxRecordingDuration;
          });

          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() => _statusMessage = 'Kamera bereit');
            }
          });
        }
      } else {
        await _cameraManager.startRecording();
      }
    } catch (e) {
      setState(() => _statusMessage = 'Fehler: $e');
    }
  }

  Future<void> _toggleCameraPreview() async {
    final newState = !_showCameraPreview;

    if (newState) {
      await _cameraManager.resumePreview();
    } else if (!_isRecording) {
      await _cameraManager.pausePreview();
    }

    setState(() => _showCameraPreview = newState);
  }

  void _openBrowser(String url) {
    setState(() {
      _showBrowser = true;
      _browserUrl = url;
    });
  }

  void _openVideoLibrary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VideoLibraryScreen()),
    );
  }

  void _closeBrowser() {
    setState(() => _showBrowser = false);
  }

  void _showRecordingStoppedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aufnahme gestoppt'),
        content: Text(
          'Die Aufnahme wurde nach ${AppConfig.maxRecordingDuration} Sekunden automatisch gestoppt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
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
                  FormatUtils.formatDuration(_remainingSeconds),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_userName != null && !_showBrowser)
              UserNameDisplay(
                userName: _userName!,
                onNameChanged: _refreshUserName,
              ),
            Expanded(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (_showCameraPreview && _cameraManager.controller != null)
                    CameraPreviewOverlay(
                      controller: _cameraManager.controller!,
                      onClose: _toggleCameraPreview,
                    )
                  else if (!_showBrowser)
                    SocialMediaShortcuts(onAppTap: _openBrowser),
                  if (_showBrowser)
                    InAppBrowser(
                      url: _browserUrl,
                      onClose: _closeBrowser,
                    ),
                ],
              ),
            ),
            if (!_showBrowser)
              Controls(
                isInitialized: _cameraManager.isInitialized,
                isRecording: _isRecording,
                onOpenLibrary: _openVideoLibrary,
                onToggleRecording: _toggleRecording,
                onTogglePreview: _toggleCameraPreview,
              ),
          ],
        ),
      ),
    );
  }
}
