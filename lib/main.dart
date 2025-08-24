import 'package:face_log/permissions_request.dart';
import 'package:flutter/material.dart';
import 'package:face_log/face_recording_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FaceLog New',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const FaceRecordingScreen(),
    );
  }
}
