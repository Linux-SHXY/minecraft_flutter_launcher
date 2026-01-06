import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  SharedPreferences? _prefs;

  static const String _keyThemeColor = 'theme_color';
  static const String _keyDownloadPath = 'download_path';

  static final List<ColorOption> availableColors = [
    ColorOption('Deep Purple', Colors.deepPurple, const Color.fromARGB(255, 136, 51, 255)),
    ColorOption('Blue', Colors.blue, const Color.fromARGB(255, 33, 150, 243)),
    ColorOption('Green', Colors.green, const Color.fromARGB(255, 76, 175, 80)),
    ColorOption('Orange', Colors.orange, const Color.fromARGB(255, 255, 152, 0)),
    ColorOption('Red', Colors.red, const Color.fromARGB(255, 244, 67, 54)),
    ColorOption('Pink', Colors.pink, const Color.fromARGB(255, 233, 30, 99)),
    ColorOption('Teal', Colors.teal, const Color.fromARGB(255, 0, 150, 136)),
  ];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<String> getThemeColor() async {
    await init();
    return _prefs?.getString(_keyThemeColor) ?? 'Deep Purple';
  }

  Future<void> setThemeColor(String colorName) async {
    await init();
    await _prefs?.setString(_keyThemeColor, colorName);
  }

  MaterialColor getMaterialColorByName(String colorName) {
    return availableColors.firstWhere(
      (c) => c.name == colorName,
      orElse: () => availableColors[0],
    ).materialColor;
  }

  Future<String> getDownloadPath() async {
    await init();
    return _prefs?.getString(_keyDownloadPath) ?? '';
  }

  Future<void> setDownloadPath(String path) async {
    await init();
    await _prefs?.setString(_keyDownloadPath, path);
  }

  Future<void> clearDownloadPath() async {
    await init();
    await _prefs?.remove(_keyDownloadPath);
  }
}

class ColorOption {
  final String name;
  final MaterialColor materialColor;
  final Color displayColor;

  ColorOption(this.name, this.materialColor, this.displayColor);
}
