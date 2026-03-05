# WebHat StoryPack - Android Custom Engine

This directory contains the professional Android custom engine for WebHat StoryPack, built with Flutter and optimized for performance.

## Features

### 🔧 Custom Application Class (`WebHatApplication.kt`)
- **Pre-warmed Flutter Engine**: Reduces initial startup time by caching the Flutter engine
- **Memory Management**: Automatic cache clearing on low memory
- **MultiDex Support**: For older Android devices
- **StrictMode**: Debug build performance monitoring

### 🎯 Custom MainActivity (`MainActivity.kt`)
- **Method Channel**: Bidirectional communication between Flutter and native Android
- **Intent Handling**: Deep links, file opens, and share receivers
- **File Sharing**: Native Android share sheet integration
- **Cache Management**: Calculate and clear app caches

### 📱 AndroidManifest.xml
- **File Association**: Opens `.webhat` files from file managers
- **Deep Links**: Custom `webhat://` scheme support
- **Share Receiver**: Accepts shared files from other apps
- **Security**: Network security config and file provider setup

### ⚡ Performance Optimizations
- **ProGuard/R8**: Code shrinking and obfuscation for release builds
- **ABI Splitting**: Separate APKs for different architectures
- **Build Cache**: Gradle build caching enabled
- **Resource Shrinking**: Removes unused resources

## Project Structure

```
android/
├── app/
│   ├── src/
│   │   └── main/
│   │       ├── kotlin/com/webhat/storypack/
│   │       │   ├── WebHatApplication.kt    # Custom Application class
│   │       │   └── MainActivity.kt          # Custom Activity with method channel
│   │       ├── res/xml/
│   │       │   ├── file_paths.xml           # FileProvider paths
│   │       │   ├── network_security_config.xml
│   │       │   ├── backup_rules.xml
│   │       │   └── data_extraction_rules.xml
│   │       └── AndroidManifest.xml
│   ├── build.gradle                         # App-level build config
│   └── proguard-rules.pro                   # ProGuard rules
├── build.gradle                             # Project-level build config
├── gradle.properties                        # Gradle settings
└── settings.gradle                          # Project settings
```

## Native Method Channel API

### Flutter → Native Methods

| Method | Parameters | Return | Description |
|--------|------------|--------|-------------|
| `getAppVersion` | - | `String` | Get app version name |
| `getBuildNumber` | - | `int` | Get build number |
| `clearCache` | - | `bool` | Clear all caches |
| `getCacheSize` | - | `int` | Get cache size in bytes |
| `shareFile` | `filePath` | `bool` | Share file via Android share sheet |
| `openFile` | `filePath` | `bool` | Open file with external app |

### Native → Flutter Methods

| Method | Parameters | Description |
|--------|------------|-------------|
| `onWebHatFileOpened` | `filePath` | When a .webhat file is opened |
| `onWebHatFileShared` | `filePath` | When a file is shared to the app |

## Usage in Flutter

```dart
import 'services/native_channel.dart';

// Get native channel service
final nativeChannel = NativeChannelService();

// Get app version
final version = await nativeChannel.getAppVersion();
print('App version: $version');

// Listen for file opens
nativeChannel.onWebHatFileOpened.listen((filePath) {
  print('File opened: $filePath');
  // Load the story
});

// Share a file
await nativeChannel.shareFile('/path/to/story.webhat');

// Clear cache
await nativeChannel.clearCache();
```

## Building

### Debug Build
```bash
cd mobile/flutter_storypack
flutter build apk --debug
```

### Release Build
```bash
flutter build apk --release
```

### App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### Build for Specific Architecture
```bash
flutter build apk --target-platform android-arm64
```

## Signing Configuration

For release builds, create `android/key.properties`:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=path/to/your/keystore.jks
```

Then update `android/app/build.gradle`:

```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ...
        }
    }
}
```

## Troubleshooting

### Build Fails with "Flutter SDK not found"
```bash
# Create local.properties
echo "flutter.sdk=/path/to/flutter" > android/local.properties
```

### Gradle Sync Issues
```bash
cd android
./gradlew clean
./gradlew build
```

### ProGuard Issues
Add rules to `proguard-rules.pro` if classes are missing in release builds.

### Memory Issues During Build
Increase heap size in `gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx6g -Dfile.encoding=UTF-8
```

## Requirements

- Android SDK 21+ (Android 5.0)
- Kotlin 1.9.22
- Gradle 8.5
- Flutter 3.19.0+

## License

MIT License - See LICENSE file for details.
