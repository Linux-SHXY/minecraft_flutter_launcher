import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // 从JSON创建MinecraftVersion对象的方法
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

// Minecraft版本清单的数据模型
class MinecraftVersionManifest {
  final Map<String, String> latest;
  final List<MinecraftVersion> versions;

  MinecraftVersionManifest({required this.latest, required this.versions});

  // 从JSON创建MinecraftVersionManifest对象的工厂方法
  factory MinecraftVersionManifest.fromJson(Map<String, dynamic> json) {
    return MinecraftVersionManifest(
      latest: Map<String, String>.from(json['latest']),
      versions: (json['versions'] as List<dynamic>)
          .map((version) => MinecraftVersion.fromJson(version))
          .toList(),
    );
  }
}

class GameList {
  // 版本清单URL
  static const String versionManifestUrl =
      'https://launchermeta.mojang.com/mc/game/version_manifest.json';

  // 获取Minecraft版本列表
  static Future<List<MinecraftVersion>> getMinecraftVersions() async {
    try {
      // 发送HTTP请求
      final response = await http.get(Uri.parse(versionManifestUrl));

      // 检查响应状态码
      if (response.statusCode == 200) {
        // 解析JSON响应
        final jsonData = json.decode(response.body);
        final manifest = MinecraftVersionManifest.fromJson(jsonData);

        // 返回版本列表
        return manifest.versions;
      } else {
        // 抛出异常
        throw Exception('Failed to load versions: ${response.statusCode}');
      }
    } catch (e) {
      // 捕获并重新抛出异常
      throw Exception('Failed to connect to server: $e');
    }
  }

  // 获取最新的发布版本
  static Future<MinecraftVersion?> getLatestRelease() async {
    try {
      final versions = await getMinecraftVersions();
      final manifest = await getVersionManifest();

      // 查找最新发布版本
      return versions.firstWhere(
        (version) => version.id == manifest.latest['release'],
        orElse: () => versions.first,
      );
    } catch (e) {
      print('Error getting latest release: $e');
      return null;
    }
  }

  // 获取完整的版本清单
  static Future<MinecraftVersionManifest> getVersionManifest() async {
    final response = await http.get(Uri.parse(versionManifestUrl));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return MinecraftVersionManifest.fromJson(jsonData);
    } else {
      throw Exception('Failed to load version manifest');
    }
  }
}
