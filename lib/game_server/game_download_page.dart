import 'package:flutter/material.dart';
import 'download_game.dart';

class GameDownloadPage extends StatefulWidget {
  final Map<String, double> downloadProgress;
  final Map<String, bool> isDownloading;
  final Map<String, bool> downloadComplete;
  final Map<String, String> currentTask;
  final Function(MinecraftVersion) onDownload;

  const GameDownloadPage({
    super.key,
    required this.downloadProgress,
    required this.isDownloading,
    required this.downloadComplete,
    required this.currentTask,
    required this.onDownload,
  });

  @override
  State<GameDownloadPage> createState() => _GameDownloadPageState();
}

class _GameDownloadPageState extends State<GameDownloadPage> {
  late Future<List<MinecraftVersion>> _versionsFuture;

  @override
  void initState() {
    super.initState();
    _versionsFuture = GameList.getMinecraftVersions();
  }

  Future<void> _downloadVersion(MinecraftVersion version) async {
    widget.onDownload(version);
  }

  Widget _buildDownloadButton(MinecraftVersion version) {
    final isDownloading = widget.isDownloading[version.id] == true;
    final progress = widget.downloadProgress[version.id] ?? 0.0;
    final isComplete = widget.downloadComplete[version.id] == true;
    final currentTask = widget.currentTask[version.id] ?? '';

    if (isDownloading) {
      return SizedBox(
        width: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              color: const Color.fromARGB(255, 136, 51, 255),
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              currentTask,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    if (isComplete) {
      return ElevatedButton.icon(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.check),
        label: const Text('已下载'),
      );
    }

    return ElevatedButton(
      onPressed: () => _downloadVersion(version),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 136, 51, 255),
        foregroundColor: Colors.white,
      ),
      child: const Text('Download'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<MinecraftVersion>>(
        future: _versionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No versions available',
                style: TextStyle(fontSize: 16),
              ),
            );
          } else {
            final versions = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: versions.length,
              itemBuilder: (context, index) {
                final version = versions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      version.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Type: ${version.type}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Release Time: ${version.releaseTime.toString().split(' ').first}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: _buildDownloadButton(version),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
