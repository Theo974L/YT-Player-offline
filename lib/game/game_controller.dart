import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models.dart';
import 'text_match.dart';

/// Logique du blind test. Utilise SON PROPRE lecteur audio (indépendant du
/// mini-lecteur) pour ne jouer que de courts extraits.
class GameController extends ChangeNotifier {
  // Durées RÉELLEMENT jouées.
  static const List<int> levelsMs = [500, 1000, 2000, 3000];
  // Ce qui est AFFICHÉ au joueur (volontairement plus court sur les 2 premiers).
  static const List<String> levelDisplay = ['0.1', '0.5', '1.5', '3'];
  static const List<int> levelPoints = [1000, 600, 300, 150];
  static const int maxAttempts = 3;

  final AudioPlayer _player = AudioPlayer();
  final Random _rng = Random();

  final List<Track> songs;
  int index = 0;
  int levelIndex = 0;
  int attemptsLeft = maxAttempts;
  int score = 0;
  final List<int> results = [];
  String? feedback;
  bool finished = false;
  bool busy = false;

  int _startMs = 0;
  StreamSubscription<Duration>? _posSub;

  GameController(List<Track> pool)
      : songs = (pool.toList()..shuffle()).take(min(10, pool.length)).toList() {
    _loadCurrent();
  }

  Track get current => songs[index];
  int get total => songs.length;
  int get windowMs => levelsMs[levelIndex];
  double get windowSeconds => windowMs / 1000;
  int get currentCeiling => levelPoints[levelIndex];
  bool get canExtend => levelIndex < levelsMs.length - 1;
  int get maxScore => songs.length * levelPoints.first;

  /// Libellé affiché au joueur (ex. "0.1") — volontairement différent du réel.
  String get windowLabel => levelDisplay[levelIndex];
  String get nextWindowLabel =>
      canExtend ? levelDisplay[levelIndex + 1] : levelDisplay.last;

  Future<void> _loadCurrent() async {
    busy = true;
    feedback = null;
    levelIndex = 0;
    attemptsLeft = maxAttempts;
    notifyListeners();

    final track = current;
    int totalMs;
    try {
      final d = await _player.setFilePath(track.filePath);
      totalMs = (d ?? Duration(seconds: track.durationSec)).inMilliseconds;
    } catch (_) {
      totalMs = track.durationSec * 1000;
    }
    // Départ aléatoire dans la portion CENTRALE (15%–75%) du morceau : évite
    // les intros/outros souvent silencieuses. (Une vraie détection de silence
    // demanderait de décoder l'audio, pas trivial côté Flutter.)
    final windowMax = levelsMs.last;
    final lower = (totalMs * 0.15).round();
    final upper = (totalMs * 0.75).round() - windowMax;
    if (upper > lower) {
      _startMs = lower + _rng.nextInt(upper - lower);
    } else {
      final maxStart = totalMs - windowMax;
      _startMs = maxStart > 0 ? _rng.nextInt(maxStart) : 0;
    }

    busy = false;
    await _playWindow();
  }

  Future<void> _playWindow() async {
    await _posSub?.cancel();
    _posSub = null;
    final endMs = _startMs + windowMs;
    try {
      await _player.seek(Duration(milliseconds: _startMs));
      // On coupe quand la POSITION RÉELLE atteint la fin de la fenêtre : ça
      // attend que la lecture ait vraiment démarré (évite les extraits muets
      // dus à la latence de démarrage sur les fenêtres courtes).
      _posSub = _player.positionStream.listen((pos) {
        if (pos.inMilliseconds >= endMs) {
          _posSub?.cancel();
          _posSub = null;
          _player.pause();
        }
      });
      // Ne PAS await play() : son Future ne se termine qu'à la fin de la lecture.
      unawaited(_player.play());
    } catch (_) {}
    notifyListeners();
  }

  /// Réécouter l'extrait courant (même durée).
  Future<void> replay() => _playWindow();

  /// Étendre : 0.1 → 0.5 → 1 → 2 s (baisse le plafond de points).
  void extend() {
    if (!canExtend || busy) return;
    levelIndex++;
    _playWindow();
  }

  Future<void> submit(String guess) async {
    if (busy || finished || guess.trim().isEmpty) return;
    final sim = titleSimilarity(guess, current.title);
    final mult = sim >= 0.9
        ? 1.0
        : sim >= 0.7
            ? 0.8
            : sim >= 0.5
                ? 0.5
                : 0.0;

    if (mult > 0) {
      final pts = (levelPoints[levelIndex] * mult).round();
      score += pts;
      results.add(pts);
      feedback = 'Bravo ! « ${current.title} »  (+$pts)';
      busy = true;
      notifyListeners();
      _posSub?.cancel();
      await _player.pause();
      await Future.delayed(const Duration(milliseconds: 1200));
      await _advance();
    } else {
      attemptsLeft--;
      if (attemptsLeft <= 0) {
        results.add(0);
        feedback = 'Raté ! C\'était « ${current.title} »';
        busy = true;
        notifyListeners();
        _posSub?.cancel();
        await _player.pause();
        await Future.delayed(const Duration(milliseconds: 1400));
        await _advance();
      } else {
        feedback =
            'Raté — encore $attemptsLeft essai${attemptsLeft > 1 ? "s" : ""}';
        notifyListeners();
      }
    }
  }

  Future<void> skip() async {
    if (busy || finished) return;
    results.add(0);
    feedback = 'Passé — c\'était « ${current.title} »';
    busy = true;
    notifyListeners();
    _posSub?.cancel();
    await _player.pause();
    await Future.delayed(const Duration(milliseconds: 1200));
    await _advance();
  }

  Future<void> _advance() async {
    if (index >= songs.length - 1) {
      finished = true;
      busy = false;
      _posSub?.cancel();
      await _player.stop();
      notifyListeners();
      return;
    }
    index++;
    await _loadCurrent();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
