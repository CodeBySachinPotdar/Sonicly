class Artist {
  final String name;
  final int songCount;
  final int albumCount;
  final int totalDurationMs;

  const Artist({
    required this.name,
    required this.songCount,
    required this.albumCount,
    required this.totalDurationMs,
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
      other is Artist && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
