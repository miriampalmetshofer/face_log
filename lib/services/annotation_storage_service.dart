import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/video_annotation.dart';

class AnnotationStorageService {
  static const String _annotationsFileName = 'annotations.json';

  /// Get the path to the annotations file
  static Future<String> _getAnnotationsFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, _annotationsFileName);
  }

  /// Load all annotations from storage
  static Future<Map<String, VideoAnnotation>> _loadAllAnnotations() async {
    try {
      final filePath = await _getAnnotationsFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        return {};
      }

      final contents = await file.readAsString();
      final jsonData = json.decode(contents) as Map<String, dynamic>;

      final annotations = <String, VideoAnnotation>{};
      jsonData.forEach((key, value) {
        annotations[key] = VideoAnnotation.fromJson(value as Map<String, dynamic>);
      });

      return annotations;
    } catch (e) {
      // Silent fail - return empty map if file doesn't exist or is corrupt
      return {};
    }
  }

  /// Save all annotations to storage
  static Future<void> _saveAllAnnotations(Map<String, VideoAnnotation> annotations) async {
    try {
      final filePath = await _getAnnotationsFilePath();
      final file = File(filePath);

      final jsonData = <String, dynamic>{};
      annotations.forEach((key, value) {
        jsonData[key] = value.toJson();
      });

      await file.writeAsString(json.encode(jsonData));
    } catch (e) {
      // Re-throw to allow caller to handle the error
      rethrow;
    }
  }

  /// Save an annotation for a specific video
  static Future<void> saveAnnotation(VideoAnnotation annotation) async {
    final annotations = await _loadAllAnnotations();
    annotations[annotation.videoPath] = annotation;
    await _saveAllAnnotations(annotations);
  }

  /// Load an annotation for a specific video
  static Future<VideoAnnotation?> loadAnnotation(String videoPath) async {
    final annotations = await _loadAllAnnotations();
    return annotations[videoPath];
  }

  /// Delete an annotation for a specific video
  static Future<void> deleteAnnotation(String videoPath) async {
    final annotations = await _loadAllAnnotations();
    annotations.remove(videoPath);
    await _saveAllAnnotations(annotations);
  }

  /// Check if an annotation exists for a specific video
  static Future<bool> hasAnnotation(String videoPath) async {
    final annotations = await _loadAllAnnotations();
    return annotations.containsKey(videoPath);
  }

  /// Get all annotations
  static Future<List<VideoAnnotation>> getAllAnnotations() async {
    final annotations = await _loadAllAnnotations();
    return annotations.values.toList();
  }
}
