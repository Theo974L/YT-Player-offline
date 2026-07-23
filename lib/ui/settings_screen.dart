import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/backup_service.dart';
import '../data/library_model.dart';
import '../data/settings_model.dart';

const String _coffeeUrl = 'https://buymeacoffee.com/elmoutardes';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _openCoffee(BuildContext context) async {
    try {
      await launchUrl(Uri.parse(_coffeeUrl),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir le lien.')),
        );
      }
    }
  }

  Future<void> _export(BuildContext context) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await context.read<BackupService>().exportLibrary();
      messenger.showSnackBar(SnackBar(
        content: Text(path == null
            ? 'Export annulé'
            : 'Bibliothèque exportée avec succès'),
      ));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Échec de l’export de la bibliothèque')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import(BuildContext context) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final library = context.read<LibraryModel>();
    try {
      final result = await context.read<BackupService>().importLibrary();
      if (result == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Import annulé')));
      } else {
        await library.refresh();
        messenger.showSnackBar(SnackBar(
          content: Text(
              '${result.added} morceau(x) importé(s)'
              '${result.skipped > 0 ? ", ${result.skipped} déjà présent(s)" : ""}'),
        ));
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Échec de l’import : fichier invalide')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          _sectionTitle(context, 'Apparence'),
          RadioListTile<ThemeMode>(
            title: const Text('Système'),
            subtitle: const Text('Suit le réglage du téléphone'),
            value: ThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (m) => settings.setThemeMode(m!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Clair'),
            value: ThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (m) => settings.setThemeMode(m!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Sombre'),
            value: ThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (m) => settings.setThemeMode(m!),
          ),

          const Divider(),
          _sectionTitle(context, 'Accessibilité'),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'L’app suit automatiquement la taille de police et le contraste '
              'définis dans les réglages de ton téléphone, et les boutons sont '
              'annotés pour les lecteurs d’écran (TalkBack / VoiceOver).',
            ),
          ),

          const Divider(),
          _sectionTitle(context, 'Bibliothèque'),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Sauvegarde tes morceaux (fichiers + infos) dans une archive, '
              'ou restaure-les sur un autre appareil.',
            ),
          ),
          ListTile(
            leading: _busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.upload_file, color: scheme.primary),
            title: const Text('Exporter la bibliothèque'),
            subtitle: const Text('Crée une archive .zip de tes morceaux'),
            enabled: !_busy,
            onTap: () => _export(context),
          ),
          ListTile(
            leading: _busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.download_for_offline, color: scheme.primary),
            title: const Text('Importer une bibliothèque'),
            subtitle: const Text('Restaure des morceaux depuis une archive .zip'),
            enabled: !_busy,
            onTap: () => _import(context),
          ),

          const Divider(),
          _sectionTitle(context, 'Soutenir'),
          ListTile(
            leading: Icon(Icons.local_cafe, color: scheme.primary),
            title: const Text('Buy me a coffee'),
            subtitle: const Text('Soutiens le développement ☕'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _openCoffee(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
}
