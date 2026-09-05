class Album {
  final String name;
  final String artist;
  final int songCount;
  final int totalDurationMs;
  final String? artworkPath;
  final int? year;

  const Album({
    required this.name,
    required this.artist,
    required this.songCount,
    required this.totalDurationMs,
    this.artworkPath,
    this.year,
  });

  Duration get totalDuration => Duration(milliseconds: totalDurationMs);

  String get durationFormatted {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          artist == other.artist;

  @override
  int get hashCode => Object.hash(name, artist);
}
