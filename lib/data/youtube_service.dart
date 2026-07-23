import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// On masque SearchResult/Playlist/Video de la lib pour éviter la collision avec nos modèles.
import 'package:youtube_explode_dart/youtube_explode_dart.dart'
    hide SearchResult, Playlist, Video;

import 'models.dart';

/// Extraction + recherche + téléchargement via youtube_explode_dart (Android + iOS).
class YoutubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  void dispose() => _yt.close();

  /// Résout un lien (ou id) en un seul résultat.
  Future<SearchResult> resolve(String urlOrId) async {
    final v = await _yt.videos.get(urlOrId);
    return SearchResult(
      videoId: v.id.value,
      title: v.title,
      author: v.author,
      durationSec: v.duration?.inSeconds ?? 0,
      thumbnailUrl: v.thumbnails.highResUrl,
    );
  }

  Future<List<SearchResult>> search(String query) async {
    final results = await _yt.search.search(query);
    return results.map((v) {
      return SearchResult(
        videoId: v.id.value,
        title: v.title,
        author: v.author,
        durationSec: v.duration?.inSeconds ?? 0,
        thumbnailUrl: v.thumbnails.highResUrl,
      );
    }).toList();
  }

  /// Télécharge la piste audio (m4a/webm) dans le stockage privé de l'app.
  /// [onProgress] : 0.0 -> 1.0 (null si taille inconnue).
  Future<Track> downloadAudio(
    String videoIdOrUrl, {
    void Function(double? progress)? onProgress,
  }) async {
    final video = await _yt.videos.get(videoIdOrUrl);
    // Client "androidVr" : ses URLs de flux ne sont PAS bridées par YouTube,
    // donc le téléchargement se fait à pleine vitesse (le client web est throttlé).
    final manifest = await _yt.videos.streamsClient.getManifest(
      video.id,
      ytClients: [YoutubeApiClient.androidVr],
    );
    final audio = manifest.audioOnly.withHighestBitrate();

    final dir = await getApplicationDocumentsDirectory();
    final musicDir = Directory(p.join(dir.path, 'music'))
      ..createSync(recursive: true);
    final ext = audio.container.name == 'mp4' ? 'm4a' : audio.container.name;
    final file = File(p.join(musicDir.path, '${video.id.value}.$ext'));

    final total = audio.size.totalBytes;
    var received = 0;
    final sink = file.openWrite();
    await for (final chunk in _yt.videos.streamsClient.get(audio)) {
      received += chunk.length;
      sink.add(chunk);
      if (onProgress != null) {
        onProgress(total > 0 ? received / total : null);
      }
    }
    await sink.flush();
    await sink.close();

    return Track(
      youtubeId: video.id.value,
      title: video.title,
      artist: video.author,
      durationSec: video.duration?.inSeconds ?? 0,
      filePath: file.path,
      fileSizeBytes: file.lengthSync(),
      thumbnailUrl: video.thumbnails.highResUrl,
    );
  }

  /// Télécharge la vidéo complète (flux "muxed" : vidéo+audio déjà fusionnés
  /// par YouTube, plafonné à 360p mais lisible directement — pas besoin de
  /// ré-encoder ni de fusionner deux flux, donc téléchargement rapide et léger).
  /// La miniature est aussi mise en cache localement pour un visionnage
  /// 100% hors-ligne. [onProgress] : 0.0 -> 1.0 (null si taille inconnue).
  Future<Video> downloadVideo(
    String videoIdOrUrl, {
    void Function(double? progress)? onProgress,
  }) async {
    final video = await _yt.videos.get(videoIdOrUrl);
    final manifest = await _yt.videos.streamsClient.getManifest(video.id);
    final muxed = manifest.muxed.withHighestBitrate();

    final dir = await getApplicationDocumentsDirectory();
    final videosDir = Directory(p.join(dir.path, 'videos'))
      ..createSync(recursive: true);
    final file =
        File(p.join(videosDir.path, '${video.id.value}.${muxed.container.name}'));

    final total = muxed.size.totalBytes;
    var received = 0;
    final sink = file.openWrite();
    await for (final chunk in _yt.videos.streamsClient.get(muxed)) {
      received += chunk.length;
      sink.add(chunk);
      if (onProgress != null) {
        onProgress(total > 0 ? received / total : null);
      }
    }
    await sink.flush();
    await sink.close();

    final thumbnailPath =
        await _cacheThumbnail(video.id.value, video.thumbnails.highResUrl);

    return Video(
      youtubeId: video.id.value,
      title: video.title,
      author: video.author,
      durationSec: video.duration?.inSeconds ?? 0,
      filePath: file.path,
      fileSizeBytes: file.lengthSync(),
      thumbnailPath: thumbnailPath,
    );
  }

  /// Télécharge une miniature et la stocke localement ; retourne son chemin
  /// (ou null si l'opération échoue, ce qui n'est pas bloquant).
  Future<String?> _cacheThumbnail(String youtubeId, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;
      final dir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory(p.join(dir.path, 'thumbnails'))
        ..createSync(recursive: true);
      final file = File(p.join(thumbDir.path, '$youtubeId.jpg'));
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
