# Aria - High-Fidelity Offline Music Player for Android & iOS

Aria is a production-grade, completely **free**, **ad-free**, and **privacy-first** offline music player engineered with Flutter, Dart, `just_audio`, and `audio_service`. It plays local audio files natively with bit-perfect fidelity, comprehensive metadata parsing, and seamless background lock-screen integration.

---

## 🌟 Key Features

- **100% Offline & Private**: Zero accounts, zero tracking, zero telemetry, zero cloud dependencies, and zero advertisements.
- **Universal Codec Support**: Plays MP3, AAC, M4A, FLAC, WAV, OGG, OPUS, and AIFF files up to 24-bit/192kHz.
- **Pure Dart Metadata Engine**: Zero native dependencies for tag parsing. Extracts ID3v1, ID3v2.2-2.4, MP4 atoms, Vorbis comments, and RIFF chunks, including embedded APIC/cover artwork.
- **Background Playback & Lock-screen Controls**: Full integration with Android `MediaSession` & iOS `MPNowPlayingInfoCenter` / `MPRemoteCommandCenter`.
- **Intelligent Audio Focus**:
  - Handles incoming phone calls and alarms (auto-pauses and resumes).
  - Transient ducking during turn-by-turn navigation alerts.
  - "Becoming Noisy" listener: instant auto-pause when headphones or Bluetooth devices disconnect.
- **Queue Management**:
  - Non-destructive shuffling (preserves the original queue order).
  - Repeat modes: None, All, Single Track.
  - Up Next queue with drag-and-drop reordering and swipe-to-dismiss.
  - Persistent playback state across application restarts.
- **Two-Tier Artwork Caching**: In-memory LRU cache backed by atomic filesystem disk cache for instantaneous rendering without lag.
- **Modern Minimalist UI**:
  - Light, Dark, and true AMOLED Pure Black modes.
  - Intuitive library browsing by Songs, Albums, Artists, Playlists, Favorites, and Folder Hierarchy.
  - Interactive mini-player with gesture-based drag to expand into the full Now Playing screen.

---

## 📐 Architecture

Aria strictly follows Clean Architecture principles, ensuring complete decoupling between presentation, business logic, audio engine, and platform abstractions.

```
lib/
├── audio/
│   ├── audio_focus/
│   │   └── audio_focus_manager.dart     # Audio session, interruptions, ducking, becoming-noisy
│   ├── player_service/
│   │   └── audio_player_handler.dart    # Background AudioService & MediaSession bridge
│   └── queue/
│       └── queue_manager.dart           # Non-destructive shuffle, repeat, queue reordering
├── data/
│   ├── cache/
│   │   └── artwork_cache.dart           # In-memory LRU + disk filesystem artwork cache
│   ├── database/
│   │   └── app_database.dart            # SQLite schema, migrations, and indexed queries
│   ├── metadata/
│   │   └── audio_metadata_reader.dart   # Pure Dart ID3v1/v2, MP4, Vorbis, RIFF parser
│   ├── repositories/
│   │   ├── music_repository_impl.dart   # Library queries, search, folder aggregation
│   │   └── playlist_repository_impl.dart# Playlist CRUD & junction table queries
│   └── scanner/
│       └── file_scanner.dart            # Recursive storage crawler & dead-file purger
├── domain/
│   ├── album.dart                       # Album aggregate model
│   ├── artist.dart                      # Artist aggregate model
│   ├── playback.dart                    # Playback state, shuffle & repeat enums
│   ├── playlist.dart                    # Custom user playlist model
│   ├── song.dart                        # Core audio track entity with duration formatting
│   └── repositories/
│       ├── music_repository.dart        # Music catalog contract
│       └── playlist_repository.dart     # Playlist management contract
├── presentation/
│   ├── albums/                          # Albums grid & album detail screens
│   ├── artists/                         # Artists list & artist track list screens
│   ├── favorites/                       # Favorited tracks screen
│   ├── folders/                         # Direct directory file tree navigator
│   ├── home/                            # Home screen with quick-access library pills
│   ├── now_playing/                     # Fullscreen player with scrubber, queue & controls
│   ├── playlists/                       # Playlists overview & playlist detail screens
│   ├── settings/                        # Theme toggle (Light/Dark/AMOLED), rescan & about
│   ├── songs/                           # Sortable all-songs list with fast search
│   ├── theme/
│   │   └── app_theme.dart               # Light, Dark, and AMOLED Material 3 themes
│   ├── view_models/
│   │   ├── library_view_model.dart      # Catalog state, sorting, search, scanning status
│   │   ├── player_view_model.dart       # Current track, position, shuffle/repeat triggers
│   │   ├── playlists_view_model.dart    # Playlist creation, addition, deletion
│   │   └── settings_view_model.dart     # Theme mode, directory configuration
│   ├── widgets/
│   │   ├── artwork_widget.dart          # Image renderer with disk fallback & placeholders
│   │   ├── empty_state.dart             # Descriptive empty placeholders
│   │   ├── mini_player.dart             # Persistent floating bottom player bar
│   │   ├── song_options_bottom_sheet.dart # Quick actions: add to playlist, favorite, info
│   │   └── song_tile.dart               # High-performance list item widget
│   └── main_navigation_shell.dart       # Bottom navigation container with mini-player
└── main.dart                            # Dependency injection & application entry point
```

---

## 🎵 Audio Engineering & Codec Matrix

| Format | Extension | Container / Tag Standard | Decoding Engine | Max Tested Bit Depth / Sample Rate |
| :--- | :--- | :--- | :--- | :--- |
| **MP3** | `.mp3` | MPEG-1/2 Audio Layer III (ID3v1, ID3v2.2-2.4) | Native Platform / ExoPlayer / AVPlayer | 320 kbps / 48 kHz CBR/VBR |
| **AAC** | `.aac`, `.m4a` | MPEG-4 Part 14 / ADTS (`moov.udta.meta.ilst`) | Native Platform / ExoPlayer / AVPlayer | 320 kbps / 48 kHz |
| **FLAC** | `.flac` | Free Lossless Audio Codec (`VORBIS_COMMENT`) | Native Platform / ExoPlayer / AVPlayer | **24-bit / 192 kHz Lossless** |
| **ALAC** | `.m4a` | Apple Lossless Audio Codec (MP4 atom) | Native Platform / ExoPlayer / AVPlayer | **24-bit / 96 kHz Lossless** |
| **WAV** | `.wav` | Resource Interchange File Format (RIFF `INFO`) | Native Platform / ExoPlayer / AVPlayer | **32-bit float / 192 kHz PCM** |
| **AIFF** | `.aiff`, `.aif` | Audio Interchange File Format (RIFF/FORM `ID3 `) | Native Platform / ExoPlayer / AVPlayer | **24-bit / 96 kHz PCM** |
| **OGG** | `.ogg` | Ogg Vorbis Bitstream (`VORBIS_COMMENT`) | Native Platform / ExoPlayer / AVPlayer | 500 kbps / 48 kHz |
| **OPUS** | `.opus` | Ogg Opus Bitstream (`OpusTags`) | Native Platform / ExoPlayer / AVPlayer | 510 kbps / 48 kHz |

---

## 🔄 Lifecycle, MediaSession & Audio Focus

Aria integrates directly with OS-level audio subsystems via `audio_service` and `audio_session`:

1. **Android MediaSession**:
   - Registered as a Foreground Service with type `mediaPlayback`.
   - Emits `PlaybackStateCompat` tokens containing seek capabilities, skip next/previous, and play/pause flags.
   - Updates lock-screen metadata and lock-screen cover art dynamically.
2. **iOS Remote Command Center**:
   - Configured with `AVAudioSessionCategoryPlayback`.
   - Hooks into `MPRemoteCommandCenter` for remote hardware buttons, Apple Watch, and Control Center control.
   - Syncs elapsed playback position, duration, and title to `MPNowPlayingInfoCenter`.
3. **Audio Focus Handling**:
   - **Call Interruptions**: Automatically pauses playback upon incoming ring/call and resumes seamlessly when the call terminates.
   - **Navigation & Notifications**: Automatically ducks volume temporarily when higher-priority navigation instructions sound.
   - **Becoming Noisy**: Listens to hardware broadcast receivers. If physical wired headphones or Bluetooth headsets disconnect, playback is immediately paused to prevent blasting audio publicly.

---

## 🗄️ Database & Storage Architecture

Aria uses SQLite through `sqflite` with B-Tree indexes optimized for instant lookups even with libraries exceeding 50,000 songs.

### Database Tables:
- `songs`: Cached song metadata (URI, title, artist, album, duration, track number, year, genre, play count, last played timestamp).
- `playlists`: User-defined playlist entities.
- `playlist_songs`: Join table supporting custom track ordering within playlists.
- `favorites`: Fast set-lookup index of favorited song IDs.
- `playback_state`: Saves the last playing song, playback position, repeat mode, and shuffle state for seamless session restoration upon application relaunch.

### Indexes:
- `idx_songs_title` on `songs(title)`
- `idx_songs_artist` on `songs(artist)`
- `idx_songs_album` on `songs(album)`
- `idx_songs_date_added` on `songs(date_added)`
- `idx_songs_play_count` on `songs(play_count)`

---

## 🔒 Privacy & Permissions

Aria enforces a strict **Zero-Data-Collection** policy. No network requests are ever dispatched.

### Android Permissions
- `READ_MEDIA_AUDIO` (Android 13+): Reads local audio files from storage.
- `READ_EXTERNAL_STORAGE` (Android 12 and below): Legacy storage read access.
- `FOREGROUND_SERVICE` & `FOREGROUND_SERVICE_MEDIA_PLAYBACK`: Keeps playback active without the OS terminating the background task.
- `WAKE_LOCK`: Keeps audio processors running while screen is locked.
- `POST_NOTIFICATIONS` (Android 13+): Displays playback notification controls.

### iOS Configuration
- `UIBackgroundModes` -> `audio`: Enables background playback.
- `UIFileSharingEnabled` & `LSSupportsOpeningDocumentsInPlace`: Allows users to transfer music into the app directly via the macOS Finder / Windows iTunes / iOS Files app.

---

## 🛠️ Build & Installation Guide

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.24.0 or higher recommended)
- [Dart SDK](https://dart.dev/get-dart) (3.5.0 or higher)
- Android Studio / Android SDK (API 34+)
- Xcode 15+ (for iOS builds)
- CocoaPods (`sudo gem install cocoapods`)

> 📖 **Looking for a detailed step-by-step local running guide?**  
> Check out the [Local Development & Running Guide](file:///d:/Music%20Player/RUNNING_LOCALLY.md) for full instructions on running on Android Emulators, physical Android phones, iOS Simulators, physical iPhones, pushing sample audio files with `adb`, hot-reload tips, and troubleshooting.

### Quick Start (Local Run)
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Check available devices/emulators
flutter devices

# 3. Run the app in debug mode
flutter run
```

### Running Automated Tests
```bash
flutter test
```

### Static Analysis
```bash
flutter analyze
```

### Building for Android

#### 1. Generate Release APK (Universal or Per-ABI)
```bash
# Universal Release APK
flutter build apk --release

# Split ABI APKs (Smaller file size for armeabi-v7a, arm64-v8a, x86_64)
flutter build apk --release --split-per-abi
```
Output location: `build/app/outputs/flutter-apk/app-release.apk`

#### 2. Generate Release Android App Bundle (AAB) for Google Play
```bash
flutter build appbundle --release
```
Output location: `build/app/outputs/bundle/release/app-release.aab`

---

### Building for iOS

#### 1. Prepare Pods
```bash
cd ios
pod install
cd ..
```

#### 2. Build iOS Archive
```bash
flutter build ipa --release
```
Output location: `build/ios/archive/Runner.xcarchive`

#### 3. Export IPA via Xcode Organizer or Fastlane
Open `ios/Runner.xcworkspace` in Xcode, select **Product > Archive**, and distribute using your chosen Apple Developer provisioning profile (Ad-Hoc, TestFlight, or App Store).

---

## 🧪 Testing Coverage

The codebase includes a comprehensive suite of automated tests verifying models, queue mechanics, metadata parsing, and widget rendering:
- `test/models_test.dart`: Serialization, duration formatting, and entity aggregates.
- `test/queue_manager_test.dart`: Shuffling integrity, unshuffle restoration, repeat cycles (`off`, `all`, `one`), and track reordering.
- `test/metadata_reader_test.dart`: ID3/Vorbis parsing, filename heuristics fallback, and corrupted file handling.
- `test/widget_test.dart`: UI widget rendering, empty state buttons, fallback artwork, and theme consistency.

---

## 📄 License

This project is licensed under the MIT License — free for personal and commercial usage with zero strings attached.
