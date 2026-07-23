import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Base locale sqflite : morceaux + playlists (schéma complet dès la v1).
class AppDatabase {
  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'yt_offline.db');
    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE tracks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            youtubeId TEXT NOT NULL,
            title TEXT NOT NULL,
            artist TEXT,
            durationSec INTEGER NOT NULL,
            filePath TEXT NOT NULL,
            fileSizeBytes INTEGER NOT NULL,
            thumbnailUrl TEXT,
            createdAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            createdAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE playlist_track (
            playlistId INTEGER NOT NULL,
            trackId INTEGER NOT NULL,
            addedAt INTEGER NOT NULL,
            PRIMARY KEY (playlistId, trackId),
            FOREIGN KEY (playlistId) REFERENCES playlists(id) ON DELETE CASCADE,
            FOREIGN KEY (trackId) REFERENCES tracks(id) ON DELETE CASCADE
          )
        ''');
        await db.execute(_createVideosTable);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(_createVideosTable);
        }
      },
    );
  }

  static const _createVideosTable = '''
    CREATE TABLE videos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      youtubeId TEXT NOT NULL,
      title TEXT NOT NULL,
      author TEXT,
      durationSec INTEGER NOT NULL,
      filePath TEXT NOT NULL,
      fileSizeBytes INTEGER NOT NULL,
      thumbnailPath TEXT,
      createdAt INTEGER NOT NULL
    )
  ''';

  // ---- Tracks ----
  Future<int> insertTrack(Track t) async =>
      (await db).insert('tracks', t.toMap());

  Future<List<Track>> allTracks() async {
    final rows = await (await db).query('tracks', orderBy: 'createdAt DESC');
    return rows.map(Track.fromMap).toList();
  }

  Future<bool> existsByYoutubeId(String ytId) async {
    final rows = await (await db)
        .query('tracks', where: 'youtubeId = ?', whereArgs: [ytId], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> deleteTrack(int id) async =>
      (await db).delete('tracks', where: 'id = ?', whereArgs: [id]);

  Future<int> totalBytes() async {
    final r = await (await db)
        .rawQuery('SELECT COALESCE(SUM(fileSizeBytes),0) AS total FROM tracks');
    return (r.first['total'] as int?) ?? 0;
  }

  // ---- Playlists (utilisées en partie 2) ----
  Future<int> createPlaylist(String name) async => (await db).insert('playlists', {
        'name': name,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

  Future<void> deletePlaylist(int id) async =>
      (await db).delete('playlists', where: 'id = ?', whereArgs: [id]);

  Future<List<Playlist>> playlists() async {
    final rows = await (await db).rawQuery('''
      SELECT p.id AS id, p.name AS name, COUNT(pt.trackId) AS trackCount
      FROM playlists p
      LEFT JOIN playlist_track pt ON pt.playlistId = p.id
      GROUP BY p.id ORDER BY p.createdAt DESC
    ''');
    return rows
        .map((m) => Playlist(
              id: m['id'] as int,
              name: m['name'] as String,
              trackCount: m['trackCount'] as int,
            ))
        .toList();
  }

  Future<void> addTrackToPlaylist(int playlistId, int trackId) async =>
      (await db).insert(
        'playlist_track',
        {
          'playlistId': playlistId,
          'trackId': trackId,
          'addedAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

  Future<void> removeTrackFromPlaylist(int playlistId, int trackId) async =>
      (await db).delete('playlist_track',
          where: 'playlistId = ? AND trackId = ?',
          whereArgs: [playlistId, trackId]);

  Future<List<Track>> tracksOfPlaylist(int playlistId) async {
    final rows = await (await db).rawQuery('''
      SELECT t.* FROM tracks t
      INNER JOIN playlist_track pt ON pt.trackId = t.id
      WHERE pt.playlistId = ? ORDER BY pt.addedAt ASC
    ''', [playlistId]);
    return rows.map(Track.fromMap).toList();
  }

  // ---- Videos ----
  Future<int> insertVideo(Video v) async =>
      (await db).insert('videos', v.toMap());

  Future<List<Video>> allVideos() async {
    final rows = await (await db).query('videos', orderBy: 'createdAt DESC');
    return rows.map(Video.fromMap).toList();
  }

  Future<bool> videoExistsByYoutubeId(String ytId) async {
    final rows = await (await db)
        .query('videos', where: 'youtubeId = ?', whereArgs: [ytId], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> deleteVideo(int id) async =>
      (await db).delete('videos', where: 'id = ?', whereArgs: [id]);

  Future<int> totalVideoBytes() async {
    final r = await (await db)
        .rawQuery('SELECT COALESCE(SUM(fileSizeBytes),0) AS total FROM videos');
    return (r.first['total'] as int?) ?? 0;
  }
}
