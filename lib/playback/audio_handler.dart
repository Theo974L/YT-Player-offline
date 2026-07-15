import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models.dart';

/// Pont entre le lecteur (just_audio) et le système (audio_service) :
/// notification média, contrôles écran verrouillé/casque, lecture en fond.
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();
  List<Track> _tracks = [];

  AudioPlayerHandler() {
    // Diffuse l'état du player vers le système.
    player.playbackEventStream.map(_transform).pipe(playbackState);
    // Met à jour la notification quand on change de piste / connaît la durée.
    player.currentIndexStream.listen((i) {
      if (i != null && i < _tracks.length) mediaItem.add(_item(_tracks[i]));
    });
    player.durationStream.listen((d) {
      final i = player.currentIndex;
      if (i != null && i < _tracks.length) mediaItem.add(_item(_tracks[i], d));
    });
  }

  Track? get currentTrack {
    final i = player.currentIndex;
    if (i == null || i < 0 || i >= _tracks.length) return null;
    return _tracks[i];
  }

  Future<void> playTracks(List<Track> tracks, int index) async {
    _tracks = List.of(tracks);
    queue.add(_tracks.map((t) => _item(t)).toList());
    await player.setAudioSource(
      ConcatenatingAudioSource(
        children:
            tracks.map((t) => AudioSource.uri(Uri.file(t.filePath))).toList(),
      ),
      initialIndex: index,
    );
    player.play();
  }

  MediaItem _item(Track t, [Duration? duration]) => MediaItem(
        id: t.id.toString(),
        title: t.title,
        artist: t.artist,
        duration: duration ?? Duration(seconds: t.durationSec),
        artUri: t.thumbnailUrl != null ? Uri.tryParse(t.thumbnailUrl!) : null,
      );

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() => player.seekToNext();

  @override
  Future<void> skipToPrevious() => player.seekToPrevious();

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {
    final enabled = mode == AudioServiceShuffleMode.all;
    if (enabled) await player.shuffle();
    await player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {
    await player.setLoopMode(const {
      AudioServiceRepeatMode.none: LoopMode.off,
      AudioServiceRepeatMode.one: LoopMode.one,
      AudioServiceRepeatMode.all: LoopMode.all,
      AudioServiceRepeatMode.group: LoopMode.all,
    }[mode]!);
  }

  PlaybackState _transform(PlaybackEvent event) {
    final playing = player.playing;
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
      shuffleMode: player.shuffleModeEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      repeatMode: const {
        LoopMode.off: AudioServiceRepeatMode.none,
        LoopMode.one: AudioServiceRepeatMode.one,
        LoopMode.all: AudioServiceRepeatMode.all,
      }[player.loopMode]!,
    );
  }
}
