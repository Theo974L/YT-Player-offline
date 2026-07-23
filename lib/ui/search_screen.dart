import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/library_model.dart';
import '../data/models.dart';
import '../data/video_model.dart';
import '../data/youtube_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _searched = false;
  List<SearchResult> _results = [];
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _looksLikeUrl(String q) =>
      q.startsWith('http') || q.contains('youtube.com') || q.contains('youtu.be');

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _searched = true;
      _error = null;
      _results = [];
    });
    try {
      final yt = context.read<YoutubeService>();
      final results =
          _looksLikeUrl(q) ? [await yt.resolve(q)] : await yt.search(q);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _error = 'Recherche échouée');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ajouter un morceau',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Titre ou lien YouTube…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _controller.clear()),
                        ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (!_searched) {
      return _hint('Recherche un morceau',
          'Tape un titre, ou colle un lien YouTube.');
    }
    if (_results.isEmpty) {
      return _hint('Aucun résultat', 'Essaie d’autres mots-clés.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _ResultTile(result: _results[i]),
    );
  }

  Widget _hint(String title, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search,
              size: 64, color: scheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final SearchResult result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryModel>();
    final vid = context.watch<VideoModel>();
    final scheme = Theme.of(context).colorScheme;
    final downloadingAudio = lib.isDownloading(result.videoId);
    final downloadingVideo = vid.isDownloading(result.videoId);

    return Material(
      color: scheme.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 92,
                height: 56,
                child: result.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: result.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.music_note),
                      )
                    : const Icon(Icons.music_note),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (result.author != null)
                    Text(result.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                  if (result.durationSec > 0)
                    Text(formatDuration(result.durationSec),
                        style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: 4),
            _FormatDownloadButton(
              tooltip: 'Télécharger en MP3 (audio)',
              icon: Icons.headphones,
              downloading: downloadingAudio,
              onPressed: () => lib.download(result.videoId),
            ),
            _FormatDownloadButton(
              tooltip: 'Télécharger en MP4 (vidéo)',
              icon: Icons.movie_outlined,
              downloading: downloadingVideo,
              onPressed: () => vid.download(result.videoId),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatDownloadButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool downloading;
  final VoidCallback onPressed;

  const _FormatDownloadButton({
    required this.tooltip,
    required this.icon,
    required this.downloading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: downloading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                tooltip: tooltip,
                icon: Icon(icon, size: 20),
                onPressed: onPressed,
              ),
      ),
    );
  }
}
