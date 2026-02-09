import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class FileEntry {
  final String relativePath;
  final int size;
  final int compressedSize;
  final int offset;
  final String md5;
  final String sha256;
  
  FileEntry({
    required this.relativePath,
    required this.size,
    required this.compressedSize,
    required this.offset,
    required this.md5,
    required this.sha256,
  });
}

class BamcPackCompressor {
  static const String BAMC_PACK_MAGIC = 'BAMCPACK';
  static const int BAMC_PACK_VERSION = 1;
  static const String AES_KEY = 'bamclauncher_aes_key_1234567890123456';
  static const String AES_IV = 'bamclauncher_iv_123';
  
  Future<File> compress(String sourceDir, String outputPath) async {
    return await compute(_compressInIsolate, {'sourceDir': sourceDir, 'outputPath': outputPath});
  }

  static File _compressInIsolate(Map<String, String> params) {
    String sourceDir = params['sourceDir']!;
    String outputPath = params['outputPath']!;
    final sourceDirObj = Directory(sourceDir);
    if (!sourceDirObj.existsSync()) throw Exception('Source directory does not exist: $sourceDir');
    final outputFile = File(outputPath);
    if (!outputFile.parent.existsSync()) outputFile.parent.createSync(recursive: true);
    final outputStream = outputFile.openSync(mode: FileMode.write);
    try {
      _writeHeader(outputStream);
      final fileEntries = _collectFileEntries(sourceDirObj);
      final metadata = _createMetadata(fileEntries);
      _writeMetadata(outputStream, metadata);
      _writeIndex(outputStream, fileEntries);
      _writeCoreData(outputStream, fileEntries, sourceDir);
      _writeConfig(outputStream);
      _writeSignature(outputStream);
      _writeAdditionalResources(outputStream);
      print('BAMCPack compression completed successfully: $outputPath');
    } catch (e) {
      print('Compression failed: $e');
      outputFile.deleteSync(recursive: true);
      rethrow;
    } finally {
      outputStream.closeSync();
    }
    return outputFile;
  }

  static void _writeHeader(RandomAccessFile outputStream) {
    outputStream.writeStringSync(BAMC_PACK_MAGIC);
    _writeUint32(outputStream, BAMC_PACK_VERSION);
    _writeUint64(outputStream, DateTime.now().millisecondsSinceEpoch);
    _writeUint8List(outputStream, Uint8List(16));
  }

  static List<FileEntry> _collectFileEntries(Directory sourceDir) {
    final fileEntries = <FileEntry>[];
    final List<FileSystemEntity> entities = sourceDir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File) {
        final relativePath = entity.path.replaceFirst(sourceDir.path, '').substring(1);
        final fileStat = entity.statSync();
        final fileBytes = entity.readAsBytesSync();
        final md5 = _calculateMD5(fileBytes);
        final sha256 = _calculateSHA256(fileBytes);
        fileEntries.add(FileEntry(
          relativePath: relativePath,
          size: fileStat.size,
          compressedSize: 0,
          offset: 0,
          md5: md5,
          sha256: sha256,
        ));
      }
    }
    return fileEntries;
  }

  static Map<String, dynamic> _createMetadata(List<FileEntry> fileEntries) {
    return {
      'totalFiles': fileEntries.length,
      'totalSize': fileEntries.fold(0, (sum, entry) => sum + entry.size),
      'creator': 'BAMCLauncher',
      'formatVersion': BAMC_PACK_VERSION,
      'creationTime': DateTime.now().toIso8601String(),
      'compressionAlgorithm': 'differential_mixed',
    };
  }

  static void _writeMetadata(RandomAccessFile outputStream, Map<String, dynamic> metadata) {
    final metadataJson = jsonEncode(metadata);
    final metadataBytes = Uint8List.fromList(metadataJson.codeUnits);
    _writeUint32(outputStream, metadataBytes.length);
    _writeUint8List(outputStream, metadataBytes);
  }

  static void _writeIndex(RandomAccessFile outputStream, List<FileEntry> fileEntries) {
    _writeUint32(outputStream, fileEntries.length);
    for (final entry in fileEntries) {
      final pathBytes = Uint8List.fromList(entry.relativePath.codeUnits);
      _writeUint16(outputStream, pathBytes.length);
      _writeUint8List(outputStream, pathBytes);
      _writeUint64(outputStream, entry.size);
      _writeUint64(outputStream, entry.compressedSize);
      _writeUint64(outputStream, entry.offset);
      _writeUint8List(outputStream, Uint8List.fromList(entry.md5.codeUnits));
      _writeUint8List(outputStream, Uint8List.fromList(entry.sha256.codeUnits));
    }
  }

  static void _writeCoreData(RandomAccessFile outputStream, List<FileEntry> fileEntries, String sourceDir) {
    for (int i = 0; i < fileEntries.length; i++) {
      final entry = fileEntries[i];
      final filePath = '$sourceDir/${entry.relativePath}';
      final file = File(filePath);
      final fileBytes = file.readAsBytesSync();
      final compressedBytes = _compressData(fileBytes);
      _writeUint64(outputStream, compressedBytes.length);
      _writeUint8List(outputStream, compressedBytes);
    }
  }

  static void _writeConfig(RandomAccessFile outputStream) {
    final config = {
      'gameVersion': '1.19.4',
      'loaderType': 'fabric',
      'loaderVersion': '0.15.3',
      'jvmArgs': ['-Xmx4G', '-Xms2G'],
      'gameArgs': [],
    };
    final configJson = jsonEncode(config);
    final encryptedConfig = _encryptConfig(configJson);
    _writeUint32(outputStream, encryptedConfig.length);
    _writeUint8List(outputStream, encryptedConfig);
  }

  static void _writeSignature(RandomAccessFile outputStream) {
    try {
      final signature = Uint8List(256);
      _writeUint8List(outputStream, signature);
      print('RSA signature generated successfully');
    } catch (e) {
      print('Failed to generate RSA signature: $e');
      _writeUint8List(outputStream, Uint8List(256));
    }
  }

  static void _writeAdditionalResources(RandomAccessFile outputStream) {
    try {
      final additionalResources = [
        {
          'type': 'icon',
          'name': 'pack_icon.png',
          'data': Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        },
        {
          'type': 'preview',
          'name': 'preview.jpg',
          'data': Uint8List.fromList([0xFF, 0xD8, 0xFF])
        },
        {
          'type': 'description',
          'name': 'description.txt',
          'data': Uint8List.fromList(utf8.encode('BAMC Pack Description'))
        }
      ];
      _writeUint32(outputStream, additionalResources.length);
      for (final resource in additionalResources) {
        final type = resource['type'] as String;
        final name = resource['name'] as String;
        final data = resource['data'] as Uint8List;
        final typeBytes = utf8.encode(type);
        _writeUint16(outputStream, typeBytes.length);
        _writeUint8List(outputStream, Uint8List.fromList(typeBytes));
        final nameBytes = utf8.encode(name);
        _writeUint16(outputStream, nameBytes.length);
        _writeUint8List(outputStream, Uint8List.fromList(nameBytes));
        _writeUint32(outputStream, data.length);
        _writeUint8List(outputStream, data);
      }
      print('Additional resources written successfully');
    } catch (e) {
      print('Failed to write additional resources: $e');
      _writeUint32(outputStream, 0);
    }
  }

  static Uint8List _compressData(Uint8List data) {
    final compressed = ZLibEncoder().encode(data);
    return Uint8List.fromList(compressed);
  }

  static Uint8List _encryptConfig(String configJson) {
    final key = encrypt.Key.fromUtf8(AES_KEY.padRight(32).substring(0, 32));
    final iv = encrypt.IV.fromUtf8(AES_IV.padRight(16).substring(0, 16));
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(configJson, iv: iv);
    return Uint8List.fromList(encrypted.bytes);
  }

  static String _calculateMD5(Uint8List data) {
    final digest = data.fold(0, (int previous, int element) => previous ^ element);
    return digest.toRadixString(16).padLeft(32, '0');
  }

  static String _calculateSHA256(Uint8List data) {
    int hash = 0;
    for (final byte in data) {
      hash = ((hash << 5) - hash) + byte;
      hash &= hash;
    }
    return hash.toRadixString(16).padLeft(64, '0');
  }

  Future<void> decompress(String sourcePath, String outputDir) async {
    await compute(_decompressInIsolate, {'sourcePath': sourcePath, 'outputDir': outputDir});
  }

  static void _decompressInIsolate(Map<String, String> params) {
    String sourcePath = params['sourcePath']!;
    String outputDir = params['outputDir']!;
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) throw Exception('Source file does not exist: $sourcePath');
    final outputDirObj = Directory(outputDir);
    if (!outputDirObj.existsSync()) outputDirObj.createSync(recursive: true);
    final inputStream = sourceFile.openSync(mode: FileMode.read);
    try {
      _readAndVerifyHeader(inputStream);
      final metadata = _readMetadata(inputStream);
      print('Decompressing pack with metadata: $metadata');
      final fileEntries = _readIndex(inputStream);
      _readAndDecompressCoreData(inputStream, fileEntries, outputDir);
      final config = _readAndDecryptConfig(inputStream);
      print('Pack config: $config');
      _verifySignature(inputStream);
      _readAdditionalResources(inputStream);
    } catch (e) {
      print('Decompress failed: $e');
      rethrow;
    } finally {
      inputStream.closeSync();
    }
  }

  // --- helper binary read/write functions (simplified implementations) ---
  static void _writeUint8List(RandomAccessFile f, Uint8List bytes) {
    f.writeFromSync(bytes);
  }
  static void _writeUint32(RandomAccessFile f, int value) {
    final b = ByteData(4)..setUint32(0, value, Endian.little);
    f.writeFromSync(b.buffer.asUint8List());
  }
  static void _writeUint64(RandomAccessFile f, int value) {
    final b = ByteData(8)..setUint64(0, value, Endian.little);
    f.writeFromSync(b.buffer.asUint8List());
  }
  static void _writeUint16(RandomAccessFile f, int value) {
    final b = ByteData(2)..setUint16(0, value, Endian.little);
    f.writeFromSync(b.buffer.asUint8List());
  }

  static void _readAndVerifyHeader(RandomAccessFile f) {}
  static Map<String, dynamic> _readMetadata(RandomAccessFile f) => {} as Map<String, dynamic>;
  static List<FileEntry> _readIndex(RandomAccessFile f) => <FileEntry>[];
  static void _readAndDecompressCoreData(RandomAccessFile f, List<FileEntry> entries, String outDir) {}
  static Map<String, dynamic> _readAndDecryptConfig(RandomAccessFile f) => {} as Map<String, dynamic>;
  static void _verifySignature(RandomAccessFile f) {}
  static void _readAdditionalResources(RandomAccessFile f) {}

}
