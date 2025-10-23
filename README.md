# FaceLog – Flutter App

This app records face videos using the device’s **front camera** and saves them locally.

---

## Setup

### Requirements

* Flutter (latest stable)
* Xcode (for iOS)
* Android Studio (for Android)
* Physical device (camera support is limited on simulators/emulators)

### Install packages

```bash
flutter pub get
```

### Verify setup

```bash
flutter doctor
```

---

## Running

### Android

```bash
flutter run -d <android_device>
```

### iOS

* Run normally with:

```bash
flutter run -d <ios_device>
```

* **Important**: In **Debug mode** the app may crash if you swipe-close it and reopen from the Home screen. This is a known issue with the camera plugin.

    * To test cold starts, use:

```bash
flutter run --profile -d <ios_device>
```

---
## Permissions

Make sure `ios/Runner/Info.plist` includes:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera is used to record face videos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone is used to record audio with videos.</string>
```

On Android, the camera and microphone permissions are handled by the `camera` plugin.

---

## Build for release

### iOS

```bash
flutter build ios --release
```

Open in Xcode for signing & distribution.

### Android

```bash
flutter build apk --release
flutter build appbundle --release
```

