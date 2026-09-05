import 'dart:async';
import 'package:audio_session/audio_session.dart';
import '../player_service/audio_player_handler.dart';

class AudioFocusManager {
  final AudioPlayerHandler _playerHandler;
  StreamSubscription? _noisySubscription;
  StreamSubscription? _interruptionSubscription;

  AudioFocusManager({required this._playerHandler});

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // When wired headphones or Bluetooth disconnect, pause playback
    _noisySubscription = session.becomingNoisyEventStream.listen((_) {
      _playerHandler.pause();
    });

    // Handle interruptions (e.g. phone call, Siri, alarms)
    _interruptionSubscription = session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _playerHandler.player.setVolume(0.3);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            _playerHandler.pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _playerHandler.player.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
            // Optionally resume if desired
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });
  }

  Future<void> dispose() async {
    await _noisySubscription?.cancel();
    await _interruptionSubscription?.cancel();
  }
}
