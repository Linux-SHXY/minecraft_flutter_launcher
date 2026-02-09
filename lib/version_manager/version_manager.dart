import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

enum VersionType {
  installer,
  portable,
}

class VersionManager {
  static const String _versionTypeKey = 'version_type';
  static const String _portableFlagFile = 'portable.flag';

  Future<VersionType> detectVersionType() async {
    final executableDir = Directory(Platform.resolvedExecutable).parent;
    final portableFlagFile = File('${executableDir.path}/$_portableFlagFile');

    if (portableFlagFile.existsSync()) {
      await _saveVersionType(VersionType.portable);
      return VersionType.portable;
    }

    final prefs = await SharedPreferences.getInstance();
    final versionTypeStr = prefs.getString(_versionTypeKey);

    if (versionTypeStr != null) {
      return VersionType.values.byName(versionTypeStr);
    }

    await _saveVersionType(VersionType.installer);
    return VersionType.installer;
  }

  Future<void> _saveVersionType(VersionType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_versionTypeKey, type.name);
  }

  Future<String> getDataDirectory() async {
    final versionType = await detectVersionType();

    if (versionType == VersionType.portable) {
      final executableDir = Directory(Platform.resolvedExecutable).parent;
      final dataDir = Directory('${executableDir.path}/data');

      if (!dataDir.existsSync()) {
        dataDir.createSync(recursive: true);
      }

      return dataDir.path;
    } else {
      Directory appDir;

      if (Platform.isAndroid) {
        appDir = Directory('/storage/emulated/0/Android/data/com.bamclauncher/files');
      } else if (Platform.isIOS) {
        appDir = Directory('${Platform.environment['HOME']}/Library/Application Support/BAMCLauncher');
      } else if (Platform.isWindows) {
        appDir = Directory('${Platform.environment['APPDATA']}/BAMCLauncher');
      } else if (Platform.isMacOS) {
        appDir = Directory('${Platform.environment['HOME']}/Library/Application Support/BAMCLauncher');
      } else if (Platform.isLinux) {
        appDir = Directory('${Platform.environment['HOME']}/.config/BAMCLauncher');
      } else {
        appDir = Directory.current;
      }

      if (!appDir.existsSync()) {
        appDir.createSync(recursive: true);
      }

      return appDir.path;
    }
  }

  Future<void> createPortableFlag() async {
    final executableDir = Directory(Platform.resolvedExecutable).parent;
    final portableFlagFile = File('${executableDir.path}/$_portableFlagFile');

    if (!portableFlagFile.existsSync()) {
      portableFlagFile.createSync();
    }

    await _saveVersionType(VersionType.portable);
  }

  Future<void> removePortableFlag() async {
    final executableDir = Directory(Platform.resolvedExecutable).parent;
    final portableFlagFile = File('${executableDir.path}/$_portableFlagFile');

    if (portableFlagFile.existsSync()) {
      portableFlagFile.deleteSync();
    }

    await _saveVersionType(VersionType.installer);
  }

  Future<bool> isAutoUpdateSupported() async {
    final versionType = await detectVersionType();
    return versionType == VersionType.installer;
  }
}

