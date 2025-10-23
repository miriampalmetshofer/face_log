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

---

## Troubleshooting

### iOS Build Fails: "resource fork, Finder information, or similar detritus not allowed"

**Problem**: iOS build fails with codesigning error mentioning "resource fork" or "similar detritus not allowed".

**Cause**: Image files (PNG, JPG) in your project have macOS extended attributes attached to them. This commonly happens when:
- Images are downloaded from the internet (ChatGPT, web browsers, etc.)
- Files are copied from the Downloads folder
- Images are edited with certain macOS apps

These attributes propagate through Flutter's build process and cause Apple's codesigning to fail.

**Solution**:

1. **Clean all image files** in your project:
   ```bash
   find . -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -exec xattr -c {} \;
   ```

2. **Clean Flutter build cache**:
   ```bash
   flutter clean
   ```

3. **Rebuild**:
   ```bash
   flutter run --release -d <ios_device>
   ```

4. **Commit the cleaned files** to git to prevent the issue from recurring.

**Prevention**: Always clean extended attributes from new images before adding them to the project:
```bash
xattr -c path/to/new/image.png
```

