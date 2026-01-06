import 'package:flutter/material.dart';
import 'download_game.dart';
import '../settings_manager.dart';

class GameDownloadPage extends StatefulWidget {
  const GameDownloadPage({super.key});

  @override
  State<GameDownloadPage> createState() => _GameDownloadPageState();
}

class _GameDownloadPageState extends State<GameDownloadPage> {
  final SettingsManager _settingsManager = SettingsManager();
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};
  final Map<String, bool> _downloadComplete = {};

  Future<void> _downloadVersion(MinecraftVersion version) async {
    if (_isDownloading[version.id] == true) return;

    final downloadPath = await _settingsManager.getDownloadPath();
    if (downloadPath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先在设置中设置游戏下载目录'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isDownloading[version.id] = true;
      _downloadProgress[version.id] = 0.0;
      _downloadComplete[version.id] = false;
    });

    try {
      await GameList.downloadVersion(
        version.id,
        downloadPath,
        (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress[version.id] = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading[version.id] = false;
          _downloadComplete[version.id] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${version.id} 下载完成!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading[version.id] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDownloadButton(MinecraftVersion version) {
    final isDownloading = _isDownloading[version.id] == true;
    final progress = _downloadProgress[version.id] ?? 0.0;
    final isComplete = _downloadComplete[version.id] == true;

    if (isDownloading) {
      return SizedBox(
        width: 120,
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
        future: GameList.getMinecraftVersions(),
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
