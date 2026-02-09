import 'package:flutter/foundation.dart';

enum PackFormat {
  bamcpack,
  pclpack,
  mrpack,
  mcbbs,
  unknown,
}

class PackFormatDetector {
  Future<PackFormat> detectFormat(String filePath) async {
    return await compute(_detectFormatInBackground, filePath);
  }

  static PackFormat _detectFormatInBackground(String filePath) {
    if (filePath.endsWith('.bamcpack')) return PackFormat.bamcpack;
    if (filePath.endsWith('.pclpack')) return PackFormat.pclpack;
    if (filePath.endsWith('.mrpack')) return PackFormat.mrpack;
    if (filePath.endsWith('.zip') || filePath.endsWith('.7z')) return PackFormat.mcbbs;
    return PackFormat.unknown;
  }
}
