import 'package:flutter/material.dart';
import 'download_game.dart';
import '../settings_manager.dart';

Future<void> startDownloadVersion(
  BuildContext context,
  MinecraftVersion version,
  SettingsManager settingsManager,
  void Function(DownloadProgress) onProgress,
  VoidCallback onStart,
  VoidCallback onComplete,
  void Function(Object) onError,
  {int concurrency = 6, int maxRetries = 3}) async {
  final downloadPath = await settingsManager.getDownloadPath();
  if (downloadPath.isEmpty) {
    onError('请先在设置中设置游戏下载目录');
    return;
  }

  onStart();

  try {
    await GameList.downloadVersion(version.id, downloadPath, (progress) {
      onProgress(progress);
    }, concurrency: concurrency, maxRetries: maxRetries);

    onComplete();
  } catch (e) {
    onError(e);
  }
}
