import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database.dart';
import 'models.dart';

/// Résultat d'un import : combien de morceaux ont été ajoutés / ignorés
/// (déjà présents dans la bibliothèque).
class ImportResult {
  final int added;
  final int skipped;
  const ImportResult({required this.added, required this.skipped});
}

/// Sauvegarde/restauration de la bibliothèque musicale (morceaux audio
/// uniquement) sous forme d'une archive .zip auto-suffisante :
/// fichiers audio + métadonnées, pour transférer la bibliothèque sans
/// avoir à retélécharger quoi que ce soit.
class BackupService {
  final AppDatabase _db;
  BackupService(this._db);

  /// Construit l'archive et laisse l'utilisateur choisir où l'enregistrer.
  /// Retourne le chemin choisi, ou null si l'utilisateur a annulé.
  Future<String?> exportLibrary() async {
    final tracks = await _db.allTracks();
    final archive = Archive();

    final manifest = {
      'version': 1,
      'tracks': [
        for (final t in tracks)
          {
            'youtubeId': t.youtubeId,
            'title': t.title,
            'artist': t.artist,
            'durationSec': t.durationSec,
            'thumbnailUrl': t.thumbnailUrl,
            'file': 'music/${p.basename(t.filePath)}',
          },
      ],
    };
    archive.addFile(ArchiveFile.string(
      'manifest.json',
      const JsonEncoder.withIndent('  ').convert(manifest),
    ));

    for (final t in tracks) {
      final file = File(t.filePath);
      if (!file.existsSync()) continue;
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(
        'music/${p.basename(t.filePath)}',
        bytes.length,
        bytes,
      ));
    }

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw const FormatException('Échec de la création de l’archive');
    }
    final fileName =
        'yt_offline_backup_${DateTime.now().toIso8601String().split('T').first}.zip';

    return FilePicker.platform.saveFile(
      dialogTitle: 'Exporter la bibliothèque',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      bytes: Uint8List.fromList(zipBytes),
    );
  }

  /// Laisse l'utilisateur choisir un .zip exporté précédemment et réimporte
  /// les morceaux qu'il contient (les doublons, par youtubeId, sont ignorés).
  /// Retourne null si l'utilisateur a annulé.
  Future<ImportResult?> importLibrary() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Importer une bibliothèque',
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (bytes == null) return null;

    final archive = ZipDecoder().decodeBytes(bytes);
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw const FormatException('Archive invalide : manifest.json manquant');
    }
    final manifest =
        jsonDecode(utf8.decode(manifestFile.content as List<int>))
            as Map<String, Object?>;
    final entries = (manifest['tracks'] as List).cast<Map<String, Object?>>();

    final dir = await getApplicationDocumentsDirectory();
    final musicDir = Directory(p.join(dir.path, 'music'))
      ..createSync(recursive: true);

    var added = 0;
    var skipped = 0;
    for (final entry in entries) {
      final youtubeId = entry['youtubeId'] as String;
      if (await _db.existsByYoutubeId(youtubeId)) {
        skipped++;
        continue;
      }
      final relPath = entry['file'] as String;
      final zipEntry = archive.findFile(relPath);
      if (zipEntry == null) {
        skipped++;
        continue;
      }
      final outFile = File(p.join(musicDir.path, p.basename(relPath)));
      await outFile.writeAsBytes(zipEntry.content as List<int>);

      await _db.insertTrack(Track(
        youtubeId: youtubeId,
        title: entry['title'] as String,
        artist: entry['artist'] as String?,
        durationSec: entry['durationSec'] as int,
        filePath: outFile.path,
        fileSizeBytes: outFile.lengthSync(),
        thumbnailUrl: entry['thumbnailUrl'] as String?,
      ));
      added++;
    }

    return ImportResult(added: added, skipped: skipped);
  }
}
