import 'dart:io';
import 'dart:typed_data';
import 'package:face_log/screens/video_review_screen.dart';
import 'package:face_log/services/annotation_storage_service.dart';
import 'package:face_log/widgets/video_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoListItem extends StatefulWidget {
  final String videoPath;
  final VoidCallback onDelete;
  final VoidCallback onUpload;
  final VoidCallback onAnnotationChange;

  const VideoListItem({
    super.key,
    required this.videoPath,
    required this.onDelete,
    required this.onUpload,
    required this.onAnnotationChange,
  });

  @override
  State<VideoListItem> createState() => _VideoListItemState();
}

class _VideoListItemState extends State<VideoListItem> {
  Uint8List? _thumbnail;
  bool _hasAnnotation = false;
  bool _isUploaded = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _generateThumbnail(),
        AnnotationStorageService.hasAnnotation(widget.videoPath),
        AnnotationStorageService.isUploaded(widget.videoPath),
      ]);

      if (mounted) {
        setState(() {
          _thumbnail = results[0] as Uint8List?;
          _hasAnnotation = results[1] as bool;
          _isUploaded = results[2] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading video data for ${widget.videoPath}: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Uint8List?> _generateThumbnail() async {
    return await VideoThumbnail.thumbnailData(
      video: widget.videoPath,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 128,
      quality: 75,
    );
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

    if (difference.inDays >= 1) {
      // Show date + time if older than 1 day
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day.$month.$year, $hour:$minute';
    } else if (difference.inHours > 0) {
      return 'vor ${difference.inHours} Stunde${difference.inHours == 1 ? '' : 'n'}';
    } else if (difference.inMinutes > 0) {
      return 'vor ${difference.inMinutes} Minute${difference.inMinutes == 1 ? '' : 'n'}';
    } else {
      return 'Gerade eben';
    }
  }

  Future<void> _openPreview() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoReviewScreen(videoPath: widget.videoPath),
      ),
    );
    // Refresh data after returning from preview
    widget.onAnnotationChange();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.videoPath.split('/').last;
    final file = File(widget.videoPath);

    return ListTile(
      onTap: _openPreview,
      leading: _isLoading
          ? const CircularProgressIndicator()
          : _thumbnail != null
              ? VideoStatusBadge(
                  thumbnail: _thumbnail!,
                  hasAnnotation: _hasAnnotation,
                  isUploaded: _isUploaded,
                )
              : const Icon(Icons.error, color: Colors.red),
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
        onSelected: (value) async {
          switch (value) {
            case 'delete':
              widget.onDelete();
              break;
            case 'upload':
              widget.onUpload();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'upload',
            enabled: _hasAnnotation,
            child: Row(
              children: [
                Icon(
                  Icons.cloud_upload,
                  color: _hasAnnotation ? null : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hochladen',
                  style: TextStyle(
                    color: _hasAnnotation ? null : Colors.grey,
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
      ),
    );
  }
}
