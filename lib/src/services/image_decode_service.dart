import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Ensures a file Flutter can decode in [Image.file] (HEIC/HEIF → JPEG temp on Android).
class ImageDecodeService {
  static bool isHeicOrHeif(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.heic' || ext == '.heif';
  }

  /// Returns [input] unchanged for JPEG/PNG/WebP, or a temp JPEG for HEIC/HEIF.
  static Future<File> ensureDisplayable(File input) async {
    if (!isHeicOrHeif(input.path)) return input;

    try {
      final tmpDir = await getTemporaryDirectory();
      final out = File(
        '${tmpDir.path}${Platform.pathSeparator}markit_heic_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final bytes = await FlutterImageCompress.compressWithFile(
        input.absolute.path,
        quality: 100,
        format: CompressFormat.jpeg,
        keepExif: true,
      );

      if (bytes == null || bytes.isEmpty) {
        debugPrint('ImageDecodeService: HEIC compress returned null');
        return input;
      }

      await out.writeAsBytes(bytes, flush: true);
      return out;
    } catch (e, st) {
      debugPrint('ImageDecodeService: HEIC decode failed: $e\n$st');
      return input;
    }
  }
}
