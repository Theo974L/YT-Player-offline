import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models.dart';
import 'audio_handler.dart';

/// Façade UI par-dessus l'AudioPlayerHandler (audio_service).
/// Garde exactement la même API qu'avant -> aucun écran à modifier.
class PlayerService extends ChangeNotifier {
  final AudioPlayerHandler handler;

  PlayerService(this.handler) {
    _p.playerStateStream.listen((_) => notifyListeners());
    _p.currentIndexStream.listen((_) => notifyListeners());
    _p.sequenceStateStream.listen((_) => notifyListeners());
  }

  AudioPlayer get _p => handler.player;

  Stream<Duration> get positionStream => _p.positionStream;

  bool get hasMedia => handler.currentTrack != null;
  Track? get current => handler.currentTrack;
  bool get isPlaying => _p.playing;
  Duration get duration => _p.duration ?? Duration.zero;
  bool get shuffle => _p.shuffleModeEnabled;
  LoopMode get loopMode => _p.loopMode;

  Future<void> playQueue(List<Track> tracks, int index) =>
      handler.playTracks(tracks, index);

  void toggle() => _p.playing ? handler.pause() : handler.play();
  void next() => handler.skipToNext();
  void previous() => handler.skipToPrevious();
  void seek(Duration position) => handler.seek(position);
  void toggleShuffle() => _p.setShuffleModeEnabled(!_p.shuffleModeEnabled);

  void cycleLoop() {
    const modes = [LoopMode.off, LoopMode.all, LoopMode.one];
    final next = modes[(modes.indexOf(_p.loopMode) + 1) % modes.length];
    _p.setLoopMode(next);
  }

  // Le player appartient au handler (durée de vie de l'app) : on ne le dispose pas ici.
}
