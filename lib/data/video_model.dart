import 'dart:io';

import 'package:flutter/foundation.dart';

import 'database.dart';
import 'models.dart';
import 'youtube_service.dart';

/// État de la bibliothèque vidéo + logique de téléchargement (ChangeNotifier).
/// Miroir de LibraryModel, mais pour les vidéos MP4 (séparées des morceaux audio).
class VideoModel extends ChangeNotifier {
  final AppDatabase _db;
  final YoutubeService _yt;

  VideoModel(this._db, this._yt) {
    refresh();
  }

  List<Video> videos = [];
  int totalBytes = 0;
  final Set<String> _downloading = {};
  String? message;

  bool isDownloading(String videoId) => _downloading.contains(videoId);

  Future<void> refresh() async {
    videos = await _db.allVideos();
    totalBytes = await _db.totalVideoBytes();
    notifyListeners();
  }

  Future<void> download(String videoId) async {
    if (_downloading.contains(videoId)) return;
    if (await _db.videoExistsByYoutubeId(videoId)) {
      message = 'Déjà dans la bibliothèque vidéo';
      notifyListeners();
      return;
    }
    _downloading.add(videoId);
    notifyListeners();
    try {
      final video = await _yt.downloadVideo(videoId);
      await _db.insertVideo(video);
      message = '« ${video.title} » ajoutée';
      await refresh();
    } catch (_) {
      message = 'Échec du téléchargement vidéo';
    } finally {
      _downloading.remove(videoId);
      notifyListeners();
    }
  }

  Future<void> delete(Video v) async {
    try {
      final f = File(v.filePath);
      if (f.existsSync()) f.deleteSync();
      if (v.thumbnailPath != null) {
        final t = File(v.thumbnailPath!);
        if (t.existsSync()) t.deleteSync();
      }
    } catch (_) {}
    await _db.deleteVideo(v.id);
    await refresh();
  }

  void consumeMessage() {
    message = null;
  }
}
