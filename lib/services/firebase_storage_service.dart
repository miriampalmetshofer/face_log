import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/video_annotation.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadVideo(String filePath, {String? userName}) async {
    try {
      final file = File(filePath);
      final fileName = filePath.split('/').last;

      final sanitizedUserName = userName?.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_').toLowerCase() ?? 'unknown';

      // Upload to {username}/videos/{filename}
      final ref = _storage.ref().child('$sanitizedUserName/videos/$fileName');
      final uploadTask = ref.putFile(file);
      await uploadTask.whenComplete(() => null);
    } on FirebaseException catch (e) {
      throw Exception('Firebase upload failed: ${e.message}');
    } on SocketException catch (e) {
      throw Exception('Keine Internetverbindung: ${e.message}');
    } catch (e) {
      throw Exception('Upload fehlgeschlagen: $e');
    }
  }

  Future<void> uploadAnnotation(String videoPath, VideoAnnotation annotation, {String? userName}) async {
    try {
      final fileName = videoPath.split('/').last;
      // Replace .mp4 extension with .json
      final jsonFileName = fileName.replaceAll('.mp4', '.json');

      // Convert annotation to JSON string
      final jsonString = json.encode(annotation.toJson());
      final jsonBytes = utf8.encode(jsonString);

      // Sanitize username for Firebase Storage path (remove special characters)
      final sanitizedUserName = userName?.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_').toLowerCase() ?? 'unknown';

      // Upload to {username}/annotations/{filename}
      final ref = _storage.ref().child('$sanitizedUserName/annotations/$jsonFileName');
      final uploadTask = ref.putData(
        jsonBytes,
        SettableMetadata(contentType: 'application/json'),
      );
      await uploadTask.whenComplete(() => null);
    } on FirebaseException catch (e) {
      throw Exception('Firebase upload failed: ${e.message}');
    } on SocketException catch (e) {
      throw Exception('Keine Internetverbindung: ${e.message}');
    } catch (e) {
      throw Exception('Annotation upload fehlgeschlagen: $e');
    }
  }

  /// Upload both video and annotation together
  Future<void> uploadVideoWithAnnotation(String videoPath, VideoAnnotation annotation, {String? userName}) async {
    // Upload video first
    await uploadVideo(videoPath, userName: userName);
    // Then upload annotation
    await uploadAnnotation(videoPath, annotation, userName: userName);
  }
}
