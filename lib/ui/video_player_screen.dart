import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/models.dart';

const _seekStep = Duration(seconds: 10);
const _hideDelay = Duration(seconds: 3);

/// Lecture plein écran d'une vidéo MP4 téléchargée (100% hors-ligne) avec
/// des contrôles personnalisés : masquage auto, double-tap pour avancer/
/// reculer de 10s, barre de progression avec indicateur de mise en tampon,
/// bascule paysage/portrait, veille écran désactivée pendant la lecture.
class VideoPlayerScreen extends StatefulWidget {
  final Video video;
  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _initializing = true;
  bool _error = false;

  bool _controlsVisible = true;
  Timer? _hideTimer;

  bool _muted = false;
  bool _landscapeLocked = false;

  // Indicateur transitoire "+10s" / "-10s" affiché lors d'un double-tap.
  int? _seekBump;
  Timer? _seekBumpTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    setState(() {
      _initializing = true;
      _error = false;
    });
    final controller = VideoPlayerController.file(File(widget.video.filePath));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.addListener(_onTick);
      controller.play();
      setState(() {
        _controller = controller;
        _initializing = false;
      });
      _scheduleAutoHide();
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _error = true);
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekBumpTimer?.cancel();
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const []);
    super.dispose();
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    final c = _controller;
    if (c == null || !c.value.isPlaying) return;
    _hideTimer = Timer(_hideDelay, () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleAutoHide();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
      _hideTimer?.cancel();
    } else {
      c.play();
      _scheduleAutoHide();
    }
    setState(() {});
  }

  void _seekBy(Duration offset) {
    final c = _controller;
    if (c == null) return;
    final target = c.value.position + offset;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > c.value.duration ? c.value.duration : target);
    c.seekTo(clamped);

    _seekBumpTimer?.cancel();
    setState(() => _seekBump = offset.inSeconds);
    _seekBumpTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _seekBump = null);
    });
  }

  void _handleDoubleTap(TapDownDetails details, double width) {
    final isRightSide = details.localPosition.dx > width / 2;
    _seekBy(isRightSide ? _seekStep : -_seekStep);
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() => _muted = !_muted);
    c.setVolume(_muted ? 0 : 1);
  }

  void _toggleOrientation() {
    setState(() => _landscapeLocked = !_landscapeLocked);
    SystemChrome.setPreferredOrientations(
      _landscapeLocked
          ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : const [],
    );
  }

  String _fmt(Duration d) {
    if (d.isNegative) return '0:00';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(h > 0 ? 2 : 1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: _error
            ? _ErrorView(onRetry: _initPlayer)
            : _initializing
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _player(),
      ),
    );
  }

  Widget _player() {
    final c = _controller!;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          onDoubleTapDown: (d) => _handleDoubleTap(d, constraints.maxWidth),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: c.value.aspectRatio,
                  child: VideoPlayer(c),
                ),
              ),
              if (c.value.isBuffering)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              if (_seekBump != null) _SeekBumpIndicator(seconds: _seekBump!),
              IgnorePointer(
                ignoring: !_controlsVisible,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _Controls(
                    controller: c,
                    title: widget.video.title,
                    muted: _muted,
                    landscapeLocked: _landscapeLocked,
                    fmt: _fmt,
                    onBack: () => Navigator.of(context).maybePop(),
                    onTogglePlay: _togglePlay,
                    onToggleMute: _toggleMute,
                    onToggleOrientation: _toggleOrientation,
                    onSeekStart: () => _hideTimer?.cancel(),
                    onSeekEnd: _scheduleAutoHide,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.white70, size: 48),
          const SizedBox(height: 12),
          const Text('Impossible de lire cette vidéo.',
              style: TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _SeekBumpIndicator extends StatelessWidget {
  final int seconds;
  const _SeekBumpIndicator({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final forward = seconds > 0;
    return Align(
      alignment: forward ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.4,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(forward ? Icons.fast_forward : Icons.fast_rewind,
                  color: Colors.white),
              const SizedBox(height: 2),
              Text('${forward ? '+' : '-'}${seconds.abs()}s',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final VideoPlayerController controller;
  final String title;
  final bool muted;
  final bool landscapeLocked;
  final String Function(Duration) fmt;
  final VoidCallback onBack;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleOrientation;
  final VoidCallback onSeekStart;
  final VoidCallback onSeekEnd;

  const _Controls({
    required this.controller,
    required this.title,
    required this.muted,
    required this.landscapeLocked,
    required this.fmt,
    required this.onBack,
    required this.onTogglePlay,
    required this.onToggleMute,
    required this.onToggleOrientation,
    required this.onSeekStart,
    required this.onSeekEnd,
  });

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Titre + retour, avec un dégradé pour la lisibilité.
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Play/pause central.
        Center(
          child: IconButton(
            iconSize: 64,
            icon: Icon(
              value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: Colors.white,
            ),
            onPressed: onTogglePlay,
          ),
        ),

        // Barre de progression + actions, avec un dégradé pour la lisibilité.
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 4),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ProgressBar(
                    controller: controller,
                    onSeekStart: onSeekStart,
                    onSeekEnd: onSeekEnd,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Text(fmt(value.position),
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const Text(' / ',
                            style: TextStyle(color: Colors.white38, fontSize: 12)),
                        Text(fmt(value.duration),
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const Spacer(),
                        IconButton(
                          onPressed: onToggleMute,
                          icon: Icon(muted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white, size: 20),
                        ),
                        IconButton(
                          onPressed: onToggleOrientation,
                          icon: Icon(
                            landscapeLocked ? Icons.fullscreen_exit : Icons.fullscreen,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Barre de progression avec indicateur de tampon (buffer) sous le curseur.
class _ProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onSeekStart;
  final VoidCallback onSeekEnd;

  const _ProgressBar({
    required this.controller,
    required this.onSeekStart,
    required this.onSeekEnd,
  });

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double? _dragValue;

  double get _bufferedFraction {
    final value = widget.controller.value;
    final duration = value.duration.inMilliseconds;
    if (duration <= 0 || value.buffered.isEmpty) return 0;
    final buffered = value.buffered.last.end.inMilliseconds;
    return (buffered / duration).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final durationMs = value.duration.inMilliseconds;
    final positionMs = value.position.inMilliseconds
        .clamp(0, durationMs <= 0 ? 1 : durationMs)
        .toDouble();
    final sliderValue = _dragValue ?? (durationMs > 0 ? positionMs / durationMs : 0.0);

    return SizedBox(
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _bufferedFraction,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: Colors.transparent,
              thumbColor: Theme.of(context).colorScheme.primary,
            ),
            child: Slider(
              value: sliderValue.clamp(0, 1),
              onChangeStart: (_) {
                widget.onSeekStart();
                setState(() => _dragValue = sliderValue);
              },
              onChanged: (v) => setState(() => _dragValue = v),
              onChangeEnd: (v) {
                widget.controller.seekTo(Duration(milliseconds: (v * durationMs).round()));
                setState(() => _dragValue = null);
                widget.onSeekEnd();
              },
            ),
          ),
        ],
      ),
    );
  }
}
