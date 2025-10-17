import 'dart:typed_data';
import 'package:flutter/material.dart';

class VideoStatusBadge extends StatelessWidget {
  final Uint8List thumbnail;
  final bool hasAnnotation;
  final bool isUploaded;

  const VideoStatusBadge({
    super.key,
    required this.thumbnail,
    required this.hasAnnotation,
    required this.isUploaded,
  });

  @override
  Widget build(BuildContext context) {
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
  }
}
