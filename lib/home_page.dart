import 'package:flutter/material.dart';
import 'game_server/download_game.dart';

class HomePage extends StatefulWidget {
  final Map<String, double> downloadProgress;
  final Map<String, bool> isDownloading;
  final Map<String, bool> downloadComplete;
  final Map<String, String> currentTask;
  final Function(MinecraftVersion) onDownload;

  const HomePage({
    super.key,
    required this.downloadProgress,
    required this.isDownloading,
    required this.downloadComplete,
    required this.currentTask,
    required this.onDownload,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final downloadingVersions = widget.isDownloading.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://uapis.cn/api/v1/random/image'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (downloadingVersions.isNotEmpty)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: _buildDownloadingCard(downloadingVersions.first),
          ),
      ],
    );
  }

  Widget _buildDownloadingCard(String versionId) {
    final progress = widget.downloadProgress[versionId] ?? 0.0;
    final currentTask = widget.currentTask[versionId] ?? '';

    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '正在下载: $versionId',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                minHeight: 6,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentTask,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
