import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FilePathUtils {
  static Future<String> getAppDataDirectory() async {
    Directory appDir;

    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isDenied) {
          throw Exception('Storage permission denied');
        }
        appDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      } else if (Platform.isIOS) {
        appDir = await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows) {
        final appDataPath = Platform.environment['APPDATA'] ?? '';
        if (appDataPath.isEmpty) {
          appDir = await getApplicationDocumentsDirectory();
          appDir = Directory('${appDir.path}/BAMCLauncher');
        } else {
          appDir = Directory('$appDataPath/BAMCLauncher');
        }
      } else if (Platform.isMacOS) {
        final homePath = Platform.environment['HOME'] ?? '';
        if (homePath.isEmpty) {
          appDir = await getApplicationDocumentsDirectory();
          appDir = Directory('${appDir.path}/BAMCLauncher');
        } else {
          appDir = Directory('$homePath/Library/Application Support/BAMCLauncher');
        }
      } else if (Platform.isLinux) {
        final homePath = Platform.environment['HOME'] ?? '';
        if (homePath.isEmpty) {
          appDir = await getApplicationDocumentsDirectory();
          appDir = Directory('${appDir.path}/.config/BAMCLauncher');
        } else {
          appDir = Directory('$homePath/.config/BAMCLauncher');
        }
      } else {
        appDir = await getApplicationDocumentsDirectory();
        appDir = Directory('${appDir.path}/BAMCLauncher');
      }

      if (!appDir.existsSync()) {
        appDir.createSync(recursive: true);
      }

      return toCrossPlatformPath(appDir.path);
    } catch (e) {
      print('Failed to get app data directory: $e');
      final fallbackDir = Directory('.bamclauncher');
      if (!fallbackDir.existsSync()) {
        fallbackDir.createSync(recursive: true);
      }
      return toCrossPlatformPath(fallbackDir.path);
    }
  }

  static Future<String> getInstancesDirectory() async {
    final appDataDir = await getAppDataDirectory();
    final instancesDir = Directory('$appDataDir/instances');

    if (!instancesDir.existsSync()) {
      instancesDir.createSync(recursive: true);
    }

    return toCrossPlatformPath(instancesDir.path);
  }

  static Future<String> getPacksDirectory() async {
    final appDataDir = await getAppDataDirectory();
    final packsDir = Directory('$appDataDir/packs');

    if (!packsDir.existsSync()) {
      packsDir.createSync(recursive: true);
    }

    return toCrossPlatformPath(packsDir.path);
  }

  static Future<String> getJavaDirectory() async {
    final appDataDir = await getAppDataDirectory();
    final javaDir = Directory('$appDataDir/java');

    if (!javaDir.existsSync()) {
      javaDir.createSync(recursive: true);
    }

    return toCrossPlatformPath(javaDir.path);
  }

  static Future<String> getLogsDirectory() async {
    final appDataDir = await getAppDataDirectory();
    final logsDir = Directory('$appDataDir/logs');

    if (!logsDir.existsSync()) {
      logsDir.createSync(recursive: true);
    }

    return toCrossPlatformPath(logsDir.path);
  }

  static Future<String> getCrashRecordsDirectory() async {
    final appDataDir = await getAppDataDirectory();
    final crashRecordsDir = Directory('$appDataDir/crash_records');

    if (!crashRecordsDir.existsSync()) {
      crashRecordsDir.createSync(recursive: true);
    }

    return toCrossPlatformPath(crashRecordsDir.path);
  }

  static Future<String> getTempDirectory() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final bamcTempDir = Directory('${tempDir.path}/BAMCLauncher');

      if (!bamcTempDir.existsSync()) {
        bamcTempDir.createSync(recursive: true);
      }

      return toCrossPlatformPath(bamcTempDir.path);
    } catch (e) {
      print('Failed to get temp directory: $e');
      final systemTemp = Directory.systemTemp;
      final bamcTempDir = Directory('${systemTemp.path}/BAMCLauncher');
      if (!bamcTempDir.existsSync()) {
        bamcTempDir.createSync(recursive: true);
      }
      return toCrossPlatformPath(bamcTempDir.path);
    }
  }

  static String toCrossPlatformPath(String path) {
    if (Platform.isWindows) {
      return path.replaceAll('\\', '/');
    }
    return path;
  }

  static String toPlatformPath(String path) {
    if (Platform.isWindows) {
      return path.replaceAll('/', '\\');
    }
    return path;
  }

  static Future<void> fixFilePermissions(String filePath) async {
    if (Platform.isLinux || Platform.isMacOS) {
      final file = File(filePath);
      if (file.existsSync()) {
        try {
          await Process.run('chmod', ['+x', filePath]);
        } catch (e) {
          print('Failed to fix permissions for $filePath: $e');
        }
      }
    }
  }

  static Future<void> fixDirectoryPermissions(String dirPath) async {
    if (Platform.isLinux || Platform.isMacOS) {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        try {
          await Process.run('chmod', ['-R', '755', dirPath]);
        } catch (e) {
          print('Failed to fix directory permissions for $dirPath: $e');
        }
      }
    }
  }

  static Future<void> safeDeleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      print('Failed to delete file $filePath: $e');
    }
  }

  static Future<void> safeDeleteDirectory(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      print('Failed to delete directory $dirPath: $e');
    }
  }

  static Future<void> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      final destinationFile = File(destinationPath);

      if (sourceFile.existsSync()) {
        final destinationDir = destinationFile.parent;
        if (!destinationDir.existsSync()) {
          destinationDir.createSync(recursive: true);
        }

        await sourceFile.copy(destinationPath);
        await fixFilePermissions(destinationPath);
      }
    } catch (e) {
      print('Failed to copy file $sourcePath to $destinationPath: $e');
      throw e;
    }
  }

  static Future<void> moveFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      final destinationFile = File(destinationPath);

      if (sourceFile.existsSync()) {
        final destinationDir = destinationFile.parent;
        if (!destinationDir.existsSync()) {
          destinationDir.createSync(recursive: true);
        }

        await sourceFile.rename(destinationPath);
        await fixFilePermissions(destinationPath);
      }
    } catch (e) {
      print('Failed to move file $sourcePath to $destinationPath: $e');
      await copyFile(sourcePath, destinationPath);
      await safeDeleteFile(sourcePath);
    }
  }

  static Future<String> readFileWithEncoding(String filePath, {Encoding encoding = utf8}) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File not found: $filePath');
      }

      return await file.readAsString(encoding: encoding);
    } catch (e) {
      print('Failed to read file $filePath with encoding $encoding: $e');

      if (encoding != utf8) {
        try {
          final file = File(filePath);
          return await file.readAsString(encoding: utf8);
        } catch (utf8Error) {
          print('Failed to read file $filePath with UTF-8 encoding: $utf8Error');
          final file = File(filePath);
          return await file.readAsString(encoding: latin1);
        }
      }

      rethrow;
    }
  }

  static Future<void> writeFileWithEncoding(String filePath, String content, {Encoding encoding = utf8}) async {
    try {
      final file = File(filePath);
      final dir = file.parent;
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      await file.writeAsString(content, encoding: encoding);
    } catch (e) {
      print('Failed to write file $filePath: $e');
      throw e;
    }
  }

  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final stat = await file.stat();
        return stat.size;
      }
      return 0;
    } catch (e) {
      print('Failed to get file size for $filePath: $e');
      return 0;
    }
  }

  static Future<int> getDirectorySize(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) {
        return 0;
      }

      int totalSize = 0;
      final List<FileSystemEntity> entities = await dir.list(recursive: true).toList();

      for (final entity in entities) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      print('Failed to get directory size for $dirPath: $e');
      return 0;
    }
  }

  static String formatFileSize(int size) {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  static bool fileExists(String filePath) {
    final file = File(filePath);
    return file.existsSync();
  }

  static bool directoryExists(String dirPath) {
    final dir = Directory(dirPath);
    return dir.existsSync();
  }

  static String getFileName(String filePath) {
    final file = File(filePath);
    return file.uri.pathSegments.last;
  }

  static String getFileExtension(String filePath) {
    final fileName = getFileName(filePath);
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot + 1).toLowerCase();
    }
    return '';
  }

  static String getFileNameWithoutExtension(String filePath) {
    final fileName = getFileName(filePath);
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      return fileName.substring(0, lastDot);
    }
    return fileName;
  }
}
