import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

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

class GameList {
  static const String versionManifestUrl =
      'https://launchermeta.mojang.com/mc/game/version_manifest.json';

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
    Function(double) onProgress,
  ) async {
    try {
      final versionJsonUrl = await getVersionJsonUrl(versionId);
      
      final versionDir = Directory('$downloadPath/$versionId');
      if (!await versionDir.exists()) {
        await versionDir.create(recursive: true);
      }

      final versionJsonPath = '${versionDir.path}/$versionId.json';
      final versionJsonFile = File(versionJsonPath);
      
      final versionJsonResponse = await http.get(Uri.parse(versionJsonUrl));
      if (versionJsonResponse.statusCode == 200) {
        await versionJsonFile.writeAsBytes(versionJsonResponse.bodyBytes);
      }

      onProgress(0.5);

      final client = HttpClient();
      final assetsUrl = 'https://launcher.mojang.com/v1/objects/'
          '${versionId.replaceAll('.', '')}/'
          'client.jar';
          
      final clientJarPath = '${versionDir.path}/client.jar';
      final clientJarFile = File(clientJarPath);
      
      final request = await client.getUrl(Uri.parse(assetsUrl));
      final response = await request.close();
      
      final totalBytes = response.contentLength;
      int downloadedBytes = 0;
      
      final bytesBuilder = <int>[];
      await for (final chunk in response) {
        bytesBuilder.addAll(chunk);
        downloadedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(0.5 + (0.5 * downloadedBytes / totalBytes));
        }
      }
      
      await clientJarFile.writeAsBytes(bytesBuilder);
      client.close();

      onProgress(1.0);
    } catch (e) {
      throw Exception('Failed to download version $versionId: $e');
    }
  }
}
