import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<String> exportWatermarked({
    required File imageFile,
    required GlobalKey previewKey,
    double pixelRatio = 3.0,
  }) async {
    final boundary = previewKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('Preview widget not found');

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to encode image');

    final bytes = byteData.buffer.asUint8List();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final docDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${docDir.path}/Mark-it');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final localPath = '${exportDir.path}/markit_$timestamp.png';
    await File(localPath).writeAsBytes(bytes);

    try {
      await Gal.putImage(localPath, album: 'Mark-it');
    } catch (_) {}

    return localPath;
  }

  static Future<void> share(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }
}
