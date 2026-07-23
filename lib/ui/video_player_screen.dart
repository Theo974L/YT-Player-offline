import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/models.dart';

/// Lecture plein écran d'une vidéo MP4 téléchargée (100% hors-ligne).
class VideoPlayerScreen extends StatefulWidget {
  final Video video;
  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.video.filePath))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _error = true);
      });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.video.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: _error
          ? const Center(
              child: Text('Impossible de lire cette vidéo.',
                  style: TextStyle(color: Colors.white)),
            )
          : !_ready
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    _Controls(controller: _controller),
                  ],
                ),
    );
  }
}

class _Controls extends StatelessWidget {
  final VideoPlayerController controller;
  const _Controls({required this.controller});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 2),
          child: Slider(
            value: value.position.inMilliseconds
                .clamp(0, value.duration.inMilliseconds)
                .toDouble(),
            max: value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
            onChanged: (v) => controller.seekTo(Duration(milliseconds: v.toInt())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(value.position),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              IconButton(
                iconSize: 40,
                color: Colors.white,
                icon: Icon(value.isPlaying ? Icons.pause_circle : Icons.play_circle),
                onPressed: () =>
                    value.isPlaying ? controller.pause() : controller.play(),
              ),
              Text(_fmt(value.duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
