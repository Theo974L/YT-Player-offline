# Guide d'installation — Youtube Player (Flutter)

Guide complet **à partir de zéro** pour builder l'app en **APK Android** et en **IPA iOS**.

---

## 0. Prérequis (Uniquement pour IOS)

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

## 1. Récupérer le projet

Clone le dépôt et installe les dépendances :
```
git clone <URL_DE_TON_REPO>
cd yt_offline_flutter
flutter pub get
```

> Astuce build Windows : projet sous `Documents` souvent synchronisé par OneDrive → mets OneDrive
> en pause + exclusion antivirus sur le dossier, pour éviter des builds lents/bloqués.

---

## 2. Android — APK

Lancer sur un appareil (dev, hot reload) :

**APK_RELEASE_HERE/app-release.apk**

> Sur Android : Appuyer sur app-release.apk 

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
