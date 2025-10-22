import 'package:flutter/material.dart';

class UploadProgressDialog extends StatefulWidget {
  final int totalBytes;

  const UploadProgressDialog({
    super.key,
    required this.totalBytes,
  });

  @override
  State<UploadProgressDialog> createState() => UploadProgressDialogState();
}

class UploadProgressDialogState extends State<UploadProgressDialog> {
  double _progress = 0.0;

  void updateProgress(double progress) {
    if (mounted) {
      setState(() {
        _progress = progress.clamp(0.0, 1.0);
      });
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
    final percentage = (_progress * 100).toInt();
    final uploadedBytes = (widget.totalBytes * _progress).toInt();

    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Circular progress indicator
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Linear progress bar
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey.shade200,
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            // Upload text
            const Text(
              'Video wird hochgeladen...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // File size progress
            Text(
              '${_formatFileSize(uploadedBytes)} von ${_formatFileSize(widget.totalBytes)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
