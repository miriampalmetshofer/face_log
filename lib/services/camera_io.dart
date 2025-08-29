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

  static Future<String> saveToAppDocs(XFile videoFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'face_recording_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final savedPath = '${dir.path}/$fileName';
    await io.File(videoFile.path).copy(savedPath);
    return savedPath;
  }
}