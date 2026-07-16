# Guide d'installation — Youtube Player (Flutter)

Guide complet **à partir de zéro** pour builder l'app en **APK Android** et en **IPA iOS**.

---

## 0. Prérequis (une seule fois)

1. **Flutter SDK** (canal stable). Installe-le dans un chemin **sans espaces** (ex. `C:\src\flutter`),
   ajoute `...\flutter\bin` au **PATH**, puis vérifie :
   ```
   flutter doctor
   ```
2. **Android Studio** (fournit le SDK Android). Dans *SDK Manager → SDK Tools*, coche :
   - « Android SDK Command-line Tools »
   - « NDK (Side by side) » (la version demandée par le build, ex. `28.2.x`)
   Puis accepte les licences :
   ```
   flutter doctor --android-licenses
   ```
3. (Pour iOS uniquement) un **Mac avec Xcode** + un **compte Apple Developer** (99 €/an pour un `.ipa` installable).
   👉 **L'iOS ne se build PAS sous Windows** — voir la section iOS.

---

## 1. Préparer le projet

Depuis le dossier du projet :
```
flutter create . --org com.laforge --project-name yt_offline --platforms=android,ios
flutter pub get
```

Génère l'icône de l'app (place ton logo 1024×1024 en `assets/icon/app_icon.png`) :
```
dart run flutter_launcher_icons
```

> Astuce : projet sous `Documents` = souvent synchronisé par OneDrive → mets OneDrive en pause
> et ajoute une exclusion antivirus sur le dossier pour éviter des builds lents/bloqués.

---

## 2. Android — APK

Lancer sur un appareil/émulateur (dev, hot reload) :
```
flutter run
```

Construire l'**APK release** :
```
flutter build apk --release
```
→ `build\app\outputs\flutter-apk\app-release.apk`

APK **plus léger** (un par architecture — prends `arm64-v8a` pour un tél récent) :
```
flutter build apk --release --split-per-abi
```

Pour le **Play Store** (App Bundle, pas APK) :
```
flutter build appbundle --release
```
→ `build\app\outputs\bundle\release\app-release.aab`

**Installer l'APK** : copie le fichier sur le tél (câble USB conseillé) et ouvre-le.
Sur Samsung : autorise « Installer des applis inconnues » pour ton explorateur de fichiers.

> Signature : par défaut Flutter signe le release avec la **clé debug** — suffisant pour un usage perso.
> Pour publier, il faut ta propre **keystore** (voir doc Flutter « Signing the app »).

---

## 3. iOS — IPA (nécessite macOS)

### Option A — tu as un Mac
```
flutter build ipa --release
```
→ `build/ios/ipa/*.ipa` (Xcode + compte Apple Developer requis pour signer).
Ou, iPhone branché en USB : `flutter run --release` installe directement.

### Option B — pas de Mac : build dans le cloud (Codemagic)
Le fichier `codemagic.yaml` est déjà à la racine. Étapes :
1. Pousse le projet sur **GitHub**.
2. Crée un compte **codemagic.io**, connecte le repo.
3. Dans Codemagic → *Team → Integrations → App Store Connect* : ajoute une **clé API**
   (générée sur App Store Connect → *Users and Access → Integrations*), nommée **`CodemagicApiKey`**.
4. Déclare l'App ID `com.laforge.ytOffline` sur developer.apple.com et crée la fiche app sur App Store Connect.
5. Lance le workflow **`ios-release`** → récupère le `.ipa` (artifacts + email).
6. Installe via **TestFlight**.

---

## 4. Dépannage rapide

| Problème | Solution |
|---|---|
| `flutter` non reconnu | Ajouter `...\flutter\bin` au PATH, rouvrir le terminal |
| Échec install NDK / zip corrompu | Installer le NDK via Android Studio (SDK Tools), pas via Gradle |
| `adb: failed to install` (émulateur) | Cold Boot de l'émulateur, ou passer par un vrai tél en USB |
| Install très lente en Wi-Fi (ADB) | Utiliser le **câble USB** |
| Build Gradle lent/bloqué | Pause OneDrive + exclusion antivirus sur le dossier |

---

Usage strictement personnel. L'extraction YouTube dépend de `youtube_explode_dart` :
si l'extraction casse un jour, faire `flutter pub upgrade youtube_explode_dart`.
