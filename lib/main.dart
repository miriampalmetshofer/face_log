import 'package:face_log/permissions_request.dart';
import 'package:face_log/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:face_log/screens/face_recording_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await requestPermissions();

  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();

    // Schedule daily reminder at 9:00 AM
    await notificationService.scheduleDailyReminder(hour: 9, minute: 0);
    print('✅ Notifications initialized and scheduled successfully');
  } catch (e, stackTrace) {
    print('⚠️ Failed to initialize notifications: $e');
    print('Stack trace: $stackTrace');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FaceLog New',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const FaceRecordingScreen(),
    );
  }
}
