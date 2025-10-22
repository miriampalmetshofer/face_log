import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';

import '../models/annotation_category.dart';
import '../models/video_annotation.dart';
import '../services/annotation_service.dart';
import '../services/annotation_storage_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/user_preferences_service.dart';
import '../widgets/annotation_form.dart';

class VideoReviewScreen extends StatefulWidget {
  final String videoPath;

  const VideoReviewScreen({super.key, required this.videoPath});

  @override
  State<VideoReviewScreen> createState() => _VideoReviewScreenState();
}

class _VideoReviewScreenState extends State<VideoReviewScreen> {
  late VideoPlayerController _controller;
  List<AnnotationCategory>? _categories;
  bool _isLoadingSchema = true;
  VideoAnnotation? _existingAnnotation;
  bool _isUploaded = false;
  final FirebaseStorageService _storageService = FirebaseStorageService();

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
      });
    _loadAnnotationSchema();
  }

  Future<void> _loadAnnotationSchema() async {
    try {
      final categories = await AnnotationService.loadSchema();
      final existingAnnotation = await AnnotationStorageService.loadAnnotation(widget.videoPath);
      final isUploaded = await AnnotationStorageService.isUploaded(widget.videoPath);
      setState(() {
        _categories = categories;
        _existingAnnotation = existingAnnotation;
        _isUploaded = isUploaded;
        _isLoadingSchema = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSchema = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load annotation schema: $e')),
        );
      }
    }
  }

  Future<void> _saveAnnotation(Map<String, dynamic> answers) async {
    try {
      final annotation = VideoAnnotation(
        videoPath: widget.videoPath,
        answers: answers,
        timestamp: DateTime.now(),
      );
      await AnnotationStorageService.saveAnnotation(annotation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annotation gespeichert'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // Navigate back to gallery after a short delay
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _shareVideo() {
    Share.shareXFiles([
      XFile(widget.videoPath),
    ], text: 'Gesichtsaufnahme Video');
  }

  Future<void> _uploadVideo() async {
    if (_existingAnnotation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte annotieren Sie das Video zuerst'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userName = await UserPreferencesService.getUserName();

    // Calculate timeout based on file size
    final file = File(widget.videoPath);
    final fileStat = await file.stat();
    final fileSizeMB = fileStat.size / (1024 * 1024);
    final timeoutSeconds = (fileSizeMB * 2).ceil() + 30;
    final timeout = Duration(seconds: timeoutSeconds.clamp(30, 300));

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Video wird hochgeladen...\n${_formatFileSize(fileStat.size)}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    try {
      await _storageService.uploadVideoWithAnnotation(widget.videoPath, _existingAnnotation!, userName: userName).timeout(
        timeout,
        onTimeout: () {
          throw Exception('Upload-Timeout: Bitte Internetverbindung prüfen');
        },
      );

      // Mark as uploaded
      await AnnotationStorageService.markAsUploaded(widget.videoPath);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Update state
      setState(() {
        _isUploaded = true;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video und Annotation erfolgreich hochgeladen!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Video Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareVideo,
            tooltip: 'Teilen',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Upload Banner (Ready to Upload) ---
            if (_existingAnnotation != null && !_isUploaded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.blue.shade100,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Video ist annotiert und bereit zum Hochladen',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _uploadVideo,
                      icon: const Icon(Icons.cloud_upload, size: 18),
                      label: const Text('Hochladen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            // --- Uploaded Banner ---
            if (_isUploaded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.green.shade100,
                child: Row(
                  children: [
                    Icon(Icons.cloud_done, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Alles erledigt. Dein Video wurde bereits hochgeladen.',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // --- Video Player ---
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600.0,
                  maxHeight: 400.0,
                ),
                child: _controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : AspectRatio(
                        aspectRatio:
                            16 / 9,
                        child: Center(child: const CircularProgressIndicator()),
                      ),
              ),
            ),

            // --- Video Controls ---
            Container(
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 12.0,
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: Theme.of(context).colorScheme.primary,
                          bufferedColor: Colors.grey,
                          backgroundColor: Colors.black26,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_5, size: 35.0),
                            onPressed: () {
                              final newPosition =
                                  _controller.value.position -
                                  const Duration(seconds: 5);
                              _controller.seekTo(
                                newPosition.isNegative
                                    ? Duration.zero
                                    : newPosition,
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 35.0,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.forward_5, size: 35.0),
                            onPressed: () {
                              final newPosition =
                                  _controller.value.position +
                                  const Duration(seconds: 5);
                              _controller.seekTo(
                                newPosition > _controller.value.duration
                                    ? _controller.value.duration
                                    : newPosition,
                              );
                            },
                          ),
                          Text(
                            '${_printDuration(_controller.value.position)} / ${_printDuration(_controller.value.duration)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(),

            // --- Dynamic Annotation Form ---
            _isLoadingSchema
                ? const Center(child: CircularProgressIndicator())
                : _categories != null
                    ? AnnotationFormContent(
                        categories: _categories!,
                        initialAnswers: _existingAnnotation?.answers,
                        onSave: _saveAnnotation,
                      )
                    : const Center(
                        child: Text('Failed to load annotation schema'),
                      ),
          ],
        ),
      ),
    );
  }
}
