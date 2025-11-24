import 'package:face_log/config.dart';
import 'package:face_log/services/annotation_storage_service.dart';
import 'package:face_log/services/firebase_storage_service.dart';
import 'package:face_log/services/user_preferences_service.dart';
import 'package:face_log/widgets/video_list_item.dart';
import 'package:face_log/widgets/video_library_info_dialog.dart';
import 'package:face_log/widgets/upload_progress_dialog.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VideoLibraryScreen extends StatefulWidget {
  const VideoLibraryScreen({super.key});

  @override
  State<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends State<VideoLibraryScreen> {
  List<String> _recordedVideos = [];
  final FirebaseStorageService _storageService = FirebaseStorageService();
  int _refreshCounter = 0;

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
                !file.path.endsWith('.uploaded') &&
                !file.path.endsWith('.json'),
          )
          .map((file) => file.path)
          .toList();

      // Sort by recording date (extracted from filename), newest first
      videoFiles.sort((a, b) {
        final aFileName = a.split('/').last;
        final bFileName = b.split('/').last;

        // Extract timestamp from filename (format: name_YYYY-MM-DD_HH-mm-ss.mp4)
        final aTimestamp = _extractTimestampFromFilename(aFileName);
        final bTimestamp = _extractTimestampFromFilename(bFileName);

        if (aTimestamp != null && bTimestamp != null) {
          return bTimestamp.compareTo(aTimestamp); // Descending order
        }

        // Fallback to modification date if timestamp extraction fails
        final aFile = File(a);
        final bFile = File(b);
        final aModified = aFile.statSync().modified;
        final bModified = bFile.statSync().modified;
        return bModified.compareTo(aModified);
      });

      setState(() {
        _recordedVideos = videoFiles;
      });
      debugPrint('Loaded ${_recordedVideos.length} existing videos');
    } catch (e) {
      debugPrint('Error loading existing videos: $e');
    }
  }

  DateTime? _extractTimestampFromFilename(String filename) {
    try {
      // Expected format: name_YYYY-MM-DD_HH-mm-ss.mp4
      final regex = RegExp(r'(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})\.mp4$');
      final match = regex.firstMatch(filename);

      if (match != null) {
        final year = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        final second = int.parse(match.group(6)!);

        return DateTime(year, month, day, hour, minute, second);
      }
    } catch (e) {
      debugPrint('Error parsing timestamp from filename: $filename');
    }
    return null;
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

    // Get username for subfolder organization
    final userName = await UserPreferencesService.getUserName();

    // Calculate timeout based on file size
    final file = File(filePath);
    final fileStat = await file.stat();
    final timeout = Duration(seconds: AppConfig.uploadTimeoutMaxSeconds);

    // Show progress dialog
    final progressKey = GlobalKey<UploadProgressDialogState>();
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return UploadProgressDialog(
            key: progressKey,
            totalBytes: fileStat.size,
          );
        },
      );
    }

    try {
      await _storageService.uploadVideoWithAnnotation(
        filePath,
        annotation,
        userName: userName,
        onProgress: (progress) {
          progressKey.currentState?.updateProgress(progress);
        },
      ).timeout(
        timeout,
        onTimeout: () {
          throw Exception('Upload-Timeout: Bitte Internetverbindung prüfen');
        },
      );

      // Mark as uploaded
      await AnnotationStorageService.markAsUploaded(filePath);

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
        setState(() {
          _refreshCounter++;
        });
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
      appBar: AppBar(
        title: const Text('Videobibliothek'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => VideoLibraryInfoDialog.show(context),
            tooltip: 'Informationen',
          ),
        ],
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
                  return VideoListItem(
                    key: ValueKey('$videoPath-$_refreshCounter'),
                    videoPath: videoPath,
                    onDelete: () => _showDeleteConfirmation(videoPath),
                    onUpload: () => _uploadVideo(videoPath),
                    onAnnotationChange: () => setState(() {
                      _refreshCounter++;
                    }),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
