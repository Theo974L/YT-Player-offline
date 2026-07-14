# 🎵 YT Offline Player — App perso Android

Application Android personnelle permettant de télécharger des pistes audio
depuis YouTube pour une écoute **hors ligne**, avec un lecteur intégré (play/pause/next/previous).

> ⚠️ **Note légale** : ce projet utilise une librairie d'extraction non officielle de YouTube.
> Cela viole les conditions d'utilisation de YouTube (même pour un usage strictement privé,
> non publié, non commercial). Le risque est contractuel, pas destiné à la distribution.
> Projet gardé strictement personnel, non publié sur le Play Store, non partagé publiquement.

---

## 🎯 Objectif

- Rechercher / coller un lien YouTube
- Extraire l'audio et le stocker en local (téléchargement)
- Gérer une bibliothèque de morceaux téléchargés
- Lecteur audio avec contrôle play/pause/next/previous, notification media, lecture en fond

---

## 🧱 Stack technique

| Domaine | Choix | Pourquoi |
|---|---|---|
| Langage | **Kotlin** | Standard moderne Android |
| UI | **Jetpack Compose** | UI déclarative, plus rapide à itérer |
| Architecture | **MVVM** + `ViewModel` + `StateFlow` | Standard recommandé par Google |
| Injection de dépendances | **Hilt** | Intégration simple avec Compose/Android |
| Lecture audio | **Media3 (ExoPlayer)** | Gère nativement play/pause/next/prev, notifications média, lecture background |
| Extraction YouTube | **NewPipeExtractor** (ou équivalent) | Librairie d'extraction la plus maintenue, pas de clé API officielle nécessaire |
| Téléchargement | **WorkManager** | Téléchargements fiables même si l'app est fermée/tuée |
| Stockage local des métadonnées | **Room** | Base de données locale (titre, artiste, chemin fichier, durée...) |
| Stockage fichiers audio | Stockage interne de l'app (`filesDir`) | Pas besoin de permissions storage externes sur Android récent |
| Navigation | **Navigation Compose** | Standard pour Compose |

---

## 🗂️ Architecture du projet (suggestion)

```
app/
 ├── data/
 │    ├── local/           # Room (entities, DAO, database)
 │    ├── remote/          # Wrapper autour de NewPipeExtractor
 │    ├── download/        # WorkManager workers
 │    └── repository/      # Repository pattern (source unique de vérité)
 ├── domain/
 │    ├── model/           # Modèles métier (Track, PlaylistItem...)
 │    └── usecase/         # Cas d'usage (DownloadTrack, GetLibrary, etc.)
 ├── player/
 │    ├── PlaybackService.kt   # MediaSessionService (Media3)
 │    └── PlayerController.kt  # Abstraction play/pause/next/prev
 ├── ui/
 │    ├── search/          # Écran recherche/coller lien
 │    ├── library/         # Écran bibliothèque téléchargée
 │    ├── player/           # Écran lecteur (mini + plein écran)
 │    └── theme/
 └── di/                   # Modules Hilt
```

---

## ✅ Tâches à prévoir

### Phase 1 — Setup projet
- [x] Créer le projet Android Studio (Kotlin + Compose)
- [x] Configurer Hilt
- [x] Configurer Room (entité `Track`, DAO basique)
- [x] Ajouter la lib d'extraction YouTube (NewPipeExtractor via JitPack ou Maven local)
- [x] Ajouter Media3 (`media3-exoplayer`, `media3-session`)

### Phase 2 — Extraction & téléchargement
- [x] Écran "coller un lien YouTube"
- [x] Appel à la lib d'extraction → récupérer flux audio + métadonnées (titre, durée, thumbnail)
- [x] Worker `WorkManager` pour télécharger le flux audio vers stockage interne
- [x] Sauvegarde en base Room une fois le téléchargement terminé
- [x] Gestion des erreurs (lien invalide, vidéo indisponible, pas de flux audio)

### Phase 3 — Bibliothèque
- [x] Écran liste des morceaux téléchargés (Compose `LazyColumn`)
- [x] Suppression d'un morceau (fichier + entrée DB)
- [x] Affichage taille de stockage utilisée
- [x] Recherche/tri dans la bibliothèque

### Phase 4 — Lecteur audio
- [x] `MediaSessionService` avec ExoPlayer (Media3)
- [x] Contrôles : play/pause/next/previous
- [x] Gestion de la file de lecture (queue) à partir de la bibliothèque
- [x] Notification média système (contrôles depuis l'écran verrouillé)
- [x] Mini-lecteur persistant en bas de l'écran (Compose)
- [x] Écran plein écran avec seekbar, artwork, titre/artiste

### Phase 5 — Polish
- [x] Gestion des interruptions audio (appel téléphonique, autre app média)
- [x] Mode aléatoire / répétition
- [ ] Icône et nom d'app (usage perso)
- [x] Tests manuels sur device réel

### Phase 6 (optionnelle)
- [x] Playlists locales
- [ ] Import depuis plusieurs liens à la fois
- [x] Thème sombre/clair

---

## 📦 Dépendances clés (exemple `build.gradle.kts`)

```kotlin
dependencies {
    implementation("androidx.media3:media3-exoplayer:1.4.1")
    implementation("androidx.media3:media3-session:1.4.1")
    implementation("androidx.room:room-runtime:2.6.1")
    ksp("androidx.room:room-compiler:2.6.1")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")
    implementation("com.google.dagger:hilt-android:2.51.1")
    ksp("com.google.dagger:hilt-android-compiler:2.51.1")
    implementation("androidx.work:work-runtime-ktx:2.9.1")
    // Librairie d'extraction YouTube à ajouter séparément (JitPack)
}
```

---

## 🔒 Rappels
- App non publiée, usage strictement personnel
- Ne pas partager l'APK publiquement
- Se tenir informé des évolutions de la lib d'extraction (elle casse régulièrement suite aux changements côté YouTube)

## Preview
![alt text](Screenshot_20260714_182809_Youtube Player.jpg)

