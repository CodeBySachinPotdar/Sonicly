import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

class AudioMetadataResult {
  final String title;
  final String artist;
  final String album;
  final String? albumArtist;
  final int durationMs;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String? genre;
  final Uint8List? artworkBytes;
  final String? artworkMime;

  const AudioMetadataResult({
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist,
    required this.durationMs,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre,
    this.artworkBytes,
    this.artworkMime,
  });
}

class AudioMetadataReader {
  /// Reads metadata from an audio file. Never throws an exception.
  /// Falls back gracefully to filename sanitization if tags are missing or corrupt.
  static Future<AudioMetadataResult> readMetadata(File file) async {
    final fileName = p.basenameWithoutExtension(file.path);
    final extension = p.extension(file.path).toLowerCase();

    // Default fallback from filename
    final parsedFromFilename = _parseFromFilename(fileName);
    String title = parsedFromFilename.title;
    String artist = parsedFromFilename.artist;
    String album = 'Unknown Album';
    String? albumArtist;
    int durationMs = 0;
    int? trackNumber = parsedFromFilename.trackNumber;
    int? discNumber;
    int? year;
    String? genre;
    Uint8List? artworkBytes;
    String? artworkMime;

    RandomAccessFile? raf;
    try {
      final length = await file.length();
      if (length < 32) {
        return AudioMetadataResult(
          title: title,
          artist: artist,
          album: album,
          durationMs: 0,
          trackNumber: trackNumber,
        );
      }

      raf = await file.open(mode: FileMode.read);

      if (extension == '.mp3') {
        final res = await _parseMp3(raf, length);
        if (res.title.isNotEmpty) title = res.title;
        if (res.artist.isNotEmpty) artist = res.artist;
        if (res.album.isNotEmpty) album = res.album;
        if (res.albumArtist != null) albumArtist = res.albumArtist;
        if (res.durationMs > 0) durationMs = res.durationMs;
        if (res.trackNumber != null) trackNumber = res.trackNumber;
        if (res.year != null) year = res.year;
        if (res.genre != null) genre = res.genre;
        if (res.artworkBytes != null) {
          artworkBytes = res.artworkBytes;
          artworkMime = res.artworkMime;
        }
      } else if (extension == '.flac') {
        final res = await _parseFlac(raf, length);
        if (res.title.isNotEmpty) title = res.title;
        if (res.artist.isNotEmpty) artist = res.artist;
        if (res.album.isNotEmpty) album = res.album;
        if (res.albumArtist != null) albumArtist = res.albumArtist;
        if (res.durationMs > 0) durationMs = res.durationMs;
        if (res.trackNumber != null) trackNumber = res.trackNumber;
        if (res.year != null) year = res.year;
        if (res.genre != null) genre = res.genre;
        if (res.artworkBytes != null) {
          artworkBytes = res.artworkBytes;
          artworkMime = res.artworkMime;
        }
      } else if (extension == '.m4a' || extension == '.aac' || extension == '.mp4') {
        final res = await _parseMp4(raf, length);
        if (res.title.isNotEmpty) title = res.title;
        if (res.artist.isNotEmpty) artist = res.artist;
        if (res.album.isNotEmpty) album = res.album;
        if (res.albumArtist != null) albumArtist = res.albumArtist;
        if (res.durationMs > 0) durationMs = res.durationMs;
        if (res.trackNumber != null) trackNumber = res.trackNumber;
        if (res.year != null) year = res.year;
        if (res.genre != null) genre = res.genre;
        if (res.artworkBytes != null) {
          artworkBytes = res.artworkBytes;
          artworkMime = res.artworkMime;
        }
      } else if (extension == '.wav' || extension == '.aiff' || extension == '.aif') {
        final res = await _parseWav(raf, length);
        if (res.title.isNotEmpty) title = res.title;
        if (res.artist.isNotEmpty) artist = res.artist;
        if (res.album.isNotEmpty) album = res.album;
        if (res.durationMs > 0) durationMs = res.durationMs;
      } else if (extension == '.ogg' || extension == '.opus') {
        final res = await _parseOgg(raf, length);
        if (res.title.isNotEmpty) title = res.title;
        if (res.artist.isNotEmpty) artist = res.artist;
        if (res.album.isNotEmpty) album = res.album;
        if (res.durationMs > 0) durationMs = res.durationMs;
        if (res.artworkBytes != null) {
          artworkBytes = res.artworkBytes;
          artworkMime = res.artworkMime;
        }
      }
    } catch (_) {
      // Gracefully continue with extracted filename data
    } finally {
      try {
        await raf?.close();
      } catch (_) {}
    }

    return AudioMetadataResult(
      title: title,
      artist: artist,
      album: album,
      albumArtist: albumArtist,
      durationMs: durationMs,
      trackNumber: trackNumber,
      discNumber: discNumber,
      year: year,
      genre: genre,
      artworkBytes: artworkBytes,
      artworkMime: artworkMime,
    );
  }

  // --- MP3 ID3v2 Parsing ---
  static Future<_TagData> _parseMp3(RandomAccessFile raf, int fileLength) async {
    final data = _TagData();
    await raf.setPosition(0);
    final header = await raf.read(10);
    if (header.length < 10) return data;

    // Check ID3v2 header
    if (header[0] == 0x49 && header[1] == 0x44 && header[2] == 0x33) {
      final majorVersion = header[3]; // 3 for ID3v2.3, 4 for ID3v2.4
      final tagSize = _readSyncSafeInt(header, 6);

      if (tagSize > 0 && tagSize < fileLength) {
        final tagBytes = await raf.read(tagSize);
        _parseId3Frames(tagBytes, majorVersion, data);
      }
    }

    // Check ID3v1 if missing
    if (data.title.isEmpty && fileLength > 128) {
      await raf.setPosition(fileLength - 128);
      final id3v1 = await raf.read(128);
      if (id3v1.length == 128 &&
          id3v1[0] == 0x54 &&
          id3v1[1] == 0x41 &&
          id3v1[2] == 0x47) {
        data.title = _decodeAscii(id3v1.sublist(3, 33)).trim();
        data.artist = _decodeAscii(id3v1.sublist(33, 63)).trim();
        data.album = _decodeAscii(id3v1.sublist(63, 93)).trim();
        final yearStr = _decodeAscii(id3v1.sublist(93, 97)).trim();
        data.year = int.tryParse(yearStr);
      }
    }

    return data;
  }

  static void _parseId3Frames(Uint8List bytes, int version, _TagData data) {
    int offset = 0;
    while (offset + 10 <= bytes.length) {
      final frameIdBytes = bytes.sublist(offset, offset + 4);
      if (frameIdBytes[0] == 0) break; // Padding reached

      final frameId = String.fromCharCodes(frameIdBytes);
      int frameSize;
      if (version == 4) {
        frameSize = _readSyncSafeInt(bytes, offset + 4);
      } else {
        frameSize = (bytes[offset + 4] << 24) |
            (bytes[offset + 5] << 16) |
            (bytes[offset + 6] << 8) |
            bytes[offset + 7];
      }

      offset += 10;
      if (frameSize <= 0 || offset + frameSize > bytes.length) break;

      final frameContent = bytes.sublist(offset, offset + frameSize);
      offset += frameSize;

      if (frameId == 'TIT2') {
        data.title = _decodeId3Text(frameContent);
      } else if (frameId == 'TPE1') {
        data.artist = _decodeId3Text(frameContent);
      } else if (frameId == 'TALB') {
        data.album = _decodeId3Text(frameContent);
      } else if (frameId == 'TPE2') {
        data.albumArtist = _decodeId3Text(frameContent);
      } else if (frameId == 'TRCK') {
        final trackStr = _decodeId3Text(frameContent);
        final slashIndex = trackStr.indexOf('/');
        final numStr = slashIndex != -1 ? trackStr.substring(0, slashIndex) : trackStr;
        data.trackNumber = int.tryParse(numStr.trim());
      } else if (frameId == 'TYER' || frameId == 'TDRC') {
        final yearStr = _decodeId3Text(frameContent);
        data.year = int.tryParse(yearStr.length >= 4 ? yearStr.substring(0, 4) : yearStr);
      } else if (frameId == 'TCON') {
        data.genre = _decodeId3Text(frameContent);
      } else if (frameId == 'APIC') {
        _parseApicFrame(frameContent, data);
      }
    }
  }

  static void _parseApicFrame(Uint8List content, _TagData data) {
    if (content.length < 5) return;
    final encoding = content[0];
    int mimeEnd = 1;
    while (mimeEnd < content.length && content[mimeEnd] != 0) {
      mimeEnd++;
    }
    final mimeType = String.fromCharCodes(content.sublist(1, mimeEnd)).toLowerCase();
    int pos = mimeEnd + 1;
    if (pos >= content.length) return;
    pos++; // picture type byte

    // description ends with 0x00 or 0x00 0x00 depending on encoding
    if (encoding == 1 || encoding == 2) {
      while (pos + 1 < content.length) {
        if (content[pos] == 0 && content[pos + 1] == 0) {
          pos += 2;
          break;
        }
        pos += 2;
      }
    } else {
      while (pos < content.length && content[pos] != 0) {
        pos++;
      }
      pos++;
    }

    if (pos < content.length) {
      data.artworkBytes = content.sublist(pos);
      data.artworkMime = mimeType.contains('png') ? 'image/png' : 'image/jpeg';
    }
  }

  // --- FLAC Parsing ---
  static Future<_TagData> _parseFlac(RandomAccessFile raf, int fileLength) async {
    final data = _TagData();
    await raf.setPosition(0);
    final header = await raf.read(4);
    if (header.length < 4 ||
        header[0] != 0x66 ||
        header[1] != 0x4C ||
        header[2] != 0x61 ||
        header[3] != 0x43) {
      return data; // Not 'fLaC'
    }

    bool isLast = false;
    while (!isLast && await raf.position() < fileLength) {
      final blockHeader = await raf.read(4);
      if (blockHeader.length < 4) break;

      isLast = (blockHeader[0] & 0x80) != 0;
      final blockType = blockHeader[0] & 0x7F;
      final blockSize = (blockHeader[1] << 16) | (blockHeader[2] << 8) | blockHeader[3];

      if (blockSize <= 0 || await raf.position() + blockSize > fileLength) break;

      final blockData = await raf.read(blockSize);

      if (blockType == 0) {
        // STREAMINFO
        if (blockData.length >= 18) {
          final sampleRate = ((blockData[10] << 12) |
                  (blockData[11] << 4) |
                  ((blockData[12] & 0xF0) >> 4)) &
              0xFFFFF;
          final totalSamples =
              (((blockData[13] & 0x0F) << 32) |
                  (blockData[14] << 24) |
                  (blockData[15] << 16) |
                  (blockData[16] << 8) |
                  blockData[17]);
          if (sampleRate > 0) {
            data.durationMs = ((totalSamples / sampleRate) * 1000).toInt();
          }
        }
      } else if (blockType == 4) {
        // VORBIS_COMMENT
        _parseVorbisComment(blockData, data);
      } else if (blockType == 6) {
        // PICTURE
        _parseFlacPicture(blockData, data);
      }
    }

    return data;
  }

  static void _parseVorbisComment(Uint8List bytes, _TagData data) {
    if (bytes.length < 8) return;
    int offset = 0;
    final vendorLength = _readUint32LE(bytes, offset);
    offset += 4 + vendorLength;
    if (offset + 4 > bytes.length) return;

    final numComments = _readUint32LE(bytes, offset);
    offset += 4;

    for (int i = 0; i < numComments; i++) {
      if (offset + 4 > bytes.length) break;
      final commentLength = _readUint32LE(bytes, offset);
      offset += 4;
      if (offset + commentLength > bytes.length) break;

      final commentStr = utf8.decode(
        bytes.sublist(offset, offset + commentLength),
        allowMalformed: true,
      );
      offset += commentLength;

      final eqIdx = commentStr.indexOf('=');
      if (eqIdx != -1) {
        final key = commentStr.substring(0, eqIdx).toUpperCase().trim();
        final value = commentStr.substring(eqIdx + 1).trim();

        if (key == 'TITLE') data.title = value;
        if (key == 'ARTIST') data.artist = value;
        if (key == 'ALBUM') data.album = value;
        if (key == 'ALBUMARTIST') data.albumArtist = value;
        if (key == 'TRACKNUMBER') {
          final slashIdx = value.indexOf('/');
          final numStr = slashIdx != -1 ? value.substring(0, slashIdx) : value;
          data.trackNumber = int.tryParse(numStr.trim());
        }
        if (key == 'DATE' || key == 'YEAR') {
          data.year = int.tryParse(value.length >= 4 ? value.substring(0, 4) : value);
        }
        if (key == 'GENRE') data.genre = value;
      }
    }
  }

  static void _parseFlacPicture(Uint8List bytes, _TagData data) {
    if (bytes.length < 32) return;
    int offset = 4; // Skip picture type (32 bit)
    final mimeLen = _readUint32BE(bytes, offset);
    offset += 4;
    if (offset + mimeLen > bytes.length) return;

    final mime = String.fromCharCodes(bytes.sublist(offset, offset + mimeLen));
    offset += mimeLen;

    final descLen = _readUint32BE(bytes, offset);
    offset += 4 + descLen;
    offset += 16; // Skip width, height, depth, colors (4 * 4)

    if (offset + 4 > bytes.length) return;
    final dataLen = _readUint32BE(bytes, offset);
    offset += 4;

    if (offset + dataLen <= bytes.length) {
      data.artworkBytes = bytes.sublist(offset, offset + dataLen);
      data.artworkMime = mime.contains('png') ? 'image/png' : 'image/jpeg';
    }
  }

  // --- MP4 / M4A Parsing ---
  static Future<_TagData> _parseMp4(RandomAccessFile raf, int fileLength) async {
    final data = _TagData();
    await raf.setPosition(0);

    // Simple atom scanner searching for 'moov'
    int offset = 0;
    while (offset + 8 < fileLength) {
      await raf.setPosition(offset);
      final header = await raf.read(8);
      if (header.length < 8) break;

      final size = (header[0] << 24) | (header[1] << 16) | (header[2] << 8) | header[3];
      final type = String.fromCharCodes(header.sublist(4, 8));

      if (size <= 0) break;

      if (type == 'moov') {
        final moovBytes = await raf.read(size - 8);
        _scanMp4Moov(moovBytes, data);
        break;
      }
      offset += size;
    }

    return data;
  }

  static void _scanMp4Moov(Uint8List bytes, _TagData data) {
    // Scan for 'mvhd' to get timescale and duration
    final mvhdIdx = _findPattern(bytes, [0x6D, 0x76, 0x68, 0x64]); // 'mvhd'
    if (mvhdIdx != -1 && mvhdIdx + 24 < bytes.length) {
      final version = bytes[mvhdIdx + 4];
      if (version == 0) {
        final timeScale = _readUint32BE(bytes, mvhdIdx + 16);
        final duration = _readUint32BE(bytes, mvhdIdx + 20);
        if (timeScale > 0) {
          data.durationMs = ((duration / timeScale) * 1000).toInt();
        }
      }
    }

    // Scan for 'ilst'
    final ilstIdx = _findPattern(bytes, [0x69, 0x6C, 0x73, 0x74]); // 'ilst'
    if (ilstIdx != -1) {
      _parseMp4Ilst(bytes.sublist(ilstIdx + 4), data);
    }
  }

  static void _parseMp4Ilst(Uint8List bytes, _TagData data) {
    int offset = 0;
    while (offset + 8 < bytes.length) {
      final size = _readUint32BE(bytes, offset);
      if (size <= 0 || offset + size > bytes.length) break;

      final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
      final chunkData = bytes.sublist(offset + 8, offset + size);
      offset += size;

      final dataIdx = _findPattern(chunkData, [0x64, 0x61, 0x74, 0x61]); // 'data'
      if (dataIdx != -1 && dataIdx + 12 < chunkData.length) {
        final content = chunkData.sublist(dataIdx + 12);
        if (type == '\u00A9nam') {
          data.title = utf8.decode(content, allowMalformed: true).trim();
        } else if (type == '\u00A9ART') {
          data.artist = utf8.decode(content, allowMalformed: true).trim();
        } else if (type == '\u00A9alb') {
          data.album = utf8.decode(content, allowMalformed: true).trim();
        } else if (type == 'aART') {
          data.albumArtist = utf8.decode(content, allowMalformed: true).trim();
        } else if (type == 'covr') {
          data.artworkBytes = content;
          data.artworkMime = 'image/jpeg';
        } else if (type == 'trkn' && content.length >= 4) {
          data.trackNumber = (content[2] << 8) | content[3];
        }
      }
    }
  }

  // --- WAV / RIFF Parsing ---
  static Future<_TagData> _parseWav(RandomAccessFile raf, int fileLength) async {
    final data = _TagData();
    await raf.setPosition(0);
    final header = await raf.read(12);
    if (header.length < 12) return data;

    final riff = String.fromCharCodes(header.sublist(0, 4));
    final wave = String.fromCharCodes(header.sublist(8, 12));
    if (riff != 'RIFF' || (wave != 'WAVE' && wave != 'AIFF')) return data;

    int offset = 12;
    while (offset + 8 < fileLength) {
      await raf.setPosition(offset);
      final chunkHeader = await raf.read(8);
      if (chunkHeader.length < 8) break;

      final chunkId = String.fromCharCodes(chunkHeader.sublist(0, 4));
      final chunkSize = _readUint32LE(chunkHeader, 4);
      offset += 8;

      if (chunkId == 'fmt ' && chunkSize >= 16) {
        final fmtData = await raf.read(16);
        final byteRate = _readUint32LE(fmtData, 8);
        if (byteRate > 0) {
          final dataSize = fileLength - offset;
          data.durationMs = ((dataSize / byteRate) * 1000).toInt();
        }
      }
      offset += chunkSize;
    }

    return data;
  }

  // --- OGG / Vorbis Parsing ---
  static Future<_TagData> _parseOgg(RandomAccessFile raf, int fileLength) async {
    final data = _TagData();
    await raf.setPosition(0);
    final bytes = await raf.read(8192); // Read initial pages
    final commentIdx = _findPattern(bytes, [0x03, 0x76, 0x6F, 0x72, 0x62, 0x69, 0x73]);
    if (commentIdx != -1) {
      _parseVorbisComment(bytes.sublist(commentIdx + 7), data);
    }
    return data;
  }

  // --- Helper Routines ---
  static _FilenameParseResult _parseFromFilename(String filename) {
    // Check patterns like: "01 - Bohemian Rhapsody", "01. Bohemian Rhapsody", "Queen - Bohemian Rhapsody"
    String title = filename;
    String artist = 'Unknown Artist';
    int? trackNumber;

    final trackRegex = RegExp(r'^(\d{1,3})[\s\.\-_]+(.+)$');
    final match = trackRegex.firstMatch(filename);
    if (match != null) {
      trackNumber = int.tryParse(match.group(1)!);
      title = match.group(2)!.trim();
    }

    if (title.contains(' - ')) {
      final parts = title.split(' - ');
      if (parts.length == 2) {
        artist = parts[0].trim();
        title = parts[1].trim();
      }
    }

    return _FilenameParseResult(title: title, artist: artist, trackNumber: trackNumber);
  }

  static int _readSyncSafeInt(List<int> bytes, int offset) {
    return (bytes[offset] & 0x7F) << 21 |
        (bytes[offset + 1] & 0x7F) << 14 |
        (bytes[offset + 2] & 0x7F) << 7 |
        (bytes[offset + 3] & 0x7F);
  }

  static int _readUint32BE(List<int> bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  static int _readUint32LE(List<int> bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  static String _decodeId3Text(Uint8List bytes) {
    if (bytes.isEmpty) return '';
    final encoding = bytes[0];
    final content = bytes.sublist(1);

    try {
      if (encoding == 1 || encoding == 2) {
        // UTF-16
        return String.fromCharCodes(_decodeUtf16(content)).replaceAll('\u0000', '').trim();
      } else if (encoding == 3) {
        // UTF-8
        return utf8.decode(content, allowMalformed: true).replaceAll('\u0000', '').trim();
      } else {
        // ISO-8859-1
        return latin1.decode(content).replaceAll('\u0000', '').trim();
      }
    } catch (_) {
      return '';
    }
  }

  static List<int> _decodeUtf16(Uint8List bytes) {
    final codeUnits = <int>[];
    for (int i = 0; i + 1 < bytes.length; i += 2) {
      final val = bytes[i] | (bytes[i + 1] << 8);
      if (val != 0xFEFF && val != 0xFFFE) {
        codeUnits.add(val);
      }
    }
    return codeUnits;
  }

  static String _decodeAscii(List<int> bytes) {
    return String.fromCharCodes(bytes.where((b) => b >= 32 && b <= 126));
  }

  static int _findPattern(List<int> source, List<int> pattern) {
    if (pattern.isEmpty || source.length < pattern.length) return -1;
    for (int i = 0; i <= source.length - pattern.length; i++) {
      bool match = true;
      for (int j = 0; j < pattern.length; j++) {
        if (source[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }
}

class _TagData {
  String title = '';
  String artist = '';
  String album = '';
  String? albumArtist;
  int durationMs = 0;
  int? trackNumber;
  int? year;
  String? genre;
  Uint8List? artworkBytes;
  String? artworkMime;
}

class _FilenameParseResult {
  final String title;
  final String artist;
  final int? trackNumber;

  _FilenameParseResult({
    required this.title,
    required this.artist,
    this.trackNumber,
  });
}
