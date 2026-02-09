import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import '../components/anime_button.dart';
import '../components/anime_card.dart';
import '../services/pack_format_detector.dart';
import '../services/bamc_pack_compressor.dart';
import '../utils/file_path_utils.dart';
import 'package:file_picker/file_picker.dart';

class PackManagementView extends StatefulWidget {
  const PackManagementView({Key? key}) : super(key: key);
  @override
  State<PackManagementView> createState() => _PackManagementViewState();
}

class _PackManagementViewState extends State<PackManagementView> {
  final PackFormatDetector _packFormatDetector = PackFormatDetector();
  final BamcPackCompressor _bamcPackCompressor = BamcPackCompressor();
  bool _isImporting = false;
  bool _isCreating = false;
  String _selectedPackPath = '';
  var _detectedFormat = PackFormat.unknown;
  final List<String> _gameVersions = ['1.20.4','1.20.1','1.19.4'];
  final List<String> _loaderTypes = ['fabric','forge','quilt','vanilla'];
  String _selectedGameVersion = '1.20.4';
  String _selectedLoaderType = 'fabric';
  String _packName = '';
  String _packDescription = '';

  Future<void> _importPack() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['bamcpack','pclpack','mrpack','zip','7z'], dialogTitle: '选择整合包文件');
    if (result == null || result.files.isEmpty) return;
    final packPath = result.files.first.path!;
    setState(() { _isImporting = true; _selectedPackPath = packPath; });
    try {
      final format = await _packFormatDetector.detectFormat(packPath);
      setState(() { _detectedFormat = format; });
      await _importPackByFormat(packPath, format);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('整合包导入成功')));
    } catch (e) {
      print('Failed to import pack: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('整合包导入失败: $e')));
    } finally { setState(() { _isImporting = false; }); }
  }

  Future<void> _createPack() async {
    if (_packName.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('请输入整合包名称'))); return; }
    setState(() { _isCreating = true; });
    try {
      final outputPath = await FilePicker.platform.saveFile(dialogTitle: '选择整合包保存位置', fileName: '$_packName.bamcpack', allowedExtensions: ['bamcpack'], type: FileType.custom);
      if (outputPath == null) return;
      final tempDir = await Directory.systemTemp.createTemp('bamcpack_');
      final tempPath = tempDir.path;
      try {
        await _createPackStructure(tempPath);
        await _bamcPackCompressor.compress(tempPath, outputPath);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('整合包创建成功: $outputPath')));
        setState(() { _packName = ''; _packDescription = ''; _selectedGameVersion = '1.20.4'; _selectedLoaderType = 'fabric'; });
      } finally { tempDir.deleteSync(recursive: true); }
    } catch (e) {
      print('Failed to create pack: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('整合包创建失败: $e')));
    } finally { setState(() { _isCreating = false; }); }
  }

  Future<void> _createPackStructure(String tempPath) async {
    final metadata = {'name': _packName, 'description': _packDescription, 'gameVersion': _selectedGameVersion, 'loaderType': _selectedLoaderType, 'loaderVersion': 'latest', 'author': 'BAMCLauncher', 'version': '1.0.0', 'createdAt': DateTime.now().toIso8601String()};
    final metadataFile = File('$tempPath/metadata.json');
    await metadataFile.writeAsString(jsonEncode(metadata));
    final instanceConfig = {'id':'temp_instance','name':_packName,'minecraftVersion':_selectedGameVersion,'loaderType':_selectedLoaderType,'loaderVersion':'latest','javaPath':'','allocatedMemory':2048,'jvmArguments':[],'gameArguments':[],'instanceDir':tempPath,'userId':'temp_user','accessToken':'temp_token','userType':'mojang','createdAt':DateTime.now().toIso8601String(),'updatedAt':DateTime.now().toIso8601String(),'isActive':false};
    final instanceFile = File('$tempPath/instance.json');
    await instanceFile.writeAsString(jsonEncode(instanceConfig));
    final subDirs = ['mods','resourcepacks','saves','config','assets','libraries','logs'];
    for (final subDir in subDirs) await Directory('$tempPath/$subDir').create();
  }

  Future<void> _importPackByFormat(String packPath, PackFormat format) async {
    final instancesDir = await _getInstancesDirectory();
    final instanceName = _generateInstanceNameFromPack(packPath);
    final instanceDir = '$instancesDir/$instanceName';
    switch (format) {
      case PackFormat.bamcpack:
        await _bamcPackCompressor.decompress(packPath, instanceDir);
        break;
      default:
        await _extractZipFile(packPath, instanceDir);
        break;
    }
    await _createInstanceConfigFile(instanceDir, instanceName);
  }

  Future<void> _createInstanceConfigFile(String instanceDir, String instanceName) async {
    try {
      final metadataFile = File('$instanceDir/metadata.json');
      Map<String, dynamic> metadata = {};
      if (metadataFile.existsSync()) { final metadataContent = await metadataFile.readAsString(); metadata = jsonDecode(metadataContent); }
      final instanceConfig = {'id': instanceName, 'name': metadata['name'] ?? instanceName, 'minecraftVersion': metadata['gameVersion'] ?? '1.20.4', 'loaderType': metadata['loaderType'] ?? 'vanilla', 'loaderVersion': metadata['loaderVersion'] ?? 'latest', 'javaPath': '', 'allocatedMemory': 2048, 'jvmArguments': [], 'gameArguments': [], 'instanceDir': instanceDir, 'iconPath': '', 'isActive': false, 'createdAt': DateTime.now().toIso8601String(), 'updatedAt': DateTime.now().toIso8601String(), 'userId': '', 'accessToken': '', 'userType': 'offline', 'isCrashed': false, 'crashReason': '', 'lastCrashTime': null, 'gameErrors': [], 'onlinePlayers': [], 'serverAddress': '', 'isConnectedToServer': false, 'isGameReady': false, 'lastReadyTime': null, 'resourceLoadingProgress': 0.0};
      final instanceConfigFile = File('$instanceDir/instance.json');
      await instanceConfigFile.writeAsString(jsonEncode(instanceConfig));
    } catch (e) { print('Failed to create instance config file: $e'); throw Exception('Failed to create instance config file: $e'); }
  }

  Future<String> _getInstancesDirectory() async => await FilePathUtils.getInstancesDirectory();
  String _generateInstanceNameFromPack(String packPath) { final fileName = packPath.split(Platform.pathSeparator).last; final nameWithoutExtension = fileName.split('.').first; final timestamp = DateTime.now().millisecondsSinceEpoch; return '$nameWithoutExtension$timestamp'; }

  Future<void> _extractZipFile(String zipPath, String destDir) async {
    try {
      final zipFile = File(zipPath);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final destination = Directory(destDir);
      if (!destination.existsSync()) destination.createSync(recursive: true);
      for (final file in archive) {
        final filename = file.name;
        final outFile = File('${destination.path}/$filename');
        if (file.isFile) {
          outFile.parent.createSync(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }
    } catch (e) { print('Failed to extract zip: $e'); throw e; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pack Management')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          AnimeButton(text: 'Import Pack', onPressed: _importPack),
          const SizedBox(height: 12),
          AnimeButton(text: 'Create Pack', onPressed: _createPack, isPrimary: false),
        ]),
      ),
    );
  }
}
