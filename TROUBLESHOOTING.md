# WebHat StoryPack Troubleshooting Guide

## GitHub Actions Issues

### Problem: Workflows Stuck in "Queued" State

**Symptoms:**
- All workflow runs show "Queued" status
- No builds are executing
- No error messages visible

**Causes & Solutions:**

#### 1. GitHub Actions Not Enabled
```bash
# Check repository settings
# Go to: Settings > Actions > General
# Ensure "Allow all actions and reusable workflows" is selected
```

#### 2. Missing `package-lock.json` Files
The workflow references `package-lock.json` but these files don't exist in the repository.

**Fix:**
```bash
# For reader
cd reader
npm install
# Commit package-lock.json

# For editor
cd editor
npm install
# Commit package-lock.json
```

#### 3. Workflow File Issues
The current workflow has several issues:

**Missing `working-directory` in some steps:**
```yaml
# Current (problematic):
- name: Download reader artifact
  uses: actions/download-artifact@v4
  with:
    name: web-reader
    path: ./_site/reader  # This is correct

# But the build steps need proper paths
```

**Flutter version mismatch:**
```yaml
# Current: FLUTTER_VERSION: '3.16.0'
# Recommended: Use latest stable
FLUTTER_VERSION: '3.19.0'
```

### Fixed Workflow Configuration

See `.github/workflows/build-fixed.yml` for a corrected workflow.

---

## Flutter Android Build Issues

### Problem: Android Build Fails

**Common Errors:**
```
* What went wrong:
Could not determine the dependencies of task ':app:compileDebugJavaWithJavac'.
> Could not resolve all dependencies for configuration ':app:debugCompileClasspath'.
```

**Solutions:**

#### 1. Update `android/build.gradle`
```gradle
buildscript {
    ext.kotlin_version = '1.9.22'  // Update to latest
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.1'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

#### 2. Update `android/gradle/wrapper/gradle-wrapper.properties`
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.5-all.zip
```

#### 3. Update `android/app/build.gradle`
```gradle
android {
    namespace "com.webhat.storypack"
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.webhat.storypack"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = '17'
    }
}
```

---

## Python Engine Issues

### Problem: Import Errors

```python
# Error: ModuleNotFoundError: No module named 'webhat_engine'
```

**Solution:**
```bash
cd engine
pip install -e .
# Or for development:
pip install -e ".[dev]"
```

### Problem: Pygame Audio Not Working

```python
# Error: pygame.error: No available audio device
```

**Solutions:**

**Linux:**
```bash
sudo apt-get install libsdl2-mixer-2.0-0
```

**macOS:**
```bash
brew install sdl2_mixer
```

**Windows:**
- Install DirectX redistributables

---

## Web Reader/Editor Issues

### Problem: Vite Build Fails

```
Error: Cannot find module 'jszip'
```

**Solution:**
```bash
cd reader  # or editor
npm install
npm run build
```

### Problem: TypeScript Errors

```
error TS2307: Cannot find module './types'
```

**Solution:**
Ensure all type definition files exist:
```bash
# Check src/types/index.ts exists
ls -la src/types/
```

---

## iOS Build Issues

### Problem: Code Signing Required

```
error: No profiles for 'com.webhat.storypack' were found
```

**Solution:**
1. Set up Apple Developer account
2. Create provisioning profiles
3. Update `ios/Runner.xcodeproj/project.pbxproj`

---

## Performance Issues

### Large .webhat Files

**Problem:** Stories with many images load slowly

**Solutions:**
1. Compress images before adding:
```bash
# Use WebP format
convert image.png image.webp

# Or optimize PNG
optipng -o7 image.png
```

2. Implement lazy loading in reader

3. Add image caching

---

## Debugging Tips

### Enable Debug Mode

**Flutter:**
```dart
// In main.dart
void main() {
  debugPrintRebuildDirtyWidgets = true;
  runApp(MyApp());
}
```

**Python:**
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

**Web:**
```javascript
// In browser console
localStorage.setItem('webhat_debug', 'true')
```

### Check Logs

**GitHub Actions:**
```bash
# Download logs from Actions tab
# Or use GitHub CLI:
gh run view --log
```

**Flutter:**
```bash
flutter run --verbose
```

---

## Getting Help

1. Check existing [Issues](https://github.com/droy-go/webhat/issues)
2. Create a new issue with:
   - Error messages
   - Steps to reproduce
   - Environment details (OS, versions)
3. Join community discussions
