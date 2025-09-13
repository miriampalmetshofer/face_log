import 'package:face_log/services/firebase_storage_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class VideoLibrary extends StatefulWidget {
  final Function onToggleLibrary;

  const VideoLibrary({super.key, required this.onToggleLibrary});

  @override
  State<VideoLibrary> createState() => _VideoLibraryState();
}

class _VideoLibraryState extends State<VideoLibrary> {
  List<String> _recordedVideos = [];
  final FirebaseStorageService _storageService = FirebaseStorageService();

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wird hochgeladen...')),
    );
    try {
      await _storageService.uploadVideo(filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload erfolgreich!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload fehlgeschlagen.')),
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
                  'Videobibliothek',
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
                      widget.onToggleLibrary();
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
                        return const Text('Wird geladen...');
                      },
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
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
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share),
                              SizedBox(width: 8),
                              Text('Teilen'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'upload',
                          child: Row(
                            children: [
                              Icon(Icons.cloud_upload),
                              SizedBox(width: 8),
                              Text('Hochladen'),
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