import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewOverlay extends StatelessWidget {
  final CameraController controller;
  final VoidCallback onClose;

  const CameraPreviewOverlay({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
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
                const Icon(Icons.camera_alt, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Kameravorschau',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.blue),
                ),
              ],
            ),
          ),
          Expanded(
            child: controller.value.isInitialized
                ? Center(
                    child: AspectRatio(
                      aspectRatio: 1 / controller.value.aspectRatio,
                      child: CameraPreview(controller),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
