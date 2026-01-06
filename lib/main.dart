import 'package:flutter/material.dart';
import 'game_server/game_download_page.dart';
import 'game_server/Setting_Page.dart';
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

  List<Widget> get _pages => [
    const HomePage(),
    const GameDownloadPage(),
    SettingPage(onThemeUpdated: widget.onThemeUpdated),
  ];

  final List<String> _titles = [
    'Home',
    'Game Download',
    'Setting',
  ];

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
              decoration: BoxDecoration(
                color: primaryColor,
              ),
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://img.xjh.me/random_img.php?return=302&type=bg&ctype=acg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
