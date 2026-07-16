# YT Offline — version Flutter (multiplateforme)

Réécriture Flutter/Dart de l'app native, **iOS-ready** (mais l'`.ipa` se build sur macOS
uniquement — voir plus bas). L'app Kotlin d'origine reste intacte dans le reste du repo.

## ⚠️ Partie 1 (livrée)
Fondation runnable : **base sqflite**, **extraction + recherche** (youtube_explode_dart),
**téléchargement** (audio m4a/AAC), **bibliothèque**, **lecture** (just_audio) + **mini-lecteur**.

**Partie 2 (à venir)** : playlists, lecteur plein écran (seekbar/shuffle/repeat),
lecture en arrière-plan + notification (audio_service).

## Stack
- `provider` — état / injection
- `sqflite` — base locale (pas de code-gen)
- `youtube_explode_dart` — extraction YouTube (Android **et** iOS)
- `just_audio` — lecture audio
- `cached_network_image` — miniatures

## Mise en route

1. Installe le SDK Flutter (stable) puis vérifie : `flutter doctor`.

2. Depuis ce dossier, génère les dossiers de plateforme (android/, ios/…) —
   `flutter create` **ne touche pas** aux fichiers déjà présents (`lib/`, `pubspec.yaml`) :
   ```
   flutter create . --org com.laforge --project-name yt_offline --platforms=android,ios
   ```

3. Récupère les dépendances :
   ```
   flutter pub get
   ```

4. **Permission Internet (Android)** — ajoute dans
   `android/app/src/main/AndroidManifest.xml`, juste avant `<application>` :
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```

5. Lance sur un appareil branché :
   ```
   flutter run
   ```
   ou construis l'APK :
   ```
   flutter build apk --release
   ```
   (APK dans `build/app/outputs/flutter-apk/app-release.apk`)

## iOS (.ipa) — rappel
Impossible sous Windows. Quand tu auras un Mac (Xcode) : `flutter build ipa`.
Sinon, un CI cloud (Codemagic / GitHub Actions macOS) peut le produire. Le code est déjà
cross-platform ; il faudra juste, pour l'iOS, ajouter `UIBackgroundModes: audio` dans
`ios/Runner/Info.plist` (utile surtout en partie 2 pour la lecture en fond).

## Notes
- Les fichiers audio sont dans le stockage privé de l'app (`.../music/<id>.m4a`),
  lus en interne par le lecteur (comme l'app native).
- `youtube_explode_dart`, comme toute lib d'extraction, peut casser quand YouTube change :
  faire `flutter pub upgrade youtube_explode_dart` le cas échéant.
- Je n'ai pas pu compiler ce projet de mon côté : au premier `flutter pub get`, si une
  version de dépendance coince, `flutter pub upgrade` règle en général la résolution.
- Usage strictement personnel (mêmes réserves CGU YouTube que la version native).

Akjsdhfkj2587224!