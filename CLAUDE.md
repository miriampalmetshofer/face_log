# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FaceLog is a Flutter mobile application for recording face videos using the device's front camera. Videos are saved locally and can be uploaded to Firebase Storage. The app includes video preview, playback, annotation capabilities, and an embedded web browser for social media.

## Development Commands

### Setup
```bash
flutter pub get
flutter doctor  # Verify Flutter setup
```

### Running the App
```bash
# Android
flutter run -d <android_device>

# iOS (Debug mode may crash on swipe-close)
flutter run -d <ios_device>

# iOS (Profile mode - recommended for testing cold starts)
flutter run --profile -d <ios_device>
```

### Building for Release
```bash
# iOS
flutter build ios --release
# Then open in Xcode for signing & distribution

# Android
flutter build apk --release
flutter build appbundle --release
```

### Testing
```bash
flutter test
```

## Architecture

### Screen Flow
The app follows a simple navigation hierarchy:
- **FaceRecordingScreen** (main.dart): Entry point and main camera interface
  - **VideoLibraryScreen**: Browse recorded videos with thumbnails
    - **VideoReviewScreen**: Video playback with annotation form
  - **InAppBrowser**: Embedded webview for social media sites

### Core Components

**Services** (`lib/services/`):
- `camera_io.dart`: Platform-specific camera utilities
  - `pickFrontOrFirst()`: Selects front camera or falls back to first available
  - `platformImageFormat()`: Returns YUV420 for Android, BGRA8888 for iOS
  - `saveToAppDocs()`: Saves recorded video to app documents directory with timestamp
- `firebase_storage_service.dart`: Handles video uploads to Firebase Storage under `videos/` path

**Screens** (`lib/screens/`):
- `face_recording_screen.dart`: Main recording interface with:
  - Front camera preview (toggleable)
  - Recording timer (max duration configured in `config.dart`)
  - Social media app shortcuts (Instagram, Facebook, TikTok)
  - Recording status banner
- `video_library_screen.dart`: Lists all recorded videos with:
  - Thumbnail generation and caching
  - File metadata (size, date)
  - Actions: preview, share, upload to Firebase, delete
- `video_review_screen.dart`: Video playback with:
  - Video player controls (play/pause, seek ±5s, progress bar)
  - Dynamic annotation form (loaded from hardcoded JSON schema)

**Widgets** (`lib/widgets/`):
- `annotation_option.dart`: Dynamic form system with:
  - `AnnotationCategory`: Form field schema (single_choice, multiple_choice, text)
  - `AnnotationForm`: Renders form from JSON schema with conditional visibility
- `status_banner.dart`: Recording status indicator
- `controls.dart`: Bottom control bar for recording screen

**Other**:
- `config.dart`: Application configuration (currently only `maxRecordingDuration = 10` seconds)
- `in_app_browser.dart`: Webview wrapper for embedded browsing
- `permissions_request.dart`: Requests camera and microphone permissions on startup

### Firebase Integration
- Firebase is initialized in `main.dart` before app starts
- Firebase Storage used for video uploads
- Firebase App Check configured (iOS/Android specific setup required)
- Configuration files: `android/app/google-services.json`, iOS Info.plist

### Video Storage
Videos are saved to the app's documents directory with the naming pattern:
```
face_recording_<timestamp>.mp4
```

### Platform-Specific Notes
- **iOS**: Debug mode has known camera plugin issues when app is closed and reopened. Use `--profile` mode for testing cold starts.
- **Android**: Uses YUV420 image format for better performance
- Permissions are defined in `ios/Runner/Info.plist` (NSCameraUsageDescription, NSMicrophoneUsageDescription)

### Key Dependencies
- `camera`: Video recording
- `video_player`: Playback
- `video_thumbnail`: Thumbnail generation
- `firebase_core`, `firebase_storage`, `firebase_app_check`: Backend storage
- `flutter_inappwebview`: Embedded browser
- `share_plus`: Sharing videos
- `path_provider`: Local storage access
- `permission_handler`: Runtime permissions

## Code Structure Guidelines

When working on this codebase, adhere to the following principles:

### File Organization
- **Keep files small and focused**: Each file should have a single, clear responsibility
- **Extract reusable components**: Move dialogs, complex widgets, and reusable UI elements into separate files in `lib/widgets/`
- **Maximum file size**: Aim to keep files under ~300 lines. If a file grows beyond this, consider extracting components
- **Component naming**: Use descriptive names that clearly indicate the component's purpose (e.g., `unsaved_changes_dialog.dart`, `upload_progress_dialog.dart`)

### Component Structure
- **Dialog pattern**: For reusable dialogs, create a stateless class with a static `show()` method that returns the expected type
  ```dart
  class MyDialog {
    static Future<bool> show(BuildContext context) async {
      // Dialog implementation
    }
  }
  ```
- **Widget extraction**: When a screen's build method becomes too complex, extract sections into separate widget files
- **Separation of concerns**: Keep business logic in services, UI in widgets/screens, and configuration in `config.dart`

### Configuration Management
- **Centralize constants**: All configurable values (timeouts, durations, sizes, etc.) should be defined in `config.dart`
- **Avoid magic numbers**: Use named constants from `config.dart` instead of hardcoded values
- **Configuration categories**: Group related constants together in the `AppConfig` class

### Best Practices
- **Single responsibility**: Each widget, screen, or service should do one thing well
- **Reusability**: Extract common patterns into shared components
- **Readability**: Prefer multiple small files over large, monolithic ones
- **Maintainability**: Make it easy to find and modify specific functionality by keeping related code together

## Important Notes

- The app is currently in German language (UI strings like "Kamera wird initialisiert...")
- The annotation schema in `video_review_screen.dart` is currently hardcoded as JSON - this will likely need to be loaded from a config file or API
- Recording duration is capped at 10 seconds (configurable in `config.dart`)
- The app requires physical devices for testing (camera support limited on simulators/emulators)
- Firebase configuration must be set up before building (google-services.json for Android, Info.plist for iOS)
