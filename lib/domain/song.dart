class Song {
  final String id;
  final String path;
  final String title;
  final String artist;
  final String album;
  final String? albumArtist;
  final int durationMs;
  final int size;
  final int dateAdded;
  final int dateModified;
  final String format;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String? genre;
  final String? artworkPath;
  final bool hasArtwork;
  final int playCount;
  final int? lastPlayedAt;
  final bool isFavorite;

  const Song({
    required this.id,
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist,
    required this.durationMs,
    required this.size,
    required this.dateAdded,
    required this.dateModified,
    required this.format,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre,
    this.artworkPath,
    this.hasArtwork = false,
    this.playCount = 0,
    this.lastPlayedAt,
    this.isFavorite = false,
  });

  Duration get duration => Duration(milliseconds: durationMs);

  String get durationFormatted {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Song copyWith({
    String? id,
    String? path,
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    int? durationMs,
    int? size,
    int? dateAdded,
    int? dateModified,
    String? format,
    int? trackNumber,
    int? discNumber,
    int? year,
    String? genre,
    String? artworkPath,
    bool? hasArtwork,
    int? playCount,
    int? lastPlayedAt,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      path: path ?? this.path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      durationMs: durationMs ?? this.durationMs,
      size: size ?? this.size,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      format: format ?? this.format,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      artworkPath: artworkPath ?? this.artworkPath,
      hasArtwork: hasArtwork ?? this.hasArtwork,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'title': title,
      'artist': artist,
      'album': album,
      'album_artist': albumArtist,
      'duration_ms': durationMs,
      'size': size,
      'date_added': dateAdded,
      'date_modified': dateModified,
      'format': format,
      'track_number': trackNumber,
      'disc_number': discNumber,
      'year': year,
      'genre': genre,
      'artwork_path': artworkPath,
      'has_artwork': hasArtwork ? 1 : 0,
      'play_count': playCount,
      'last_played_at': lastPlayedAt,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map, {bool isFavorite = false}) {
    return Song(
      id: map['id'] as String,
      path: map['path'] as String,
      title: (map['title'] as String?)?.isNotEmpty == true
          ? map['title'] as String
          : 'Unknown Title',
      artist: (map['artist'] as String?)?.isNotEmpty == true
          ? map['artist'] as String
          : 'Unknown Artist',
      album: (map['album'] as String?)?.isNotEmpty == true
          ? map['album'] as String
          : 'Unknown Album',
      albumArtist: map['album_artist'] as String?,
      durationMs: (map['duration_ms'] as num?)?.toInt() ?? 0,
      size: (map['size'] as num?)?.toInt() ?? 0,
      dateAdded: (map['date_added'] as num?)?.toInt() ?? 0,
      dateModified: (map['date_modified'] as num?)?.toInt() ?? 0,
      format: (map['format'] as String?) ?? 'mp3',
      trackNumber: (map['track_number'] as num?)?.toInt(),
      discNumber: (map['disc_number'] as num?)?.toInt(),
      year: (map['year'] as num?)?.toInt(),
      genre: map['genre'] as String?,
      artworkPath: map['artwork_path'] as String?,
      hasArtwork: (map['has_artwork'] as int?) == 1,
      playCount: (map['play_count'] as num?)?.toInt() ?? 0,
      lastPlayedAt: (map['last_played_at'] as num?)?.toInt(),
      isFavorite: isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
