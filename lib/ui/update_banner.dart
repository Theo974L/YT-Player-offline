import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/update_model.dart';

/// Bandeau "Une nouvelle version est disponible", affiché quand une mise à
/// jour a été détectée sur les Releases GitHub.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final update = context.watch<UpdateModel>();
    final info = update.available;
    if (info == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            Icon(Icons.system_update, color: scheme.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Une nouvelle version est disponible (v${info.version})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (update.downloading)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: LinearProgressIndicator(value: update.progress),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (update.downloading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              FilledButton.tonal(
                onPressed: update.downloadAndInstall,
                child: const Text('Mettre à jour'),
              ),
          ],
        ),
      ),
    );
  }
}
