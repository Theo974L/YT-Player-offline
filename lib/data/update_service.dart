import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String _repo = 'Theo974L/Youtube-MP3-Mobile';

/// Une mise à jour disponible sur GitHub Releases.
class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final int apkSizeBytes;

  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.apkSizeBytes,
  });
}

/// Vérifie et télécharge les mises à jour depuis les Releases GitHub du dépôt.
/// Le nom de la Release doit contenir un tag de version (ex: "v1.2.0") et
/// avoir un fichier .apk en pièce jointe.
class UpdateService {
  Future<UpdateInfo?> checkForUpdate() async {
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$_repo/releases/latest'),
      headers: const {'Accept': 'application/vnd.github+json'},
    );
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, Object?>;
    final tagName = json['tag_name'] as String?;
    if (tagName == null) return null;
    final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;

    final assets = (json['assets'] as List?)?.cast<Map<String, Object?>>() ?? [];
    Map<String, Object?>? apkAsset;
    for (final a in assets) {
      final name = a['name'] as String?;
      if (name != null && name.toLowerCase().endsWith('.apk')) {
        apkAsset = a;
        break;
      }
    }
    if (apkAsset == null) return null;

    final packageInfo = await PackageInfo.fromPlatform();
    if (!_isNewer(latestVersion, packageInfo.version)) return null;

    return UpdateInfo(
      version: latestVersion,
      downloadUrl: apkAsset['browser_download_url'] as String,
      releaseNotes: (json['body'] as String?)?.trim() ?? '',
      apkSizeBytes: (apkAsset['size'] as num?)?.toInt() ?? 0,
    );
  }

  /// Compare deux versions "x.y.z" (segments manquants traités comme 0).
  bool _isNewer(String latest, String current) {
    final l = latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final c = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (var i = 0; i < l.length || i < c.length; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv != cv) return lv > cv;
    }
    return false;
  }

  /// Télécharge l'APK dans le cache de l'app. [onProgress] : 0.0 -> 1.0.
  Future<File> downloadApk(
    UpdateInfo info, {
    void Function(double? progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'update_${info.version}.apk'));

    final request = http.Request('GET', Uri.parse(info.downloadUrl));
    final response = await http.Client().send(request);
    final total = response.contentLength ?? info.apkSizeBytes;

    var received = 0;
    final sink = file.openWrite();
    await for (final chunk in response.stream) {
      received += chunk.length;
      sink.add(chunk);
      if (onProgress != null) {
        onProgress(total > 0 ? received / total : null);
      }
    }
    await sink.flush();
    await sink.close();

    return file;
  }
}
