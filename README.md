<p align="center">
  <img src="assets/banner.png" alt="Youtube Player Banner" width="100%">
</p>

<h1 align="center">
  Youtube Player
</h1>

<p align="center">
  A modern offline YouTube music player built with Flutter.
</p>

<p align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart)
![Android](https://img.shields.io/badge/Android-Supported-3DDC84?style=for-the-badge&logo=android)
![iOS](https://img.shields.io/badge/iOS-Supported-000000?style=for-the-badge&logo=apple)

</p>

---

# About

Youtube Player is an offline music player developed with Flutter.

The application allows users to search, download and listen to YouTube audio content locally.

The goal of this project is to provide a modern, fast and simple music experience across Android and iOS.

This documentation explains how to build the application from scratch.

---

# Preview
<p align="center">
  Modern interface designed with Flutter Material Design.
</p>

<br>

<table>
<tr>

<td align="center">
<img src="Screenshots/1.jpg" width="250">
<br>
<b>Home</b>
</td>

<td align="center">
<img src="Screenshots/2.jpg" width="250">
<br>
<b>Search</b>
</td>

<td align="center">
<img src="Screenshots/3.jpg" width="250">
<br>
<b>Player</b>
</td>

</tr>

<tr>

<td align="center">
<img src="Screenshots/4.jpg" width="250">
<br>
<b>Downloads</b>
</td>

<td align="center">
<img src="Screenshots/5.jpg" width="250">
<br>
<b>Library</b>
</td>

<td align="center">
<img src="Screenshots/6.jpg" width="250">
<br>
<b>Settings</b>
</td>

</tr>
</table>

---

# Features

- Offline music playback
- YouTube audio extraction
- Local music storage
- Download management
- Modern Material Design interface
- Android support
- iOS support
- Fast and lightweight application

---

# Application Architecture

```
Flutter UI

      ↓

Application Logic

      ↓

Services

      ↓

YouTube Extraction Layer

      ↓

Local Storage
```

---

# Table of Contents

- [Prerequisites](#prerequisites)
- [Clone the Project](#clone-the-project)
- [Android Build](#android-build)
- [iOS Build](#ios-build)
- [Troubleshooting](#troubleshooting)
- [Dependencies](#dependencies)
- [Disclaimer](#disclaimer)

---

# Prerequisites

## Flutter SDK

Install the **stable channel** version of Flutter.

Recommended installation path:

```
C:\src\flutter
```

Avoid paths containing spaces.

Add Flutter to your PATH:

```
flutter/bin
```

Verify installation:

```bash
flutter doctor
```

---

## Android Studio

Install Android Studio and configure the Android SDK.

Open:

```
SDK Manager
```

Enable:

- Android SDK Command-line Tools
- Android SDK Platform Tools
- NDK (Side by side)

Accept Android licenses:

```bash
flutter doctor --android-licenses
```

---

## iOS Requirements

Building an iOS application requires:

- macOS
- Xcode
- Apple Developer Account

Important:

> iOS applications cannot be built directly on Windows.

---

# Clone the Project

Clone the repository:

```bash
git clone https://github.com/Theo974L/Youtube-MP3-Mobile.git
```

Navigate to the project:

```bash
cd Youtube-MP3-Mobile
```

Install dependencies:

```bash
flutter pub get
```

---

## Windows Build Optimization

If your project is located inside:

```
Documents
```

and synchronized with OneDrive:

- Pause OneDrive synchronization
- Add the project folder to antivirus exclusions

This prevents slow or blocked Flutter builds.

---

# Android Build

## Run the application

Connect an Android device or start an emulator:

```bash
flutter run
```

---

## Generate Release APK

Build:

```bash
flutter build apk --release
```

Generated file:

```
build/app/outputs/flutter-apk/app-release.apk
```

Install:

1. Copy the APK to your Android device.
2. Open the file.
3. Allow installation from unknown sources if required.

---

## Generate Google Play Bundle

For Play Store publishing:

```bash
flutter build appbundle
```

Generated file:

```
build/app/outputs/bundle/release/app-release.aab
```

---

# iOS Build

## Build on macOS

Create an IPA:

```bash
flutter build ipa --release
```

Output:

```
build/ios/ipa/
```

Install directly on a connected iPhone:

```bash
flutter run --release
```

---

# Build iOS without a Mac

This repository includes:

```
codemagic.yaml
```

for cloud builds.

Steps:

1. Push the project to GitHub.
2. Create a Codemagic account.
3. Connect the repository.
4. Configure your Apple API Key.
5. Create the App ID:

```
com.laforge.ytOffline
```

6. Launch:

```
ios-release
```

workflow.

7. Download the generated IPA.
8. Install through TestFlight.

---

# Troubleshooting

| Problem | Solution |
|-|-|
| `flutter` command not found | Add Flutter to PATH |
| Android licenses missing | Run `flutter doctor --android-licenses` |
| NDK installation failed | Install NDK through Android Studio |
| `adb: failed to install` | Restart emulator or use USB |
| Gradle build very slow | Disable OneDrive synchronization |
| ADB over Wi-Fi slow | Use USB cable |

---

# Dependencies

Main technologies:

- Flutter
- Dart
- youtube_explode_dart

---

## YouTube Extraction Issue

If YouTube extraction stops working:

Update the dependency:

```bash
flutter pub upgrade youtube_explode_dart
```

---

# Project Structure

```
lib/
├── core/
├── data/
├── game/
├── playback/
├── ui/
└── main.dart

android/
ios/


README.md
```

---

# Disclaimer

This project is intended for **personal and educational use only**.

Users are responsible for complying with YouTube's Terms of Service and applicable copyright laws.

---

# Author

<p align="center">

<b>Theo Laforge</b>

<br>

GitHub:
<br>

https://github.com/Theo974L

</p>

---

<p align="center">

Made with Flutter

</p>