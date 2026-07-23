import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';

import 'update_service.dart';

/// État de la vérification / du téléchargement de mise à jour (ChangeNotifier).
class UpdateModel extends ChangeNotifier {
  final UpdateService _service;
  UpdateModel(this._service);

  UpdateInfo? available;
  bool downloading = false;
  double? progress;
  String? message;

  Future<void> checkNow() async {
    try {
      available = await _service.checkForUpdate();
      notifyListeners();
    } catch (_) {
      // Échec silencieux : la vérification de mise à jour n'est jamais bloquante.
    }
  }

  Future<void> downloadAndInstall() async {
    final info = available;
    if (info == null || downloading) return;
    downloading = true;
    progress = null;
    notifyListeners();
    try {
      final file = await _service.downloadApk(
        info,
        onProgress: (p) {
          progress = p;
          notifyListeners();
        },
      );
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        message = 'Impossible de lancer l’installation : ${result.message}';
      }
    } catch (_) {
      message = 'Échec du téléchargement de la mise à jour';
    } finally {
      downloading = false;
      notifyListeners();
    }
  }

  void consumeMessage() {
    message = null;
  }
}
