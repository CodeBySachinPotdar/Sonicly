import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/album.dart';
import '../../domain/artist.dart';
import '../../domain/playback.dart';
import '../../domain/repositories/music_repository.dart';
import '../../domain/song.dart';

class LibraryViewModel extends ChangeNotifier {
  final MusicRepository _musicRepository;

  List<Song> _songs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<String> _folders = [];
  List<Song> _favorites = [];
  List<Song> _recentlyPlayed = [];
  List<Song> _mostPlayed = [];
  List<Song> _recentlyAdded = [];

  bool _isLoading = false;
  bool _isScanning = false;
  int _scannedCount = 0;
  String _currentScanFile = '';
  String _searchQuery = '';
  SortField _sortField = SortField.title;
  SortOrder _sortOrder = SortOrder.ascending;

  LibraryViewModel({required this._musicRepository});

  List<Song> get songs => _songs;
  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;
  List<String> get folders => _folders;
  List<Song> get favorites => _favorites;
  List<Song> get recentlyPlayed => _recentlyPlayed;
  List<Song> get mostPlayed => _mostPlayed;
  List<Song> get recentlyAdded => _recentlyAdded;

  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  int get scannedCount => _scannedCount;
  String get currentScanFile => _currentScanFile;
  String get searchQuery => _searchQuery;
  SortField get sortField => _sortField;
  SortOrder get sortOrder => _sortOrder;

  Future<void> loadLibrary() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_searchQuery.isNotEmpty) {
        _songs = await _musicRepository.searchSongs(_searchQuery);
      } else {
        _songs = await _musicRepository.getAllSongs(
          sortField: _sortField,
          sortOrder: _sortOrder,
        );
      }

      _albums = await _musicRepository.getAlbums();
      _artists = await _musicRepository.getArtists();
      _folders = await _musicRepository.getFolders();
      _favorites = await _musicRepository.getFavorites();
      _recentlyPlayed = await _musicRepository.getRecentlyPlayed(limit: 20);
      _mostPlayed = await _musicRepository.getMostPlayed(limit: 20);
      _recentlyAdded = await _musicRepository.getRecentlyAdded(limit: 20);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _songs = await _musicRepository.getAllSongs(
        sortField: _sortField,
        sortOrder: _sortOrder,
      );
    } else {
      _songs = await _musicRepository.searchSongs(query);
    }
    notifyListeners();
  }

  Future<void> setSort(SortField field, SortOrder order) async {
    _sortField = field;
    _sortOrder = order;
    _songs = await _musicRepository.getAllSongs(
      sortField: _sortField,
      sortOrder: _sortOrder,
    );
    notifyListeners();
  }

  Future<void> toggleFavorite(Song song) async {
    final isFav = await _musicRepository.toggleFavorite(song.id);
    _favorites = await _musicRepository.getFavorites();

    void updateInList(List<Song> list) {
      final idx = list.indexWhere((s) => s.id == song.id);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(isFavorite: isFav);
      }
    }

    updateInList(_songs);
    updateInList(_recentlyPlayed);
    updateInList(_mostPlayed);
    updateInList(_recentlyAdded);

    notifyListeners();
  }

  /// Scans device storage specifically for newly or recently added audio files.
  Future<dynamic> scanRecentlyAddedSongs({
    Duration recentWindow = const Duration(days: 7),
  }) async {
    if (_isScanning) return null;
    _isScanning = true;
    _scannedCount = 0;
    _currentScanFile = '';
    notifyListeners();

    try {
      if (Platform.isAndroid) {
        var status = await Permission.audio.status;
        if (!status.isGranted) {
          status = await Permission.audio.request();
        }
        if (!status.isGranted) {
          var storageStatus = await Permission.storage.status;
          if (!storageStatus.isGranted) {
            await Permission.storage.request();
          }
        }
      }

      final result = await _musicRepository.scanRecentlyAdded(
        recentWindow: recentWindow,
        onProgress: (count, file) {
          _scannedCount = count;
          _currentScanFile = file;
          notifyListeners();
        },
      );

      await loadLibrary();
      return result;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> requestPermissionsAndScan() async {
    if (Platform.isAndroid) {
      // Check Android 13+ (audio) or legacy (storage)
      var status = await Permission.audio.status;
      if (!status.isGranted) {
        status = await Permission.audio.request();
      }
      if (!status.isGranted) {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          await Permission.storage.request();
        }
      }
    }

    await rescanLibrary();
  }

  Future<void> rescanLibrary() async {
    if (_isScanning) return;
    _isScanning = true;
    _scannedCount = 0;
    _currentScanFile = '';
    notifyListeners();

    try {
      final List<String> pathsToScan = [];

      if (Platform.isAndroid) {
        // Standard Android music directories
        pathsToScan.addAll([
          '/storage/emulated/0/Music',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Audio',
          '/storage/emulated/0/Recordings',
        ]);
      } else if (Platform.isIOS) {
        // App Documents directory (for iTunes File Sharing & Files app)
        final docsDir = await getApplicationDocumentsDirectory();
        pathsToScan.add(docsDir.path);
      } else {
        // Desktop / testing fallback
        final docsDir = await getApplicationDocumentsDirectory();
        pathsToScan.add(docsDir.path);
      }

      for (final path in pathsToScan) {
        final dir = Directory(path);
        if (await dir.exists()) {
          await _musicRepository.scanDirectory(
            path,
            onProgress: (count, file) {
              _scannedCount = count;
              _currentScanFile = file;
              notifyListeners();
            },
          );
        }
      }

      await loadLibrary();
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> scanCustomDirectory(String path) async {
    _isScanning = true;
    _scannedCount = 0;
    notifyListeners();

    try {
      await _musicRepository.scanDirectory(
        path,
        onProgress: (count, file) {
          _scannedCount = count;
          _currentScanFile = file;
          notifyListeners();
        },
      );
      await loadLibrary();
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<List<Song>> getAlbumSongs(String albumName, String artistName) async {
    return await _musicRepository.getAlbumSongs(albumName, artistName);
  }

  Future<List<Song>> getArtistSongs(String artistName) async {
    return await _musicRepository.getArtistSongs(artistName);
  }

  Future<List<Song>> getSongsInFolder(String folderPath) async {
    return await _musicRepository.getSongsInFolder(folderPath);
  }

  Future<void> clearHistory() async {
    await _musicRepository.clearHistory();
    _recentlyPlayed = [];
    _mostPlayed = [];
    notifyListeners();
  }
}
