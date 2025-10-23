import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/video_annotation.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadVideo(String filePath, {String? userName, void Function(double)? onProgress}) async {
    try {
      final file = File(filePath);
      final fileName = filePath.split('/').last;

      final sanitizedUserName = userName?.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_').toLowerCase() ?? 'unknown';

      // Upload to {username}/videos/{filename}
      final ref = _storage.ref().child('$sanitizedUserName/videos/$fileName');
      final uploadTask = ref.putFile(file);

      // Listen to upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      await uploadTask.whenComplete(() => null);
    } on FirebaseException catch (e) {
      throw Exception('Firebase upload failed: ${e.message}');
    } on SocketException catch (e) {
      throw Exception('Keine Internetverbindung: ${e.message}');
    } catch (e) {
      throw Exception('Upload fehlgeschlagen: $e');
    }
  }

  Future<void> uploadAnnotation(String videoPath, VideoAnnotation annotation, {String? userName, void Function(double)? onProgress}) async {
    try {
      final fileName = videoPath.split('/').last;
      // Replace .mp4 extension with .json
      final jsonFileName = fileName.replaceAll('.mp4', '.json');

      // Convert annotation to JSON string using upload format
      final jsonString = json.encode(annotation.toUploadJson(userName ?? 'unknown'));
      final jsonBytes = utf8.encode(jsonString);

      // Sanitize username for Firebase Storage path (remove special characters)
      final sanitizedUserName = userName?.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_').toLowerCase() ?? 'unknown';

      // Upload to {username}/annotations/{filename}
      final ref = _storage.ref().child('$sanitizedUserName/annotations/$jsonFileName');
      final uploadTask = ref.putData(
        jsonBytes,
        SettableMetadata(contentType: 'application/json'),
      );

      // Listen to upload progress (annotations are small, will be fast)
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

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
  /// Progress callback reports combined progress (video=99%, annotation=1%)
  Future<void> uploadVideoWithAnnotation(String videoPath, VideoAnnotation annotation, {String? userName, void Function(double)? onProgress}) async {
    // Upload video first (99% of the total progress)
    await uploadVideo(
      videoPath,
      userName: userName,
      onProgress: onProgress != null
          ? (videoProgress) => onProgress(videoProgress * 0.99)
          : null,
    );
    // Then upload annotation (last 1% of progress)
    await uploadAnnotation(
      videoPath,
      annotation,
      userName: userName,
      onProgress: onProgress != null
          ? (annotationProgress) => onProgress(0.99 + (annotationProgress * 0.01))
          : null,
    );
  }
}
