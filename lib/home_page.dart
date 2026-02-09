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
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://uapis.cn/api/v1/random/image'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
