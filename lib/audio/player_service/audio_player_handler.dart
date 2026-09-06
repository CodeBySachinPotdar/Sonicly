import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../domain/playback.dart';
import '../../domain/repositories/music_repository.dart';
import '../../domain/song.dart';
import '../queue/queue_manager.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final QueueManager _queueManager = QueueManager();
  final MusicRepository _musicRepository;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _bufferedPositionSubscription;
  StreamSubscription? _durationSubscription;

  QueueManager get queueManager => _queueManager;
  AudioPlayer get player => _player;

  AudioPlayerHandler({required this._musicRepository}) {
    _initStreams();
  }

  void _initStreams() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      _broadcastState();
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });

    _positionSubscription = _player.positionStream.listen((_) => _broadcastState());
    _bufferedPositionSubscription = _player.bufferedPositionStream.listen((_) => _broadcastState());
    _durationSubscription = _player.durationStream.listen((d) {
      if (d != null && d > Duration.zero && mediaItem.value != null && mediaItem.value!.duration != d) {
        mediaItem.add(mediaItem.value!.copyWith(duration: d));
      }
      _broadcastState();
    });
  }

  void _broadcastState() {
    final playing = _player.playing;
    final processingState = _player.processingState;

    AudioProcessingState mappedProcessingState;
    switch (processingState) {
      case ProcessingState.idle:
        mappedProcessingState = AudioProcessingState.idle;
        break;
      case ProcessingState.loading:
        mappedProcessingState = AudioProcessingState.loading;
        break;
      case ProcessingState.buffering:
        mappedProcessingState = AudioProcessingState.buffering;
        break;
      case ProcessingState.ready:
        mappedProcessingState = AudioProcessingState.ready;
        break;
      case ProcessingState.completed:
        mappedProcessingState = AudioProcessingState.completed;
        break;
    }

    final controls = [
      MediaControl.skipToPrevious,
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: mappedProcessingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _queueManager.currentIndex,
      ),
    );
  }

  MediaItem _songToMediaItem(Song song) {
    Uri? artUri;
    if (song.artworkPath != null && song.artworkPath!.isNotEmpty) {
      artUri = Uri.file(song.artworkPath!);
    }

    return MediaItem(
      id: song.id,
      album: song.album,
      title: song.title,
      artist: song.artist,
      duration: song.durationMs > 0 ? Duration(milliseconds: song.durationMs) : null,
      artUri: artUri,
      extras: {
        'path': song.path,
        'format': song.format,
        'isFavorite': song.isFavorite,
      },
    );
  }

  Future<void> playSong(Song song, {List<Song>? queue, int? initialIndex}) async {
    if (queue != null) {
      _queueManager.setQueue(
        queue,
        initialIndex: initialIndex ?? queue.indexOf(song),
        shuffle: _queueManager.isShuffle,
      );
      this.queue.add(_queueManager.queue.map(_songToMediaItem).toList());
    } else if (_queueManager.queue.isEmpty) {
      _queueManager.setQueue([song]);
      this.queue.add([_songToMediaItem(song)]);
    }

    final current = _queueManager.currentSong ?? song;
    mediaItem.add(_songToMediaItem(current));

    try {
      final file = File(current.path);
      if (!await file.exists()) {
        // Skip to next if file not found
        skipToNext();
        return;
      }

      final duration = await _player.setFilePath(current.path);
      if (duration != null && duration > Duration.zero) {
        mediaItem.add((mediaItem.value ?? _songToMediaItem(current)).copyWith(duration: duration));
      }
      await _player.play();
      _musicRepository.recordSongPlay(current.id);
    } catch (e) {
      // If error playing, advance to next track
      skipToNext();
    }
  }

  @override
  Future<void> play() async {
    if (_queueManager.currentSong != null) {
      if (_player.processingState == ProcessingState.idle) {
        await playSong(_queueManager.currentSong!);
      } else {
        await _player.play();
      }
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _saveCurrentSession();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _saveCurrentSession();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _broadcastState();
  }

  @override
  Future<void> skipToNext() async {
    final nextSong = _queueManager.next();
    if (nextSong != null) {
      await playSong(nextSong);
    } else {
      await _player.stop();
      _saveCurrentSession();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    // If playing for more than 3 seconds, restart current track
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    final prevSong = _queueManager.previous();
    if (prevSong != null) {
      await playSong(prevSong);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final targetSong = _queueManager.jumpToIndex(index);
    if (targetSong != null) {
      await playSong(targetSong);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    if (_queueManager.isShuffle != enabled) {
      _queueManager.toggleShuffle();
      queue.add(_queueManager.queue.map(_songToMediaItem).toList());
      _broadcastState();
      _saveCurrentSession();
    }
  }

  Future<bool> toggleShuffle() async {
    final isShuffle = _queueManager.toggleShuffle();
    queue.add(_queueManager.queue.map(_songToMediaItem).toList());
    _broadcastState();
    _saveCurrentSession();
    return isShuffle;
  }

  Future<CustomRepeatMode> cycleRepeatMode() async {
    final mode = _queueManager.cycleRepeatMode();
    switch (mode) {
      case CustomRepeatMode.off:
        await _player.setLoopMode(LoopMode.off);
        break;
      case CustomRepeatMode.all:
        await _player.setLoopMode(LoopMode.all);
        break;
      case CustomRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
    }
    _saveCurrentSession();
    return mode;
  }

  void insertNext(Song song) {
    _queueManager.insertNext(song);
    queue.add(_queueManager.queue.map(_songToMediaItem).toList());
  }

  void addToQueue(Song song) {
    _queueManager.addToQueue(song);
    queue.add(_queueManager.queue.map(_songToMediaItem).toList());
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    final idx = _queueManager.queue.indexWhere((s) => s.id == mediaItem.id);
    if (idx != -1) {
      removeQueueItemAt(idx);
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    _queueManager.removeAt(index);
    queue.add(_queueManager.queue.map(_songToMediaItem).toList());
    _broadcastState();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    _queueManager.reorder(oldIndex, newIndex);
    queue.add(_queueManager.queue.map(_songToMediaItem).toList());
    _broadcastState();
  }

  void _saveCurrentSession() {
    final current = _queueManager.currentSong;
    _musicRepository.savePlaybackSession(
      songId: current?.id,
      positionMs: _player.position.inMilliseconds,
      queueSongIds: _queueManager.queue.map((s) => s.id).toList(),
      currentIndex: _queueManager.currentIndex,
      isShuffle: _queueManager.isShuffle,
      repeatMode: _queueManager.repeatMode,
    );
  }

  Future<void> restoreLastSession() async {
    try {
      final session = await _musicRepository.getLastPlaybackSession();
      if (session == null) return;

      final List<Song> restoredQueue = session['queue'] as List<Song>;
      final int restoredIndex = session['currentIndex'] as int;
      final Song? currentSong = session['currentSong'] as Song?;
      final int positionMs = session['positionMs'] as int;
      final bool isShuffle = session['isShuffle'] as bool;
      final CustomRepeatMode repeatMode = session['repeatMode'] as CustomRepeatMode;

      if (restoredQueue.isNotEmpty && restoredIndex >= 0) {
        _queueManager.setQueue(
          restoredQueue,
          initialIndex: restoredIndex,
          shuffle: isShuffle,
        );
        _queueManager.setRepeatMode(repeatMode);
        queue.add(_queueManager.queue.map(_songToMediaItem).toList());

        if (currentSong != null) {
          mediaItem.add(_songToMediaItem(currentSong));
          final file = File(currentSong.path);
          if (await file.exists()) {
            await _player.setFilePath(currentSong.path);
            await _player.seek(Duration(milliseconds: positionMs));
          }
        }
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _bufferedPositionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _player.dispose();
  }
}
