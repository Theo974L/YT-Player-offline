<p align="center">
  <img src="assets/banner/banner.png" alt="Youtube Player Banner" width="100%">
</p>

<h1 align="center">Youtube Player Mobile</h1>

<p align="center">
A modern offline YouTube music player built with Flutter.
</p>

<p align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)
![Android](https://img.shields.io/badge/Android-Supported-3DDC84?style=for-the-badge&logo=android)
![iOS](https://img.shields.io/badge/iOS-Supported-000000?style=for-the-badge&logo=apple)
![License](https://img.shields.io/badge/License-Personal-blue?style=for-the-badge)

</p>

---

# About

Youtube Player is an offline music player developed with Flutter.

It allows you to download audio from YouTube and listen to your music locally on Android and iOS.

This guide explains how to build the application from scratch.

---

# Table of Contents

- [Prerequisites](#-prerequisites)
- [Clone the Project](#-clone-the-project)
- [Android](#-android)
- [iOS](#-ios)
- [Troubleshooting](#-troubleshooting)

---

# Features

- Offline playback
- YouTube audio extraction
- Fast downloads
- Material Design interface
- Android support
- iOS support

---

# Preview

> Replace these images with your own screenshots.

<p align="center">
<img src="Screenshots/1.jpg" width="250">
<img src="Screenshots/2.jpg" width="250">
<img src="Screenshots/3.jpg" width="250">
</p>
<p align="center">
<img src="Screenshots/4.jpg" width="250">
<img src="Screenshots/5.jpg" width="250">
<img src="Screenshots/6.jpg" width="250">
</p>
<p align="center">
<img src="Screenshots/7.jpg" width="250">
</p>

---

# Prerequisites

## Flutter SDK

Install the **stable** version of Flutter in a folder **without spaces**.

Example:

```
C:\src\flutter
```

Add:

```
flutter/bin
```

to your **PATH**, then verify your installation:

```bash
flutter doctor
```

---

## Android Studio

Install Android Studio and open:

```
SDK Manager
```

Enable:

- Android SDK Command-line Tools
- Android SDK Platform
- NDK (Side by side)

Accept Android licenses:

```bash
flutter doctor --android-licenses
```

---

## iOS

Building an iOS application requires:

- macOS
- Xcode
- Apple Developer Account

**Building iOS applications is not possible directly on Windows.**

---

# Clone the Project

Clone the repository:

```bash
git clone https://github.com/Theo974L/Youtube-MP3-Mobile.git
```

Go inside the project:

```bash
cd Youtube-MP3-Mobile
```

Install dependencies:

```bash
flutter pub get
```

> **Windows Tip**
>
> If your project is located inside the **Documents** folder and synchronized with OneDrive, pause OneDrive synchronization during builds and add the project folder to your antivirus exclusions.

---

# Android

Run the application:

```bash
flutter run
```

---

## Build Release APK

```bash
flutter build apk --release
```

Generated file:

```
build/app/outputs/flutter-apk/app-release.apk
```

Install it by opening the APK on your Android device.

---

## Google Play Bundle

```bash
flutter build appbundle
```

Generated file:

```
build/app/outputs/bundle/release/app-release.aab
```

---

# iOS

## Build on macOS

```bash
flutter build ipa --release
```

Generated file:

```
build/ios/ipa/
```

You can also deploy directly to a connected iPhone:

```bash
flutter run --release
```

---

## Build without a Mac (Codemagic)

This repository already contains a **codemagic.yaml** configuration.

Steps:

1. Push the project to GitHub.
2. Create a Codemagic account.
3. Connect your repository.
4. Configure your Apple API Key.
5. Create the App ID:

```
com.laforge.ytOffline
```

6. Launch the **ios-release** workflow.
7. Download the generated IPA.
8. Install using TestFlight.

---

# Troubleshooting

| Problem | Solution |
|----------|----------|
| `flutter` command not found | Add Flutter to PATH |
| Android licenses missing | `flutter doctor --android-licenses` |
| NDK installation failed | Install NDK directly from Android Studio |
| `adb: failed to install` | Cold Boot emulator or use USB |
| Slow Gradle build | Pause OneDrive & exclude project from antivirus |
| Slow ADB over Wi-Fi | Prefer USB connection |

---

# Dependencies

The application relies on:

- Flutter
- Dart
- youtube_explode_dart

If YouTube extraction stops working:

```bash
flutter pub upgrade youtube_explode_dart
```

---

# Disclaimer

This project is intended for **personal and educational use only**.

Users are responsible for complying with YouTube's Terms of Service and applicable copyright laws.

---

# Project Structure

```
lib/
├── models/
├── pages/
├── services/
├── widgets/
├── utils/
└── main.dart

android/
ios/
assets/
screenshots/
README.md
```

---

# Author

**Theo Laforge**

GitHub:

https://github.com/Theo974L

---

<p align="center">

Made with Flutter

</p>
