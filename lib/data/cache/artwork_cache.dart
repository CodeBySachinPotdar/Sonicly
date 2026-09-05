import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ArtworkCache {
  static final ArtworkCache instance = ArtworkCache._internal();
  ArtworkCache._internal();

  Directory? _cacheDir;
  final Map<String, Uint8List?> _memoryCache = {};
  static const int maxMemoryEntries = 150;

  Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final baseDir = await getApplicationSupportDirectory();
    final artDir = Directory(p.join(baseDir.path, 'artworks'));
    if (!await artDir.exists()) {
      await artDir.create(recursive: true);
    }
    _cacheDir = artDir;
    return _cacheDir!;
  }

  /// Saves extracted image bytes to disk and returns the local file path.
  Future<String?> saveArtwork(String identifier, Uint8List bytes, {String extension = 'jpg'}) async {
    try {
      final hash = md5.convert(bytes).toString();
      final dir = await _getCacheDirectory();
      final filePath = p.join(dir.path, '$hash.$extension');
      final file = File(filePath);

      if (!await file.exists()) {
        await file.writeAsBytes(bytes, flush: true);
      }

      _memoryCache[identifier] = bytes;
      _trimMemoryCache();
      return filePath;
    } catch (_) {
      return null;
    }
  }

  /// Retrieves artwork bytes from memory or disk cache.
  Future<Uint8List?> getArtworkBytes(String? artworkPath, {String? identifier}) async {
    if (artworkPath == null || artworkPath.isEmpty) return null;

    if (identifier != null && _memoryCache.containsKey(identifier)) {
      return _memoryCache[identifier];
    }

    try {
      final file = File(artworkPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (identifier != null) {
          _memoryCache[identifier] = bytes;
          _trimMemoryCache();
        }
        return bytes;
      }
    } catch (_) {}

    return null;
  }

  void _trimMemoryCache() {
    if (_memoryCache.length > maxMemoryEntries) {
      final keysToRemove = _memoryCache.keys.take(_memoryCache.length - maxMemoryEntries).toList();
      for (final key in keysToRemove) {
        _memoryCache.remove(key);
      }
    }
  }

  void clearMemoryCache() {
    _memoryCache.clear();
  }
}
