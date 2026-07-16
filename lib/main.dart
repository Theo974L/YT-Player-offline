import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/database.dart';
import 'data/library_model.dart';
import 'data/playlist_model.dart';
import 'data/settings_model.dart';
import 'data/youtube_service.dart';
import 'playback/audio_handler.dart';
import 'playback/player_service.dart';
import 'ui/home_shell.dart';

late final AudioPlayerHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.laforge.ytoffline.audio',
      androidNotificationChannelName: 'Lecture',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  runApp(const YtOfflineApp());
}

class YtOfflineApp extends StatelessWidget {
  const YtOfflineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>(create: (_) => AppDatabase()),
        Provider<YoutubeService>(
          create: (_) => YoutubeService(),
          dispose: (_, s) => s.dispose(),
        ),
        ChangeNotifierProvider<LibraryModel>(
          create: (ctx) => LibraryModel(
            ctx.read<AppDatabase>(),
            ctx.read<YoutubeService>(),
          ),
        ),
        ChangeNotifierProvider<PlayerService>(
          create: (_) => PlayerService(audioHandler),
        ),
        ChangeNotifierProvider<PlaylistModel>(
          create: (ctx) => PlaylistModel(ctx.read<AppDatabase>()),
        ),
        ChangeNotifierProvider<SettingsModel>(create: (_) => SettingsModel()),
      ],
      child: Consumer<SettingsModel>(
        builder: (context, settings, _) => MaterialApp(
          title: 'Youtube Player',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,
          home: const HomeShell(),
        ),
      ),
    );
  }
}
