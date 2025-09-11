import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadVideo(String filePath) async {
    final file = File(filePath);
    final fileName = filePath.split('/').last;
    final ref = _storage.ref().child('videos/$fileName');
    final uploadTask = ref.putFile(file);
    await uploadTask.whenComplete(() => null);
  }
}
