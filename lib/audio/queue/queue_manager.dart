import 'dart:math';
import '../../domain/playback.dart';
import '../../domain/song.dart';

class QueueManager {
  List<Song> _originalQueue = [];
  List<Song> _activeQueue = [];
  int _currentIndex = -1;
  bool _isShuffle = false;
  CustomRepeatMode _repeatMode = CustomRepeatMode.off;

  List<Song> get queue => List.unmodifiable(_activeQueue);
  int get currentIndex => _currentIndex;
  bool get isShuffle => _isShuffle;
  CustomRepeatMode get repeatMode => _repeatMode;

  Song? get currentSong {
    if (_currentIndex >= 0 && _currentIndex < _activeQueue.length) {
      return _activeQueue[_currentIndex];
    }
    return null;
  }

  bool get hasNext {
    if (_activeQueue.isEmpty) return false;
    if (_repeatMode == CustomRepeatMode.all || _repeatMode == CustomRepeatMode.one) return true;
    return _currentIndex < _activeQueue.length - 1;
  }

  bool get hasPrevious {
    if (_activeQueue.isEmpty) return false;
    if (_repeatMode == CustomRepeatMode.all) return true;
    return _currentIndex > 0;
  }

  void setQueue(
    List<Song> songs, {
    int initialIndex = 0,
    bool shuffle = false,
  }) {
    _originalQueue = List.from(songs);
    _isShuffle = shuffle;

    if (songs.isEmpty) {
      _activeQueue = [];
      _currentIndex = -1;
      return;
    }

    final safeIndex = initialIndex.clamp(0, songs.length - 1);
    final targetSong = songs[safeIndex];

    if (_isShuffle) {
      _activeQueue = _generateShuffledList(_originalQueue, targetSong);
      _currentIndex = _activeQueue.indexOf(targetSong);
    } else {
      _activeQueue = List.from(_originalQueue);
      _currentIndex = safeIndex;
    }
  }

  Song? jumpToIndex(int index) {
    if (index >= 0 && index < _activeQueue.length) {
      _currentIndex = index;
      return currentSong;
    }
    return null;
  }

  Song? next() {
    if (_activeQueue.isEmpty) return null;

    if (_repeatMode == CustomRepeatMode.one) {
      return currentSong;
    }

    if (_currentIndex < _activeQueue.length - 1) {
      _currentIndex++;
      return currentSong;
    } else if (_repeatMode == CustomRepeatMode.all) {
      _currentIndex = 0;
      return currentSong;
    }

    return null;
  }

  Song? previous() {
    if (_activeQueue.isEmpty) return null;

    if (_repeatMode == CustomRepeatMode.one) {
      return currentSong;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
      return currentSong;
    } else if (_repeatMode == CustomRepeatMode.all) {
      _currentIndex = _activeQueue.length - 1;
      return currentSong;
    }

    return null;
  }

  bool toggleShuffle() {
    _isShuffle = !_isShuffle;
    final current = currentSong;

    if (_isShuffle) {
      if (current != null) {
        _activeQueue = _generateShuffledList(_originalQueue, current);
        _currentIndex = _activeQueue.indexOf(current);
      } else {
        _activeQueue = List.from(_originalQueue)..shuffle(Random());
        _currentIndex = 0;
      }
    } else {
      // Revert to original order
      _activeQueue = List.from(_originalQueue);
      if (current != null) {
        final originalIdx = _originalQueue.indexOf(current);
        _currentIndex = originalIdx != -1 ? originalIdx : 0;
      }
    }
    return _isShuffle;
  }

  CustomRepeatMode cycleRepeatMode() {
    switch (_repeatMode) {
      case CustomRepeatMode.off:
        _repeatMode = CustomRepeatMode.all;
        break;
      case CustomRepeatMode.all:
        _repeatMode = CustomRepeatMode.one;
        break;
      case CustomRepeatMode.one:
        _repeatMode = CustomRepeatMode.off;
        break;
    }
    return _repeatMode;
  }

  void setRepeatMode(CustomRepeatMode mode) {
    _repeatMode = mode;
  }

  void insertNext(Song song) {
    if (_activeQueue.isEmpty) {
      setQueue([song]);
      return;
    }
    final nextIdx = _currentIndex + 1;
    _activeQueue.insert(nextIdx, song);
    _originalQueue.add(song);
  }

  void addToQueue(Song song) {
    if (_activeQueue.isEmpty) {
      setQueue([song]);
      return;
    }
    _activeQueue.add(song);
    _originalQueue.add(song);
  }

  void removeAt(int index) {
    if (index < 0 || index >= _activeQueue.length) return;
    final song = _activeQueue.removeAt(index);
    _originalQueue.remove(song);

    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      if (_currentIndex >= _activeQueue.length) {
        _currentIndex = _activeQueue.length - 1;
      }
    }
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _activeQueue.length) return;
    if (newIndex < 0 || newIndex >= _activeQueue.length) return;

    final song = _activeQueue.removeAt(oldIndex);
    _activeQueue.insert(newIndex, song);

    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
  }

  void clear() {
    _originalQueue.clear();
    _activeQueue.clear();
    _currentIndex = -1;
  }

  List<Song> _generateShuffledList(List<Song> source, Song firstSong) {
    final others = source.where((s) => s != firstSong).toList()..shuffle(Random());
    return [firstSong, ...others];
  }
}
