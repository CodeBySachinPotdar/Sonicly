import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final int createdAt;
  final int updatedAt;
  final int songCount;
  final int totalDurationMs;
  final List<Song> songs;

  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.songCount = 0,
    this.totalDurationMs = 0,
    this.songs = const [],
  });

  Duration get totalDuration => Duration(milliseconds: totalDurationMs);

  String get durationFormatted {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    final seconds = totalDuration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  Playlist copyWith({
    String? id,
    String? name,
    int? createdAt,
    int? updatedAt,
    int? songCount,
    int? totalDurationMs,
    List<Song>? songs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      songCount: songCount ?? this.songCount,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      songs: songs ?? this.songs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map, {List<Song> songs = const []}) {
    final songCount = (map['song_count'] as num?)?.toInt() ?? songs.length;
    final totalDurationMs = (map['total_duration_ms'] as num?)?.toInt() ??
        songs.fold<int>(0, (sum, s) => sum + s.durationMs);

    return Playlist(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
      updatedAt: (map['updated_at'] as num?)?.toInt() ?? 0,
      songCount: songCount,
      totalDurationMs: totalDurationMs,
      songs: songs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
