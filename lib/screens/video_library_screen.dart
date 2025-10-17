import 'dart:typed_data';

import 'package:face_log/screens/video_review_screen.dart';
import 'package:face_log/services/annotation_storage_service.dart';
import 'package:face_log/services/firebase_storage_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoLibraryScreen extends StatefulWidget {
  const VideoLibraryScreen({super.key});

  @override
  State<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends State<VideoLibraryScreen> {
  List<String> _recordedVideos = [];
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final Map<String, Uint8List?> _thumbnailCache = {};
  final Map<String, bool> _hasAnnotationCache = {};
  final Map<String, bool> _isUploadedCache = {};

  @override
  void initState() {
    super.initState();
    _loadExistingVideos();
  }

  Future<void> _loadExistingVideos() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      final videoFiles = files
          .where(
            (file) =>
                file.path.endsWith('.mp4') &&
                file.path.contains('face_recording_'),
          )
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

  Future<Uint8List?> _generateThumbnail(String videoPath) async {
    if (_thumbnailCache.containsKey(videoPath)) {
      return _thumbnailCache[videoPath];
    }

    final thumbnail = await VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 128, // specify the width of the thumbnail, let the height auto-scale
      quality: 75,
    );

    _thumbnailCache[videoPath] = thumbnail;
    return thumbnail;
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

  void _showDeleteConfirmation(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Video löschen'),
          content: const Text(
            'Möchten Sie dieses Video wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteVideo(filePath);
              },
              child: const Text('Löschen', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadVideo(String filePath) async {
    // Check if annotation exists
    final annotation = await AnnotationStorageService.loadAnnotation(filePath);
    if (annotation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bitte annotieren Sie das Video zuerst'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Calculate timeout based on file size (assume 1MB per second upload speed minimum)
    final file = File(filePath);
    final fileStat = await file.stat();
    final fileSizeMB = fileStat.size / (1024 * 1024);
    final timeoutSeconds = (fileSizeMB * 2).ceil() + 30; // 2 seconds per MB + 30s base
    final timeout = Duration(seconds: timeoutSeconds.clamp(30, 300)); // Min 30s, max 5min

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
      await _storageService.uploadVideoWithAnnotation(filePath, annotation)
          .timeout(
        timeout,
        onTimeout: () {
          throw Exception('Upload-Timeout: Bitte Internetverbindung prüfen');
        },
      );

      // Mark as uploaded
      await AnnotationStorageService.markAsUploaded(filePath);
      _isUploadedCache[filePath] = true;

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video und Annotation erfolgreich hochgeladen!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        // Refresh the list to update badge
        setState(() {});
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

  Future<bool> _hasAnnotation(String videoPath) async {
    // Use cache to avoid repeated checks
    if (_hasAnnotationCache.containsKey(videoPath)) {
      return _hasAnnotationCache[videoPath]!;
    }

    final hasAnnotation = await AnnotationStorageService.hasAnnotation(videoPath);
    _hasAnnotationCache[videoPath] = hasAnnotation;
    return hasAnnotation;
  }

  Future<bool> _isUploaded(String videoPath) async {
    // Use cache to avoid repeated checks
    if (_isUploadedCache.containsKey(videoPath)) {
      return _isUploadedCache[videoPath]!;
    }

    final isUploaded = await AnnotationStorageService.isUploaded(videoPath);
    _isUploadedCache[videoPath] = isUploaded;
    return isUploaded;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'vor ${difference.inDays} Tag${difference.inDays == 1 ? '' : 'en'}';
    } else if (difference.inHours > 0) {
      return 'vor ${difference.inHours} Stunde${difference.inHours == 1 ? '' : 'n'}';
    } else if (difference.inMinutes > 0) {
      return 'vor ${difference.inMinutes} Minute${difference.inMinutes == 1 ? '' : 'n'}';
    } else {
      return 'Gerade eben';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videobibliothek'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recordedVideos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Noch keine Videos aufgenommen',
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
                    leading: FutureBuilder<Map<String, dynamic>>(
                      future: Future.wait([
                        _generateThumbnail(videoPath),
                        _hasAnnotation(videoPath),
                        _isUploaded(videoPath),
                      ]).then((results) => {
                        'thumbnail': results[0] as Uint8List?,
                        'hasAnnotation': results[1] as bool,
                        'isUploaded': results[2] as bool,
                      }),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                          final thumbnail = snapshot.data!['thumbnail'] as Uint8List?;
                          final hasAnnotation = snapshot.data!['hasAnnotation'] as bool;
                          final isUploaded = snapshot.data!['isUploaded'] as bool;

                          // Determine badge color and icon based on state
                          Color badgeColor;
                          IconData badgeIcon;
                          if (isUploaded) {
                            badgeColor = Colors.green;
                            badgeIcon = Icons.cloud_done;
                          } else if (hasAnnotation) {
                            badgeColor = Colors.blue;
                            badgeIcon = Icons.cloud_upload;
                          } else {
                            badgeColor = Colors.orange;
                            badgeIcon = Icons.edit;
                          }

                          if (thumbnail != null) {
                            return Stack(
                              children: [
                                Image.memory(
                                  thumbnail,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: badgeColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      badgeIcon,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return const Icon(Icons.error, color: Colors.red);
                          }
                        } else if (snapshot.hasError) {
                          debugPrint('Error generating thumbnail for $videoPath: ${snapshot.error}');
                          return const Icon(Icons.error, color: Colors.red);
                        } else {
                          return const CircularProgressIndicator(); // Placeholder while loading
                        }
                      },
                    ),
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
                        return const Text('Wird geladen...');
                      },
                    ),
                    trailing: FutureBuilder<bool>(
                      future: _hasAnnotation(videoPath),
                      builder: (context, snapshot) {
                        final hasAnnotation = snapshot.data ?? false;

                        return PopupMenuButton<String>(
                          onSelected: (value) async {
                            switch (value) {
                              case 'preview':
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VideoReviewScreen(videoPath: videoPath),
                                  ),
                                );
                                // Clear cache when returning from preview (in case annotation was added/modified)
                                if (result == null) {
                                  setState(() {
                                    _hasAnnotationCache.remove(videoPath);
                                  });
                                }
                                break;
                              case 'share':
                                Share.shareXFiles([
                                  XFile(videoPath),
                                ], text: 'Gesichtsaufnahme Video');
                                break;
                              case 'delete':
                                _showDeleteConfirmation(videoPath);
                                break;
                              case 'upload':
                                _uploadVideo(videoPath);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'preview',
                              child: Row(
                                children: [
                                  Icon(Icons.remove_red_eye),
                                  SizedBox(width: 8),
                                  Text('Vorschau'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share),
                                  SizedBox(width: 8),
                                  Text('Teilen'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'upload',
                              enabled: hasAnnotation,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cloud_upload,
                                    color: hasAnnotation ? null : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Hochladen',
                                    style: TextStyle(
                                      color: hasAnnotation ? null : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Löschen',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
