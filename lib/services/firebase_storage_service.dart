import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/video_annotation.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadVideo(String filePath) async {
    final file = File(filePath);
    final fileName = filePath.split('/').last;
    final ref = _storage.ref().child('videos/$fileName');
    final uploadTask = ref.putFile(file);
    await uploadTask.whenComplete(() => null);
  }

  Future<void> uploadAnnotation(String videoPath, VideoAnnotation annotation) async {
    final fileName = videoPath.split('/').last;
    // Replace .mp4 extension with .json
    final jsonFileName = fileName.replaceAll('.mp4', '.json');

    // Convert annotation to JSON string
    final jsonString = json.encode(annotation.toJson());
    final jsonBytes = utf8.encode(jsonString);

    // Upload to Firebase Storage under annotations/ folder
    final ref = _storage.ref().child('annotations/$jsonFileName');
    final uploadTask = ref.putData(
      jsonBytes,
      SettableMetadata(contentType: 'application/json'),
    );
    await uploadTask.whenComplete(() => null);
  }

  /// Upload both video and annotation together
  Future<void> uploadVideoWithAnnotation(String videoPath, VideoAnnotation annotation) async {
    // Upload video first
    await uploadVideo(videoPath);
    // Then upload annotation
    await uploadAnnotation(videoPath, annotation);
  }
}
