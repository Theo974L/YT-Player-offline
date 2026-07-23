import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/library_model.dart';
import '../data/models.dart';
import '../data/playlist_model.dart';
import '../data/video_model.dart';
import '../playback/player_service.dart';
import 'settings_screen.dart';
import 'video_player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddToPlaylist(BuildContext context, Track track) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddToPlaylistDialog(track: track),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryModel>();
    final vid = context.watch<VideoModel>();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Ma bibliothèque',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    tooltip: 'Paramètres',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.music_note, color: scheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${lib.tracks.length} '
                        '${lib.tracks.length > 1 ? "morceaux" : "morceau"} · '
                        '${formatSize(lib.totalBytes)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                tabs: [
                  const Tab(text: 'Musique', icon: Icon(Icons.headphones)),
                  Tab(
                    icon: const Icon(Icons.movie_outlined),
                    text: 'Vidéos'
                        '${vid.videos.isNotEmpty ? " (${vid.videos.length})" : ""}',
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              lib.tracks.isEmpty
                  ? _empty(context, Icons.library_music, 'Aucun morceau',
                      'Ajoute un morceau depuis l’onglet « Ajouter »')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: lib.tracks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final t = lib.tracks[i];
                        return _TrackTile(
                          track: t,
                          onTap: () => ctx
                              .read<PlayerService>()
                              .playQueue(lib.tracks, i),
                          onAddToPlaylist: () => _showAddToPlaylist(ctx, t),
                          onDelete: () => lib.delete(t),
                        );
                      },
                    ),
              vid.videos.isEmpty
                  ? _empty(context, Icons.movie_outlined, 'Aucune vidéo',
                      'Télécharge une vidéo en MP4 depuis l’onglet « Ajouter »')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: vid.videos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final v = vid.videos[i];
                        return _VideoTile(
                          video: v,
                          onTap: () => Navigator.of(ctx).push(
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(video: v),
                            ),
                          ),
                          onDelete: () => vid.delete(v),
                        );
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _empty(
      BuildContext context, IconData icon, String title, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: scheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final Video video;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _VideoTile({
    required this.video,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 56,
                  child: video.thumbnailPath != null
                      ? Image.file(File(video.thumbnailPath!), fit: BoxFit.cover)
                      : const Icon(Icons.movie_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (video.author != null)
                      Text(video.author!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      '${formatDuration(video.durationSec)} · ${formatSize(video.fileSizeBytes)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback onAddToPlaylist;
  final VoidCallback onDelete;
  const _TrackTile({
    required this.track,
    required this.onTap,
    required this.onAddToPlaylist,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: track.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: track.thumbnailUrl!,
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
                    Text(track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (track.artist != null)
                      Text(track.artist!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      '${formatDuration(track.durationSec)} · ${formatSize(track.fileSizeBytes)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onAddToPlaylist,
                icon: const Icon(Icons.playlist_add),
                tooltip: 'Ajouter à une playlist',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddToPlaylistDialog extends StatefulWidget {
  final Track track;
  const _AddToPlaylistDialog({required this.track});

  @override
  State<_AddToPlaylistDialog> createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<_AddToPlaylistDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<PlaylistModel>();
    return AlertDialog(
      title: const Text('Ajouter à une playlist'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...model.playlists.map(
              (pl) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.queue_music),
                title: Text(pl.name),
                onTap: () {
                  model.addTrack(pl.id, widget.track.id);
                  Navigator.pop(context);
                },
              ),
            ),
            const Divider(),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Nouvelle playlist…'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        TextButton(
          onPressed: () {
            model.createAndAddTrack(_controller.text, widget.track.id);
            Navigator.pop(context);
          },
          child: const Text('Créer et ajouter'),
        ),
      ],
    );
  }
}
