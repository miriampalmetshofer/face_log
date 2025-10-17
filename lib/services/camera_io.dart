import 'dart:io';
import 'dart:io' show Platform;
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;

class CameraIO {
  static Future<CameraDescription?> pickFrontOrFirst() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return null;
    try {
      return cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
    } catch (_) {
      return cameras.first;
    }
  }

  static ImageFormatGroup platformImageFormat() {
    return Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888;
  }

  static Future<String> saveToAppDocs(XFile videoFile, {String? userName}) async {
    final dir = await getApplicationDocumentsDirectory();
    // Sanitize username to be filesystem-safe (remove special characters, lowercase)
    final safeName = userName?.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_').toLowerCase() ?? 'face_recording';
    // Create readable timestamp: YYYY-MM-DD_HH-mm-ss
    final now = DateTime.now();
    final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
    final fileName = '${safeName}_$timestamp.mp4';
    final savedPath = '${dir.path}/$fileName';
    await io.File(videoFile.path).copy(savedPath);
    return savedPath;
  }
}