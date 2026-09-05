import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import '../../audio/player_service/audio_player_handler.dart';
import '../../domain/playback.dart';
import '../../domain/repositories/music_repository.dart';
import '../../domain/song.dart';

class PlayerViewModel extends ChangeNotifier {
  final AudioPlayerHandler _audioHandler;
  final MusicRepository _musicRepository;

  StreamSubscription? _playbackStateSubscription;
  StreamSubscription? _mediaItemSubscription;

  Song? _currentSong;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffle = false;
  CustomRepeatMode _repeatMode = CustomRepeatMode.off;
  bool _isFavorite = false;

  PlayerViewModel({
    required this._audioHandler,
    required this._musicRepository,
  }) {
    _init();
  }

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  List<Song> get queue => _audioHandler.queueManager.queue;
  int get currentIndex => _audioHandler.queueManager.currentIndex;
  bool get isShuffle => _isShuffle;
  CustomRepeatMode get repeatMode => _repeatMode;
  bool get isFavorite => _isFavorite;
  bool get hasSong => _currentSong != null;

  void _init() {
    _playbackStateSubscription = _audioHandler.playbackState.listen((state) {
      final wasPlaying = _isPlaying;
      final wasBuffering = _isBuffering;
      final oldPos = _position;

      _isPlaying = state.playing;
      _isBuffering = state.processingState == AudioProcessingState.buffering;
      _position = state.position;

      if (wasPlaying != _isPlaying ||
          wasBuffering != _isBuffering ||
          (oldPos - _position).abs() >= const Duration(milliseconds: 200)) {
        notifyListeners();
      }
    });

    _mediaItemSubscription = _audioHandler.mediaItem.listen((item) async {
      if (item != null) {
        _duration = item.duration ?? Duration.zero;
        _isShuffle = _audioHandler.queueManager.isShuffle;
        _repeatMode = _audioHandler.queueManager.repeatMode;

        // Sync currentSong entity
        final currentFromQueue = _audioHandler.queueManager.currentSong;
        if (currentFromQueue != null && currentFromQueue.id == item.id) {
          _currentSong = currentFromQueue;
        } else {
          _currentSong = Song(
            id: item.id,
            path: (item.extras?['path'] as String?) ?? '',
            title: item.title,
            artist: item.artist ?? 'Unknown Artist',
            album: item.album ?? 'Unknown Album',
            durationMs: item.duration?.inMilliseconds ?? 0,
            size: 0,
            dateAdded: 0,
            dateModified: 0,
            format: (item.extras?['format'] as String?) ?? 'mp3',
            artworkPath: item.artUri?.toFilePath(),
            hasArtwork: item.artUri != null,
          );
        }

        _isFavorite = await _musicRepository.isFavorite(item.id);
        notifyListeners();
      }
    });
  }

  Future<void> playSong(Song song, {List<Song>? queue, int? initialIndex}) async {
    await _audioHandler.playSong(song, queue: queue, initialIndex: initialIndex);
  }

  Future<void> play() async {
    await _audioHandler.play();
  }

  Future<void> pause() async {
    await _audioHandler.pause();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    _position = position;
    notifyListeners();
    await _audioHandler.seek(position);
  }

  Future<void> skipNext() async {
    await _audioHandler.skipToNext();
  }

  Future<void> skipPrevious() async {
    await _audioHandler.skipToPrevious();
  }

  Future<void> skipToQueueItem(int index) async {
    await _audioHandler.skipToQueueItem(index);
  }

  Future<void> toggleShuffle() async {
    _isShuffle = await _audioHandler.toggleShuffle();
    notifyListeners();
  }

  Future<void> cycleRepeatMode() async {
    _repeatMode = await _audioHandler.cycleRepeatMode();
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    if (_currentSong == null) return;
    _isFavorite = await _musicRepository.toggleFavorite(_currentSong!.id);
    _currentSong = _currentSong!.copyWith(isFavorite: _isFavorite);
    notifyListeners();
  }

  void insertNext(Song song) {
    _audioHandler.insertNext(song);
    notifyListeners();
  }

  void addToQueue(Song song) {
    _audioHandler.addToQueue(song);
    notifyListeners();
  }

  void removeQueueItem(int index) {
    _audioHandler.removeQueueItemAt(index);
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    _audioHandler.reorderQueue(oldIndex, newIndex);
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackStateSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    super.dispose();
  }
}
