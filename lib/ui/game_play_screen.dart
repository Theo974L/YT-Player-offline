import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../game/game_controller.dart';
import '../playback/player_service.dart';

class GamePlayScreen extends StatefulWidget {
  final List<Track> pool;
  const GamePlayScreen({super.key, required this.pool});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late GameController _controller;
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = GameController(widget.pool);
    // Met en pause le mini-lecteur pour ne pas avoir deux audios en même temps.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<PlayerService>();
      if (p.isPlaying) p.toggle();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final before = _controller.index;
    await _controller.submit(_text.text);
    if (_controller.index != before || _controller.finished) _text.clear();
  }

  Future<void> _skip() async {
    await _controller.skip();
    _text.clear();
  }

  void _restart() {
    setState(() {
      _controller.dispose();
      _controller = GameController(widget.pool);
      _text.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return _controller.finished ? _results(context) : _playing(context);
      },
    );
  }

  // ---------------- Partie en cours ----------------
  Widget _playing(BuildContext context) {
    final c = _controller;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Titre ${c.index + 1}/${c.total}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('${c.score} pts',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Bouton réécouter
              GestureDetector(
                onTap: c.busy ? null : c.replay,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withOpacity(c.busy ? 0.4 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.replay,
                          size: 48, color: scheme.onPrimary),
                      const SizedBox(height: 4),
                      Text('${c.windowLabel} s',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Plafond actuel : ${c.currentCeiling} pts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      )),
              Text('Essais restants : ${c.attemptsLeft}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      )),

              const SizedBox(height: 16),
              // Étendre
              OutlinedButton.icon(
                onPressed: (c.canExtend && !c.busy) ? c.extend : null,
                icon: const Icon(Icons.timelapse),
                label: Text(c.canExtend
                    ? 'Étendre → ${c.nextWindowLabel} s'
                    : 'Extrait max'),
              ),

              const SizedBox(height: 28),

              // Feedback
              if (c.feedback != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    c.feedback!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: c.feedback!.startsWith('Raté')
                              ? scheme.error
                              : scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),

              // Réponse
              TextField(
                controller: _text,
                enabled: !c.busy,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Ton titre…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: c.busy ? null : _skip,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Passer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: c.busy ? null : _submit,
                      icon: const Icon(Icons.check),
                      label: const Text('Valider'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Résultats ----------------
  Widget _results(BuildContext context) {
    final c = _controller;
    final scheme = Theme.of(context).colorScheme;
    final found = c.results.where((p) => p > 0).length;
    final ratio = c.maxScore == 0 ? 0.0 : c.score / c.maxScore;
    final message = ratio >= 0.8
        ? 'Impressionnant ! 🏆'
        : ratio >= 0.5
            ? 'Bien joué ! 🎉'
            : ratio >= 0.25
                ? 'Pas mal 🙂'
                : 'La prochaine sera la bonne 💪';

    return Scaffold(
      appBar: AppBar(title: const Text('Résultats')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.emoji_events, size: 80, color: scheme.primary),
              const SizedBox(height: 16),
              Text(message, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              Text('${c.score}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      )),
              Text('/ ${c.maxScore} points',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      )),
              const SizedBox(height: 8),
              Text('$found / ${c.total} titres trouvés',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Quitter'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _restart,
                      child: const Text('Rejouer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
