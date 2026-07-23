/// Un morceau téléchargé (stocké en base).
class Track {
  final int id;
  final String youtubeId;
  final String title;
  final String? artist;
  final int durationSec;
  final String filePath;
  final int fileSizeBytes;
  final String? thumbnailUrl;

  const Track({
    this.id = 0,
    required this.youtubeId,
    required this.title,
    this.artist,
    required this.durationSec,
    required this.filePath,
    required this.fileSizeBytes,
    this.thumbnailUrl,
  });

  Map<String, Object?> toMap() => {
        if (id != 0) 'id': id,
        'youtubeId': youtubeId,
        'title': title,
        'artist': artist,
        'durationSec': durationSec,
        'filePath': filePath,
        'fileSizeBytes': fileSizeBytes,
        'thumbnailUrl': thumbnailUrl,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

  static Track fromMap(Map<String, Object?> m) => Track(
        id: m['id'] as int,
        youtubeId: m['youtubeId'] as String,
        title: m['title'] as String,
        artist: m['artist'] as String?,
        durationSec: m['durationSec'] as int,
        filePath: m['filePath'] as String,
        fileSizeBytes: m['fileSizeBytes'] as int,
        thumbnailUrl: m['thumbnailUrl'] as String?,
      );
}

/// Une vidéo téléchargée (stockée en base, séparée des morceaux audio).
class Video {
  final int id;
  final String youtubeId;
  final String title;
  final String? author;
  final int durationSec;
  final String filePath;
  final int fileSizeBytes;
  final String? thumbnailPath;

  const Video({
    this.id = 0,
    required this.youtubeId,
    required this.title,
    this.author,
    required this.durationSec,
    required this.filePath,
    required this.fileSizeBytes,
    this.thumbnailPath,
  });

  Map<String, Object?> toMap() => {
        if (id != 0) 'id': id,
        'youtubeId': youtubeId,
        'title': title,
        'author': author,
        'durationSec': durationSec,
        'filePath': filePath,
        'fileSizeBytes': fileSizeBytes,
        'thumbnailPath': thumbnailPath,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

  static Video fromMap(Map<String, Object?> m) => Video(
        id: m['id'] as int,
        youtubeId: m['youtubeId'] as String,
        title: m['title'] as String,
        author: m['author'] as String?,
        durationSec: m['durationSec'] as int,
        filePath: m['filePath'] as String,
        fileSizeBytes: m['fileSizeBytes'] as int,
        thumbnailPath: m['thumbnailPath'] as String?,
      );
}

/// Résultat de recherche YouTube (avant téléchargement).
class SearchResult {
  final String videoId;
  final String title;
  final String? author;
  final int durationSec;
  final String? thumbnailUrl;

  const SearchResult({
    required this.videoId,
    required this.title,
    this.author,
    required this.durationSec,
    this.thumbnailUrl,
  });
}

/// Une playlist locale (nom + nombre de morceaux).
class Playlist {
  final int id;
  final String name;
  final int trackCount;

  const Playlist({required this.id, required this.name, this.trackCount = 0});
}

String formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String formatSize(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb >= 1) return '${mb.toStringAsFixed(1)} Mo';
  return '${(bytes / 1024).toStringAsFixed(0)} Ko';
}
