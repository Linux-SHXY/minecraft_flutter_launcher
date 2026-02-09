import 'dart:convert';
import 'dart:io';
import '../models/instance_model.dart';
import '../utils/file_path_utils.dart';

class InstanceManager {
  Future<List<InstanceModel>> getAllInstances() async {
    final instancesDir = await FilePathUtils.getInstancesDirectory();
    final dir = Directory(instancesDir);
    
    if (!dir.existsSync()) {
      return [];
    }
    
    final instances = <InstanceModel>[];
    
    final List<FileSystemEntity> entities = dir.listSync();
    for (final entity in entities) {
      if (entity is Directory) {
        final instanceJsonFile = File('${entity.path}/instance.json');
        if (instanceJsonFile.existsSync()) {
          try {
            final jsonString = await instanceJsonFile.readAsString();
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final instance = InstanceModel.fromJson(json);
            instances.add(instance);
          } catch (e) {
            print('Failed to load instance: ${entity.path}, error: $e');
          }
        }
      }
    }
    
    return instances;
  }
  
  Future<InstanceModel?> getInstance(String id) async {
    final instancesDir = await FilePathUtils.getInstancesDirectory();
    final instanceDir = Directory('$instancesDir/$id');
    
    if (!instanceDir.existsSync()) {
      return null;
    }
    
    final instanceJsonFile = File('${instanceDir.path}/instance.json');
    if (!instanceJsonFile.existsSync()) {
      return null;
    }
    
    try {
      final jsonString = await instanceJsonFile.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return InstanceModel.fromJson(json);
    } catch (e) {
      print('Failed to load instance: $id, error: $e');
      return null;
    }
  }
  
  Future<InstanceModel> createInstance(InstanceModel instance) async {
    final instancesDir = await FilePathUtils.getInstancesDirectory();
    final instanceDir = Directory('$instancesDir/${instance.id}');
    
    if (!instanceDir.existsSync()) {
      instanceDir.createSync(recursive: true);
    }
    
    final instanceJsonFile = File('${instanceDir.path}/instance.json');
    final jsonString = jsonEncode(instance.toJson());
    await instanceJsonFile.writeAsString(jsonString);
    
    final subDirs = ['mods', 'resourcepacks', 'saves', 'config', 'logs'];
    for (final subDir in subDirs) {
      final dir = Directory('${instanceDir.path}/$subDir');
      if (!dir.existsSync()) dir.createSync();
    }
    
    return instance;
  }
  
  Future<InstanceModel> updateInstance(InstanceModel instance) async {
    final updatedInstance = instance.copyWith(updatedAt: DateTime.now());
    final instancesDir = await FilePathUtils.getInstancesDirectory();
    final instanceJsonFile = File('$instancesDir/${instance.id}/instance.json');
    
    if (instanceJsonFile.existsSync()) {
      final jsonString = jsonEncode(updatedInstance.toJson());
      await instanceJsonFile.writeAsString(jsonString);
    }
    
    return updatedInstance;
  }
  
  Future<void> deleteInstance(String id) async {
    final instancesDir = await FilePathUtils.getInstancesDirectory();
    final instanceDir = Directory('$instancesDir/$id');
    
    if (instanceDir.existsSync()) {
      instanceDir.deleteSync(recursive: true);
    }
  }
  
  Future<void> launchInstance(InstanceModel instance) async {
    try {
      final javaPath = await _verifyJavaEnvironment(instance.javaPath);
      print('Using Java: $javaPath');
      final launchArgs = await _buildLaunchArguments(instance, javaPath);
      print('Launch arguments: $launchArgs');
      final process = await _startMinecraftProcess(launchArgs, instance.instanceDir);
      print('Minecraft process started with PID: ${process.pid}');
      _monitorProcess(process, instance);
      await updateInstance(instance.copyWith(isActive: true));
      print('Successfully launched instance: ${instance.name}');
    } catch (e) {
      print('Failed to launch instance ${instance.name}: $e');
      throw e;
    }
  }
  
  Future<String> _verifyJavaEnvironment(String javaPath) async {
    if (javaPath.isNotEmpty) {
      final javaFile = File(javaPath);
      if (javaFile.existsSync()) {
        await _verifyJavaVersion(javaPath);
        return javaPath;
      }
    }
    return await _findJavaAutomatically();
  }
  
  Future<void> _verifyJavaVersion(String javaPath) async {
    try {
      final result = await Process.run(javaPath, ['-version'], runInShell: true);
      final output = result.stderr.toString().toLowerCase();
      print('Java version output: $output');
      if (!output.contains('version "1.8') && !output.contains('version "9') && !output.contains('version "11') && !output.contains('version "17')) {
        throw Exception('Unsupported Java version. Please use Java 8, 9, 11, or 17.');
      }
    } catch (e) {
      throw Exception('Failed to verify Java version: $e');
    }
  }
  
  Future<String> _findJavaAutomatically() async {
    final javaExecutable = Platform.isWindows ? 'java.exe' : 'java';
    try {
      final result = await Process.run('where.exe', [javaExecutable], runInShell: true);
      if (result.exitCode == 0) {
        final javaPath = result.stdout.toString().trim().split('\n').first;
        await _verifyJavaVersion(javaPath);
        return javaPath;
      }
    } catch (e) {
      print('Failed to find Java in PATH: $e');
    }
    final commonPaths = Platform.isWindows ? [
      'C:\\Program Files\\Java\\jdk-17\\bin\\java.exe',
      'C:\\Program Files\\Java\\jdk-11\\bin\\java.exe',
      'C:\\Program Files\\Java\\jdk1.8.0_301\\bin\\java.exe',
    ] : ['/usr/bin/java', '/usr/local/bin/java'];
    for (final path in commonPaths) {
      final javaFile = File(path);
      if (javaFile.existsSync()) {
        try {
          await _verifyJavaVersion(path);
          return path;
        } catch (e) {
          print('Java at $path is invalid: $e');
        }
      }
    }
    throw Exception('No valid Java environment found.');
  }
  
  Future<List<String>> _buildLaunchArguments(InstanceModel instance, String javaPath) async {
    final args = <String>[];
    args.addAll(instance.jvmArguments);
    if (!instance.jvmArguments.any((arg) => arg.startsWith('-Xmx'))) {
      args.add('-Xmx${instance.allocatedMemory}M');
    }
    if (!instance.jvmArguments.any((arg) => arg.startsWith('-Xms'))) {
      args.add('-Xms2G');
    }
    switch (instance.loaderType.toLowerCase()) {
      case 'forge':
        args.addAll(_buildForgeArguments(instance));
        break;
      case 'fabric':
        args.addAll(_buildFabricArguments(instance));
        break;
      case 'quilt':
        args.addAll(_buildQuiltArguments(instance));
        break;
      default:
        args.addAll(_buildVanillaArguments(instance));
        break;
    }
    args.addAll(instance.gameArguments);
    return args;
  }
  
  List<String> _buildVanillaArguments(InstanceModel instance) {
    final args = <String>[];
    final librariesDir = Directory('${instance.instanceDir}/libraries');
    final jars = <String>[];
    if (librariesDir.existsSync()) {
      final libraryFiles = librariesDir.listSync(recursive: true)
          .where((file) => file is File && file.path.endsWith('.jar'))
          .map((file) => file.path)
          .toList();
      jars.addAll(libraryFiles);
    }
    final minecraftJar = '${instance.instanceDir}/versions/${instance.minecraftVersion}/${instance.minecraftVersion}.jar';
    jars.add(minecraftJar);
    args.add('-cp');
    args.add(jars.join(Platform.isWindows ? ';' : ':'));
    args.add('net.minecraft.client.main.Main');
    args.add('--version');
    args.add(instance.minecraftVersion);
    args.add('--gameDir');
    args.add(instance.instanceDir);
    args.add('--assetsDir');
    args.add('${instance.instanceDir}/assets');
    args.add('--assetIndex');
    args.add(instance.assetIndex ?? instance.minecraftVersion);
    args.add('--uuid');
    args.add(instance.userId);
    args.add('--accessToken');
    args.add(instance.accessToken);
    args.add('--userType');
    args.add(instance.userType);
    args.add('--versionType');
    args.add(instance.loaderType);
    if (instance.jvmArguments.isNotEmpty) args.addAll(instance.jvmArguments);
    if (instance.gameArguments.isNotEmpty) args.addAll(instance.gameArguments);
    return args;
  }
  
  List<String> _buildForgeArguments(InstanceModel instance) {
    final args = <String>[];
    final librariesDir = Directory('${instance.instanceDir}/libraries');
    final jars = <String>[];
    if (librariesDir.existsSync()) {
      final libraryFiles = librariesDir.listSync(recursive: true)
          .where((file) => file is File && file.path.endsWith('.jar'))
          .map((file) => file.path)
          .toList();
      jars.addAll(libraryFiles);
    }
    final forgeJar = '${instance.instanceDir}/versions/${instance.minecraftVersion}/forge-${instance.minecraftVersion}-${instance.loaderVersion}.jar';
    if (File(forgeJar).existsSync()) {
      jars.add(forgeJar);
    } else {
      final alternativeForgeJar = '${instance.instanceDir}/forge-${instance.minecraftVersion}-${instance.loaderVersion}.jar';
      if (File(alternativeForgeJar).existsSync()) {
        jars.add(alternativeForgeJar);
      }
    }
    final minecraftJar = '${instance.instanceDir}/versions/${instance.minecraftVersion}/${instance.minecraftVersion}.jar';
    jars.add(minecraftJar);
    args.add('-cp');
    args.add(jars.join(Platform.isWindows ? ';' : ':'));
    args.add('net.minecraftforge.fml.loading.FMLClientLaunchProvider');
    args.add('--fml.ignoreInvalidMinecraftCertificates');
    args.add('--fml.ignorePatchDiscrepancies');
    args.add('--version');
    args.add(instance.minecraftVersion);
    args.add('--gameDir');
    args.add(instance.instanceDir);
    args.add('--assetsDir');
    args.add('${instance.instanceDir}/assets');
    args.add('--assetIndex');
    args.add(instance.assetIndex ?? instance.minecraftVersion);
    args.add('--uuid');
    args.add(instance.userId);
    args.add('--accessToken');
    args.add(instance.accessToken);
    args.add('--userType');
    args.add(instance.userType);
    args.add('--versionType');
    args.add('forge');
    if (instance.jvmArguments.isNotEmpty) args.addAll(instance.jvmArguments);
    return args;
  }
  
  List<String> _buildFabricArguments(InstanceModel instance) {
    // simplified for brevity
    return _buildVanillaArguments(instance);
  }
  
  List<String> _buildQuiltArguments(InstanceModel instance) {
    return _buildVanillaArguments(instance);
  }
  
  Future<Process> _startMinecraftProcess(List<String> args, String workingDirectory) async {
    final java = Platform.isWindows ? 'java.exe' : 'java';
    return await Process.start(java, args, workingDirectory: workingDirectory, runInShell: true);
  }
  
  void _monitorProcess(Process process, InstanceModel instance) {
    process.exitCode.then((code) async {
      print('Process exited with code: $code');
      await updateInstance(instance.copyWith(isActive: false));
    });
  }
}
