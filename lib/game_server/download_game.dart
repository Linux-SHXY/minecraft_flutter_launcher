import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
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
    Function(DownloadProgress) onProgress, {
    int concurrency = 6,
    int maxRetries = 3,
  }) async {
    try {
      onProgress(DownloadProgress(
        currentTask: '开始下载',
        completedTasks: 0,
        totalTasks: 1,
        taskProgress: 0.0,
        overallProgress: 0.0,
      ));

      final versionJsonUrl = await getVersionJsonUrl(versionId);

      final versionDir = Directory('$downloadPath/versions/$versionId');
      if (!await versionDir.exists()) await versionDir.create(recursive: true);

      final versionJsonPath = '${versionDir.path}/$versionId.json';
      final versionJsonFile = File(versionJsonPath);

      // 简化：只保证存在版本 JSON，不做复杂校验
        if (!await versionJsonFile.exists()) {
        await _downloadFileSimpleBytes(versionJsonUrl, versionJsonPath, (chunk, total) {
          // chunk is bytes downloaded since last callback; we don't expose per-file cumulative here,
          // just provide a simple progress estimate if total is known
          onProgress(DownloadProgress(
            currentTask: '下载版本信息',
            completedTasks: 0,
            totalTasks: 4,
            taskProgress: total != null && total > 0 ? chunk / total : 0.0,
            overallProgress: total != null && total > 0 ? (chunk / total) * 0.05 : 0.0,
          ));
        }, maxRetries: maxRetries);
      }

      final versionJsonContent = await versionJsonFile.readAsString();
      final versionJson = json.decode(versionJsonContent) as Map<String, dynamic>;

      // 先解析库和客户端信息
      final libs = _parseLibraries(versionJson, downloadPath);
      final client = _parseClientJar(versionJson, downloadPath, versionId);

      // 处理 assetIndex：先下载索引文件，然后解析对象列表
      final assetsInfo = versionJson['assetIndex'] as Map<String, dynamic>?;
      final List<DownloadTask> assetObjectTasks = [];
      if (assetsInfo != null) {
        final assetIndexId = assetsInfo['id'] as String;
        final assetIndexPath = path.join(downloadPath, 'assets', 'indexes', '$assetIndexId.json');
        final assetIndexUrl = assetsInfo['url'] as String;

        final assetIndexFile = File(assetIndexPath);
        if (!await assetIndexFile.exists()) {
          await _downloadFileSimpleBytes(assetIndexUrl, assetIndexPath, (downloaded, total) {
            onProgress(DownloadProgress(
              currentTask: '下载资源索引: $assetIndexId.json',
              completedTasks: 0,
              totalTasks: 1,
              taskProgress: total != null && total > 0 ? downloaded / total : 0.0,
              overallProgress: 0.02,
            ));
          }, maxRetries: maxRetries);
        }

        // 解析 asset index 获取对象列表
        assetObjectTasks.addAll(await _parseAssetObjects(assetIndexPath, downloadPath));
      }

      // 合并所有需要下载的任务（库、资源对象、客户端）
      final tasks = <DownloadTask>[];
      tasks.addAll(libs);
      tasks.addAll(assetObjectTasks);
      tasks.add(client);

      // 估算总字节数（使用可用的 expectedSize）
      int totalBytes = 0;
      for (final t in tasks) {
        if (t.expectedSize != null) {
          totalBytes += t.expectedSize!;
        }
      }

      final totalTasks = tasks.length;
      int completedTasks = 0;
      int downloadedBytes = 0;

      // 并发下载队列
      final queue = List<DownloadTask>.from(tasks);
      final List<Future> workers = [];

      for (int w = 0; w < concurrency; w++) {
        workers.add((() async {
          while (true) {
            DownloadTask? task;
            // 获取下一个任务
            if (queue.isNotEmpty) {
              task = queue.removeAt(0);
            } else {
              break;
            }

            onProgress(DownloadProgress(
              currentTask: task.description,
              completedTasks: completedTasks,
              totalTasks: totalTasks,
              taskProgress: 0.0,
              overallProgress: totalBytes > 0 ? downloadedBytes / totalBytes : completedTasks / totalTasks,
            ));

            final file = File(task.localPath);
            if (await file.exists()) {
              // 已存在则跳过，但记入大小（如果已知）
              if (task.expectedSize != null) downloadedBytes += task.expectedSize!;
              completedTasks++;
              continue;
            }

            try {
              await _downloadFileSimpleBytes(task.url, task.localPath, (chunkDownloaded, fileTotal) async {
                // 增加已下载字节（chunk）并回调总体进度
                downloadedBytes += chunkDownloaded;
                onProgress(DownloadProgress(
                  currentTask: task!.description,
                  completedTasks: completedTasks,
                  totalTasks: totalTasks,
                  taskProgress: fileTotal != null && fileTotal > 0 ? (downloadedBytes % (fileTotal + 1)) / fileTotal : 0.0,
                  overallProgress: totalBytes > 0 ? downloadedBytes / totalBytes : (completedTasks / totalTasks),
                ));
              }, maxRetries: maxRetries);

              completedTasks++;
            } catch (e) {
              // 单个任务失败时记录并继续（可改为重试队列）
              stderr.writeln('下载失败: ${task.description} (${task.url}) -> $e');
            }
          }
        })());
      }

      await Future.wait(workers);

      onProgress(DownloadProgress(
        currentTask: '完成',
        completedTasks: totalTasks,
        totalTasks: totalTasks,
        taskProgress: 1.0,
        overallProgress: 1.0,
      ));
    } catch (e) {
      throw Exception('下载失败: $e');
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
          localPath = path.join(downloadPath, 'resources', key);
        } else if (virtual == true) {
          localPath = path.join(downloadPath, 'assets', 'virtual', 'legacy', key);
        } else {
          localPath = path.join(downloadPath, 'assets', 'objects', hashPrefix, hash);
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

  

  

  

  static Future<void> _downloadFileSimpleBytes(
    String url,
    String localPath,
    Function(int chunkDownloaded, int? totalBytes) onChunk, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final dir = Directory(path.dirname(localPath));
        if (!await dir.exists()) await dir.create(recursive: true);

        final file = File(localPath);
        if (await file.exists()) await file.delete();

        final client = http.Client();
        try {
          final request = http.Request('GET', Uri.parse(url));
          final response = await client.send(request);
          if (response.statusCode != 200) {
            throw Exception('HTTP ${response.statusCode}');
          }

          final contentLength = response.contentLength;
          final sink = file.openWrite();

          await response.stream.listen((chunk) {
            sink.add(chunk);
            onChunk(chunk.length, contentLength);
          }, onDone: () async {
            await sink.close();
            onChunk(0, contentLength);
          }, onError: (e) async {
            await sink.close();
            throw e;
          }).asFuture();
        } finally {
          client.close();
        }

        return;
      } catch (e) {
        if (attempt >= maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempt));
      }
    }
  }

  
}
