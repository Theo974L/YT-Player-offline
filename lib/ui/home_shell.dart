import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../data/library_model.dart';
import '../data/update_model.dart';
import '../data/video_model.dart';
import 'game_home_screen.dart';
import 'library_screen.dart';
import 'mini_player.dart';
import 'playlists_screen.dart';
import 'search_screen.dart';
import 'update_banner.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Notification média (Android 13+ / iOS) : demandée une fois au démarrage.
    Permission.notification.request();
  }

  @override
  Widget build(BuildContext context) {
    // Messages (téléchargement terminé / erreur) -> SnackBar.
    final message = context.select<LibraryModel, String?>((m) => m.message);
    final videoMessage = context.select<VideoModel, String?>((m) => m.message);
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        context.read<LibraryModel>().consumeMessage();
      });
    }
    if (videoMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(videoMessage)));
        context.read<VideoModel>().consumeMessage();
      });
    }
    final updateMessage = context.select<UpdateModel, String?>((m) => m.message);
    if (updateMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(updateMessage)));
        context.read<UpdateModel>().consumeMessage();
      });
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const UpdateBanner(),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  LibraryScreen(),
                  PlaylistsScreen(),
                  GameHomeScreen(),
                  SearchScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Bibliothèque',
              ),
              NavigationDestination(
                icon: Icon(Icons.queue_music_outlined),
                selectedIcon: Icon(Icons.queue_music),
                label: 'Playlists',
              ),
              NavigationDestination(
                icon: Icon(Icons.quiz_outlined),
                selectedIcon: Icon(Icons.quiz),
                label: 'Jeu',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: 'Ajouter',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
