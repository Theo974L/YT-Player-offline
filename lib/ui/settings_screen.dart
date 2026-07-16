import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/settings_model.dart';

const String _coffeeUrl = 'https://buymeacoffee.com/elmoutardes';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
