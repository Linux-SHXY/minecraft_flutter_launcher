import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

class MinecraftVersion {
  final String id;
  final String type;
  final String url;
  final DateTime time;
  final DateTime releaseTime;

  MinecraftVersion({
    required this.id,
    required this.type,
    required this.url,
    required this.time,
    required this.releaseTime,
  });

  factory MinecraftVersion.fromJson(Map<String, dynamic> json) {
    return MinecraftVersion(
      id: json['id'],
      type: json['type'],
      url: json['url'],
      time: DateTime.parse(json['time']),
      releaseTime: DateTime.parse(json['releaseTime']),
    );
  }
}

class MinecraftVersionManifest {
  final Map<String, String> latest;
  final List<MinecraftVersion> versions;

  MinecraftVersionManifest({required this.latest, required this.versions});

  factory MinecraftVersionManifest.fromJson(Map<String, dynamic> json) {
    return MinecraftVersionManifest(
      latest: Map<String, String>.from(json['latest']),
      versions: (json['versions'] as List<dynamic>)
          .map((version) => MinecraftVersion.fromJson(version))
          .toList(),
    );
  }
}

class DownloadSource {
  final String name;
  final String baseUrl;

  DownloadSource({required this.name, required this.baseUrl});
}

class DownloadTask {
  final String url;
  final String localPath;
  final int? expectedSize;
  final String? expectedHash;
  final String description;

  DownloadTask({
    required this.url,
    required this.localPath,
    this.expectedSize,
    this.expectedHash,
    required this.description,
  });

  bool get hasValidation => expectedSize != null || expectedHash != null;
}

class DownloadProgress {
  final String currentTask;
  final int completedTasks;
  final int totalTasks;
  final double taskProgress;
  final double overallProgress;

  DownloadProgress({
    required this.currentTask,
    required this.completedTasks,
    required this.totalTasks,
    required this.taskProgress,
    required this.overallProgress,
  });
}

class AssetObject {
  final String hash;
  final int size;
  final String localPath;
  final String sourcePath;

  AssetObject({
    required this.hash,
    required this.size,
    required this.localPath,
    required this.sourcePath,
  });
}

class GameList {
  static const String versionManifestUrl =
      'https://launchermeta.mojang.com/mc/game/version_manifest.json';

  static final List<DownloadSource> downloadSources = [
    DownloadSource(name: 'Mojang 官方源', baseUrl: 'https://launcher.mojang.com'),
    DownloadSource(
      name: 'BMCLAPI 镜像源',
      baseUrl: 'https://bmclapi2.bangbang93.com',
    ),
  ];

  static Future<List<MinecraftVersion>> getMinecraftVersions() async {
    try {
      final response = await http.get(Uri.parse(versionManifestUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final manifest = MinecraftVersionManifest.fromJson(jsonData);
        return manifest.versions;
      } else {
        throw Exception('Failed to load versions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  static Future<MinecraftVersion?> getLatestRelease() async {
    try {
      final versions = await getMinecraftVersions();
      final manifest = await getVersionManifest();

      return versions.firstWhere(
        (version) => version.id == manifest.latest['release'],
        orElse: () => versions.first,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<MinecraftVersionManifest> getVersionManifest() async {
    final response = await http.get(Uri.parse(versionManifestUrl));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return MinecraftVersionManifest.fromJson(jsonData);
    } else {
      throw Exception('Failed to load version manifest');
    }
  }

  static Future<String> getVersionJsonUrl(String versionId) async {
    final manifest = await getVersionManifest();
    final version = manifest.versions.firstWhere((v) => v.id == versionId);
    return version.url;
  }

  static Future<void> downloadVersion(
    String versionId,
    String downloadPath,
    Function(DownloadProgress) onProgress,
  ) async {
    try {
      onProgress(
        DownloadProgress(
          currentTask: '获取版本信息',
          completedTasks: 0,
          totalTasks: 100,
          taskProgress: 0.0,
          overallProgress: 0.0,
        ),
      );

      final versionJsonUrl = await getVersionJsonUrl(versionId);

      final versionDir = Directory('$downloadPath/versions/$versionId');
      if (!await versionDir.exists()) {
        await versionDir.create(recursive: true);
      }

      final versionJsonPath = '${versionDir.path}/$versionId.json';
      final versionJsonFile = File(versionJsonPath);

      if (!await versionJsonFile.exists()) {
        await _downloadWithRetry(
          versionJsonUrl,
          versionJsonPath,
          '版本 JSON 文件',
          (progress) {
            onProgress(
              DownloadProgress(
                currentTask: '版本 JSON 文件',
                completedTasks: 0,
                totalTasks: 100,
                taskProgress: progress,
                overallProgress: progress * 0.1,
              ),
            );
          },
        );
      }

      final versionJsonContent = await versionJsonFile.readAsString();
      final versionJson = json.decode(versionJsonContent);

      final List<DownloadTask> downloadTasks = [];

      downloadTasks.addAll(_parseLibraries(versionJson, downloadPath));
      downloadTasks.addAll(_parseAssets(versionJson, downloadPath));
      downloadTasks.add(_parseClientJar(versionJson, downloadPath, versionId));

      final totalTasks = downloadTasks.length;

      for (int i = 0; i < downloadTasks.length; i++) {
        final task = downloadTasks[i];

        onProgress(
          DownloadProgress(
            currentTask: task.description,
            completedTasks: i,
            totalTasks: totalTasks,
            taskProgress: 0.0,
            overallProgress: i / totalTasks,
          ),
        );

        if (!await File(task.localPath).exists() ||
            (task.hasValidation &&
                !await _validateFile(
                  task.localPath,
                  task.expectedSize,
                  task.expectedHash,
                ))) {
          await _downloadWithRetry(
            task.url,
            task.localPath,
            task.description,
            (progress) {
              onProgress(
                DownloadProgress(
                  currentTask: task.description,
                  completedTasks: i,
                  totalTasks: totalTasks,
                  taskProgress: progress,
                  overallProgress: (i + progress) / totalTasks,
                ),
              );
            },
            expectedSize: task.expectedSize,
            expectedHash: task.expectedHash,
          );
        }
      }

      final assetIndexId = versionJson['assetIndex']['id'];
      final assetIndexPath = '$downloadPath/assets/indexes/$assetIndexId.json';

      if (await File(assetIndexPath).exists()) {
        onProgress(
          DownloadProgress(
            currentTask: '解析资源对象',
            completedTasks: totalTasks,
            totalTasks: totalTasks + 1,
            taskProgress: 0.0,
            overallProgress: totalTasks / (totalTasks + 1),
          ),
        );

        final assetObjectTasks = await _parseAssetObjects(
          assetIndexPath,
          downloadPath,
        );

        if (assetObjectTasks.isNotEmpty) {
          final totalAssetTasks = totalTasks + assetObjectTasks.length;

          for (int i = 0; i < assetObjectTasks.length; i++) {
            final task = assetObjectTasks[i];

            onProgress(
              DownloadProgress(
                currentTask: task.description,
                completedTasks: totalTasks + i,
                totalTasks: totalAssetTasks,
                taskProgress: 0.0,
                overallProgress: (totalTasks + i) / totalAssetTasks,
              ),
            );

            if (!await File(task.localPath).exists() ||
                (task.hasValidation &&
                    !await _validateFile(
                      task.localPath,
                      task.expectedSize,
                      task.expectedHash,
                    ))) {
              await _downloadWithRetry(
                task.url,
                task.localPath,
                task.description,
                (progress) {
                  onProgress(
                    DownloadProgress(
                      currentTask: task.description,
                      completedTasks: totalTasks + i,
                      totalTasks: totalAssetTasks,
                      taskProgress: progress,
                      overallProgress:
                          (totalTasks + i + progress) / totalAssetTasks,
                    ),
                  );
                },
                expectedSize: task.expectedSize,
                expectedHash: task.expectedHash,
              );
            }
          }
        }
      }

      onProgress(
        DownloadProgress(
          currentTask: '下载完成',
          completedTasks: totalTasks,
          totalTasks: totalTasks,
          taskProgress: 1.0,
          overallProgress: 1.0,
        ),
      );
    } catch (e) {
      throw Exception('Failed to download version $versionId: $e');
    }
  }

  static List<DownloadTask> _parseLibraries(
    Map<String, dynamic> versionJson,
    String downloadPath,
  ) {
    final List<DownloadTask> tasks = [];
    final libraries = versionJson['libraries'] as List<dynamic>;

    for (final lib in libraries) {
      if (lib['rules'] != null) {
        if (!_checkRules(lib['rules'])) continue;
      }

      final downloads = lib['downloads'];
      if (downloads == null || downloads['artifact'] == null) continue;

      final artifact = downloads['artifact'];
      final libPath = artifact['path'];
      final url = artifact['url'];
      final size = artifact['size'];
      final sha1 = artifact['sha1'];

      final localPath = '$downloadPath/libraries/$libPath';

      tasks.add(
        DownloadTask(
          url: url,
          localPath: localPath,
          expectedSize: size,
          expectedHash: sha1,
          description: '库文件: ${path.basename(libPath)}',
        ),
      );
    }

    return tasks;
  }

  static List<DownloadTask> _parseAssets(
    Map<String, dynamic> versionJson,
    String downloadPath,
  ) {
    final List<DownloadTask> tasks = [];
    final assetIndex = versionJson['assetIndex'];

    if (assetIndex == null) return tasks;

    final assetIndexUrl = assetIndex['url'];
    final assetIndexId = assetIndex['id'];
    final assetIndexSha1 = assetIndex['sha1'];
    final assetIndexSize = assetIndex['size'];
    final assetIndexPath = '$downloadPath/assets/indexes/$assetIndexId.json';

    tasks.add(
      DownloadTask(
        url: assetIndexUrl,
        localPath: assetIndexPath,
        expectedSize: assetIndexSize,
        expectedHash: assetIndexSha1,
        description: '资源索引: $assetIndexId.json',
      ),
    );

    return tasks;
  }

  static Future<List<DownloadTask>> _parseAssetObjects(
    String assetIndexPath,
    String downloadPath,
  ) async {
    final List<DownloadTask> tasks = [];

    try {
      final assetIndexFile = File(assetIndexPath);
      if (!await assetIndexFile.exists()) {
        return tasks;
      }

      final assetIndexContent = await assetIndexFile.readAsString();
      final assetIndexJson =
          json.decode(assetIndexContent) as Map<String, dynamic>;

      final objects = assetIndexJson['objects'] as Map<String, dynamic>;
      final mapToResources = assetIndexJson['map_to_resources'] as bool?;
      final virtual = assetIndexJson['virtual'] as bool?;

      objects.forEach((key, value) {
        final objectInfo = value as Map<String, dynamic>;
        final hash = objectInfo['hash'] as String;
        final size = objectInfo['size'] as int;
        final hashPrefix = hash.substring(0, 2);

        String localPath;
        if (mapToResources == true) {
          localPath = '$downloadPath/resources/$key';
        } else if (virtual == true) {
          localPath = '$downloadPath/assets/virtual/legacy/$key';
        } else {
          localPath = '$downloadPath/assets/objects/$hashPrefix/$hash';
        }

        tasks.add(
          DownloadTask(
            url: 'https://resources.download.minecraft.net/$hashPrefix/$hash',
            localPath: localPath,
            expectedSize: size,
            expectedHash: hash,
            description: '资源: ${path.basename(key)}',
          ),
        );
      });
    } catch (e, st) {
      // 记录异常以便诊断，保持函数继续返回空任务列表
      stderr.writeln('解析资源索引失败: $e');
      stderr.writeln(st.toString());
    }

    return tasks;
  }

  static DownloadTask _parseClientJar(
    Map<String, dynamic> versionJson,
    String downloadPath,
    String versionId,
  ) {
    final downloads = versionJson['downloads'];
    if (downloads == null || downloads['client'] == null) {
      throw Exception(
        'Version JSON does not contain client download information',
      );
    }

    final client = downloads['client'];
    final url = client['url'];
    final size = client['size'];
    final sha1 = client['sha1'];
    final localPath = '$downloadPath/versions/$versionId/$versionId.jar';

    return DownloadTask(
      url: url,
      localPath: localPath,
      expectedSize: size,
      expectedHash: sha1,
      description: '游戏客户端: $versionId.jar',
    );
  }

  static bool _checkRules(List<dynamic> rules) {
    for (final rule in rules) {
      final action = rule['action'];
      if (action == 'allow') {
        if (rule['os'] != null) {
          final os = rule['os'];
          final osName = os['name'];
          if (osName == 'windows' && !Platform.isWindows) return false;
          if (osName == 'osx' && !Platform.isMacOS) return false;
          if (osName == 'linux' && !Platform.isLinux) return false;
        }
      } else if (action == 'disallow') {
        if (rule['os'] != null) {
          final os = rule['os'];
          final osName = os['name'];
          if (osName == 'windows' && Platform.isWindows) return false;
          if (osName == 'osx' && Platform.isMacOS) return false;
          if (osName == 'linux' && Platform.isLinux) return false;
        }
      }
    }
    return true;
  }

  static Future<void> _downloadWithRetry(
    String url,
    String localPath,
    String description,
    Function(double) onProgress, {
    int? expectedSize,
    String? expectedHash,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < maxRetries) {
      try {
        await _downloadFile(
          url,
          localPath,
          onProgress,
          expectedSize: expectedSize,
        );

        if (expectedHash != null) {
          final actualHash = await _calculateSha1(localPath);
          if (actualHash.toLowerCase() != expectedHash.toLowerCase()) {
            throw Exception('SHA1 校验失败: 期望 $expectedHash, 实际 $actualHash');
          }
        }

        return;
      } catch (e) {
        lastException = e as Exception;
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount));
        }
      }
    }

    throw Exception('$description 下载失败 (重试 $maxRetries 次后): $lastException');
  }

  static Future<void> _downloadFile(
    String url,
    String localPath,
    Function(double) onProgress, {
    int? expectedSize,
  }) async {
    final dir = Directory(path.dirname(localPath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }

      final contentLength = response.contentLength ?? expectedSize;
      final sink = file.openWrite();

      int downloadedBytes = 0;
      await response.stream
          .listen(
            (chunk) {
              sink.add(chunk);
              downloadedBytes += chunk.length;
              if (contentLength != null && contentLength > 0) {
                onProgress(downloadedBytes / contentLength);
              }
            },
            onDone: () => sink.close(),
            onError: (error) {
              sink.close();
              throw error;
            },
          )
          .asFuture();
    } finally {
      client.close();
    }
  }

  static Future<bool> _validateFile(
    String filePath, [
    int? expectedSize,
    String? expectedHash,
  ]) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    if (expectedSize != null) {
      final stat = await file.stat();
      if (stat.size != expectedSize) return false;
    }

    if (expectedHash != null) {
      final actualHash = await _calculateSha1(filePath);
      if (actualHash.toLowerCase() != expectedHash.toLowerCase()) return false;
    }

    return true;
  }

  static Future<String> _calculateSha1(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
}
