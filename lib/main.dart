import 'package:flutter/material.dart';
import 'home_page.dart';
import 'game_server/game_download_page.dart';
import 'game_server/Setting_Page.dart';
import 'game_server/download_game.dart';
import 'game_server/download_controller.dart';
import 'settings_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsManager().init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SettingsManager _settingsManager = SettingsManager();
  ThemeData _themeData = ThemeData(
    primarySwatch: Colors.deepPurple,
    useMaterial3: true,
  );

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final colorName = await _settingsManager.getThemeColor();
    final materialColor = _settingsManager.getMaterialColorByName(colorName);
    final brightness = ThemeData.estimateBrightnessForColor(materialColor);

    setState(() {
      _themeData = ThemeData(
        primarySwatch: materialColor,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: materialColor,
          brightness: brightness,
        ),
      );
    });
  }

  void _updateTheme() {
    _loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minecraft Launcher',
      theme: _themeData,
      home: MainPage(onThemeUpdated: _updateTheme),
    );
  }
}

class MainPage extends StatefulWidget {
  final VoidCallback onThemeUpdated;
  const MainPage({super.key, required this.onThemeUpdated});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final SettingsManager _settingsManager = SettingsManager();
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};
  final Map<String, bool> _downloadComplete = {};
  final Map<String, String> _currentTask = {};

  Future<void> _downloadVersion(MinecraftVersion version) async {
    if (_isDownloading[version.id] == true) return;

    await startDownloadVersion(
      context,
      version,
      _settingsManager,
      (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress[version.id] = progress.overallProgress;
            _currentTask[version.id] = progress.currentTask;
          });
        }
      },
      () {
        if (mounted) {
          setState(() {
            _isDownloading[version.id] = true;
            _downloadProgress[version.id] = 0.0;
            _downloadComplete[version.id] = false;
            _currentTask[version.id] = '准备下载...';
          });
        }
      },
      () {
        if (mounted) {
          setState(() {
            _isDownloading[version.id] = false;
            _downloadComplete[version.id] = true;
            _currentTask[version.id] = '下载完成';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${version.id} 下载完成!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      (error) {
        if (mounted) {
          setState(() {
            _isDownloading[version.id] = false;
            _currentTask[version.id] = '下载失败';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('下载失败: $error'), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  List<Widget> get _pages => [
    HomePage(
      downloadProgress: _downloadProgress,
      isDownloading: _isDownloading,
      downloadComplete: _downloadComplete,
      currentTask: _currentTask,
      onDownload: _downloadVersion,
    ),
    GameDownloadPage(
      downloadProgress: _downloadProgress,
      isDownloading: _isDownloading,
      downloadComplete: _downloadComplete,
      currentTask: _currentTask,
      onDownload: _downloadVersion,
    ),
    SettingPage(onThemeUpdated: widget.onThemeUpdated),
  ];

  final List<String> _titles = ['Home', 'Game Download', 'Setting'];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: const Text(
                'Minecraft Launcher',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: _currentIndex == 0,
              selectedTileColor: primaryColor.withValues(alpha: 0.1),
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Game Download'),
              selected: _currentIndex == 1,
              selectedTileColor: primaryColor.withValues(alpha: 0.1),
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Setting'),
              selected: _currentIndex == 2,
              selectedTileColor: primaryColor.withValues(alpha: 0.1),
              onTap: () => _onItemTapped(2),
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              label: const Text('Start Game'),
            )
          : null,
    );
  }
}
