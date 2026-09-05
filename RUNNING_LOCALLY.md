# How to Run Aria Locally (Development & Testing Guide)

This guide provides step-by-step instructions for running the **Aria Offline Music Player** on your local workstation using Android emulators, physical Android devices, iOS simulators, or physical iPhones.

---

## 📋 Table of Contents

1. [Prerequisites & Environment Setup](#1-prerequisites--environment-setup)
2. [Quick Start (Fast Track)](#2-quick-start-fast-track)
3. [Running on Android](#3-running-on-android)
   - [Option A: Android Virtual Device (Emulator)](#option-a-android-virtual-device-emulator)
   - [Option B: Physical Android Device](#option-b-physical-android-device)
   - [Adding Sample Music to Android](#adding-sample-music-to-android)
4. [Running on iOS (macOS required)](#4-running-on-ios-macos-required)
   - [Option A: iOS Simulator](#option-a-ios-simulator)
   - [Option B: Physical iPhone / iPad](#option-b-physical-iphone--ipad)
   - [Adding Sample Music to iOS](#adding-sample-music-to-ios)
5. [Development Controls & Shortcuts](#5-development-controls--shortcuts)
6. [Run Configurations & Build Flavors](#6-run-configurations--build-flavors)
7. [Running Tests & Code Quality Checks](#7-running-tests--code-quality-checks)
8. [Troubleshooting & FAQ](#8-troubleshooting--faq)

---

## 1. Prerequisites & Environment Setup

Before starting, ensure your system has the required tooling installed:

| Tool | Minimum Version | Check Command | Installation Link |
| :--- | :--- | :--- | :--- |
| **Flutter SDK** | `3.24.0+` | `flutter --version` | [flutter.dev/install](https://docs.flutter.dev/get-started/install) |
| **Dart SDK** | `3.5.0+` (bundled with Flutter) | `dart --version` | Bundled with Flutter |
| **Android Studio** | Hedgehog (2023.1.1+) | Check Android Studio GUI | [developer.android.com/studio](https://developer.android.com/studio) |
| **Android SDK / NDK** | API 34+ | In Android Studio SDK Manager | Included in Android Studio |
| **Xcode** *(macOS only)* | `15.0+` | `xcodebuild -version` | Mac App Store |
| **CocoaPods** *(macOS only)* | `1.14+` | `pod --version` | `sudo gem install cocoapods` |

### Verify Your Setup
Run the Flutter diagnostic check:
```bash
flutter doctor -v
```
Ensure that **Flutter**, **Android toolchain**, and (if on macOS) **Xcode** have green checkmarks.
If prompted to accept Android licenses, run:
```bash
flutter doctor --android-licenses
```

---

## 2. Quick Start (Fast Track)

1. **Open terminal in the project directory**:
   ```bash
   cd "d:\Music Player"
   ```

2. **Fetch dependencies**:
   ```bash
   flutter pub get
   ```

3. **Check available devices/emulators**:
   ```bash
   flutter devices
   ```

4. **Launch the application**:
   ```bash
   flutter run
   ```
   *(If multiple devices are detected, specify target using `-d <device_id>`)*

---

## 3. Running on Android

### Option A: Android Virtual Device (Emulator)

1. **List installed emulators**:
   ```bash
   flutter emulators
   ```

2. **Start your emulator**:
   ```bash
   flutter emulators --launch <emulator_id>
   ```
   *(Or launch it from Android Studio > Virtual Device Manager)*

3. **Run the app**:
   ```bash
   flutter run -d <emulator_id>
   ```

### Option B: Physical Android Device

1. **Enable Developer Options on your phone**:
   - Go to **Settings > About phone**.
   - Tap **Build Number** 7 times until you see *"You are now a developer!"*.
2. **Enable USB Debugging**:
   - Go to **Settings > System > Developer options** (or **Settings > Developer options**).
   - Toggle **USB debugging** ON.
3. **Connect phone via USB cable**:
   - On phone popup: Check *"Always allow from this computer"* and tap **Allow**.
4. **Verify device detection**:
   ```bash
   flutter devices
   ```
   *(Your phone model should appear in the list)*
5. **Run the app**:
   ```bash
   flutter run -d <your_device_id>
   ```

---

### Adding Sample Music to Android

Because Aria is an offline player, it needs audio files to populate the library.

#### On an Emulator:
You can push `.mp3`, `.flac`, `.m4a`, `.wav`, `.ogg` files directly from your computer using `adb`:

```bash
# Push an individual song
adb push "C:\Users\YourName\Music\song.mp3" /sdcard/Music/

# Or push an entire directory of music
adb push "C:\Users\YourName\Music\Albums" /sdcard/Music/
```

Alternatively, simply **drag and drop** audio files from your Windows/macOS file explorer directly onto the running Android Emulator window. The emulator will save them to the `Downloads` folder.

#### On a Physical Device:
Connect the phone in **File Transfer (MTP)** mode and drag music files into the `Music` or `Audiobooks` folder.

#### Trigger Library Scan:
1. Open **Aria**.
2. When prompted, grant **Audio / Storage** permission.
3. If files don't appear automatically, go to **Settings** (gear icon in top right) and tap **Rescan Storage**.
4. Or go to the **Folders** tab and select the specific directory where your audio files reside.

---

## 4. Running on iOS (macOS required)

### Option A: iOS Simulator

1. **Install CocoaPods dependencies**:
   ```bash
   cd ios
   pod install
   cd ..
   ```

2. **Open iOS Simulator**:
   ```bash
   open -a Simulator
   ```

3. **Launch the app**:
   ```bash
   flutter run -d iPhone
   ```

### Option B: Physical iPhone / iPad

1. **Connect your iPhone via USB / Lightning / USB-C**.
2. **Configure Xcode Signing**:
   - Open `ios/Runner.xcworkspace` in Xcode:
     ```bash
     open ios/Runner.xcworkspace
     ```
   - Select the `Runner` root target in the left project navigator.
   - Go to the **Signing & Capabilities** tab.
   - Under **Team**, select your Apple ID (Personal Team).
   - Under **Bundle Identifier**, if needed, prefix with a unique identifier (e.g., `com.yourname.musicplayer`).
3. **Trust Developer on iPhone**:
   - When the build finishes deploying, go to **Settings > General > VPN & Device Management** on your iPhone.
   - Select your Apple ID and tap **Trust**.
4. **Run from terminal**:
   ```bash
   flutter run -d <device_id>
   ```

---

### Adding Sample Music to iOS

Aria enables `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` in `Info.plist`:

#### In iOS Simulator:
1. Open the built-in **Files** app on the Simulator.
2. Drag and drop audio files from macOS Finder onto the Simulator window.
3. Save them to **On My iPhone > Aria** (or inside Downloads).
4. Launch Aria and navigate to the **Folders** tab or tap **Rescan Library**.

#### On Physical iPhone:
1. Connect iPhone to Mac (via Finder) or Windows (via iTunes or Apple Devices app).
2. Select your device and click **Files** tab.
3. Select **Aria** and drag audio files into the documents area.
4. You can also AirDrop audio files to your iPhone and save them to the **Files** app.

---

## 5. Development Controls & Shortcuts

When `flutter run` is active in your terminal, use these interactive hotkeys:

| Key | Action |
| :--- | :--- |
| `r` | **Hot Reload**: Instantly updates UI code without resetting player state. |
| `R` | **Hot Restart**: Restarts the Flutter app state while keeping process alive. |
| `p` | **Debug Paint**: Shows widget layout boundaries and constraints. |
| `v` | **Flutter DevTools**: Opens web-based profiler, widget tree inspector, and CPU timeline. |
| `o` | **Toggle Platform**: Simulates switching between Android and iOS design behavior. |
| `b` | **Toggle Brightness**: Quickly preview Light mode vs. Dark mode. |
| `q` | **Quit**: Safely terminates the running application process. |

---

## 6. Run Configurations & Build Flavors

### Debug Mode (Default)
Optimized for developer speed, hot reload, and detailed assertions:
```bash
flutter run
```

### Profile Mode
Runs near-release performance with debugging hooks enabled (useful for analyzing audio thread latency and 120Hz scrolling smoothness):
```bash
flutter run --profile
```

### Release Mode
Full ahead-of-time (AOT) compilation with all debugging overhead stripped:
```bash
flutter run --release
```

---

## 7. Running Tests & Code Quality Checks

### Run All Automated Unit & Widget Tests
```bash
flutter test
```

### Run a Specific Test Suite
```bash
# Domain models test
flutter test test/models_test.dart

# Audio queue & shuffle test
flutter test test/queue_manager_test.dart

# Pure Dart audio metadata parser test
flutter test test/metadata_reader_test.dart

# UI widget rendering test
flutter test test/widget_test.dart
```

### Run Static Analysis (Linter)
```bash
flutter analyze
```
*(All checks must return: `No issues found!`)*

---

## 8. Troubleshooting & FAQ

### Q: The app opens, but no songs appear in the library.
- **Cause 1: Permission not granted**. On Android 13+, ensure `READ_MEDIA_AUDIO` is allowed. Go to Android Settings > Apps > Aria > Permissions > Music and Audio > Allow.
- **Cause 2: No audio files exist**. Virtual emulators have zero media files by default. Follow [Adding Sample Music to Android](#adding-sample-music-to-android).
- **Cause 3: Cache out of date**. Tap the **Settings** gear icon in the top right and tap **Rescan Storage**.

### Q: `flutter pub get` or build fails with Gradle or CocoaPods errors.
- Clean the build cache and reinstall pods:
  ```bash
  flutter clean
  flutter pub get
  ```
- For iOS:
  ```bash
  cd ios
  pod deintegrate
  pod install
  cd ..
  ```

### Q: Audio pauses when the screen locks on Android.
- Check OEM battery optimization. On Samsung (OneUI) or Xiaomi (MIUI), battery savers aggressively kill background tasks. In Android Settings > Apps > Aria > Battery, select **Unrestricted**.

### Q: How do I test the Lock-screen and Notification controls?
- Start playing any audio track in Aria.
- Press the Home button or switch to another app.
- Pull down the Android notification shade or access the iOS Control Center / Lock-screen. You will see the track title, artist name, cover art, scrubber, and playback buttons.

### Q: How do I test the "Becoming Noisy" auto-pause?
- While playing music through wired headphones or Bluetooth earbuds, physically unplug the headphones or turn off Bluetooth. Aria will immediately pause audio to prevent public speaker output.
