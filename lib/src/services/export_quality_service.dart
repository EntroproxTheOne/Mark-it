import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ExportQualityTier {
  standard,
  high,
  ultra,
  original,
}

/// Persisted export scale + helpers to match on-screen layout pixel density.
class ExportQualityService {
  static const _prefsKey = 'export_quality_tier';

  static Future<ExportQualityTier> currentTier() async {
    final p = await SharedPreferences.getInstance();
    final i = p.getInt(_prefsKey);
    if (i == null) return ExportQualityTier.high;
    if (i < 0 || i >= ExportQualityTier.values.length) {
      return ExportQualityTier.high;
    }
    return ExportQualityTier.values[i];
  }

  static Future<void> setTier(ExportQualityTier tier) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_prefsKey, tier.index);
  }

  static String label(ExportQualityTier t) => switch (t) {
        ExportQualityTier.standard => 'Standard (2×)',
        ExportQualityTier.high => 'High (3×)',
        ExportQualityTier.ultra => 'Ultra (4×)',
        ExportQualityTier.original => 'Original resolution',
      };

  static String description(ExportQualityTier t) => switch (t) {
        ExportQualityTier.standard => 'Smaller files, sharp on most phones',
        ExportQualityTier.high => 'Recommended balance of size and detail',
        ExportQualityTier.ultra => 'Larger PNG, extra crisp edges and text',
        ExportQualityTier.original =>
          'Export width matches your photo when possible (best for HEIC / large shots)',
      };

  /// Decodes pixel width from image bytes (JPEG/PNG/WebP; HEIC may fail — use display JPEG).
  static Future<int?> decodeImageWidth(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        final w = frame.image.width;
        frame.image.dispose();
        return w;
      } finally {
        codec.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  /// [logicalWidth] is the RepaintBoundary width in logical pixels.
  static double pixelRatioForTier({
    required ExportQualityTier tier,
    required double logicalWidth,
    int? imageWidthPx,
  }) {
    if (logicalWidth <= 0) return 3;
    final base = switch (tier) {
      ExportQualityTier.standard => 2.0,
      ExportQualityTier.high => 3.0,
      ExportQualityTier.ultra => 4.0,
      ExportQualityTier.original => 4.0,
    };
    if (tier != ExportQualityTier.original || imageWidthPx == null) {
      return base;
    }
    final match = imageWidthPx / logicalWidth;
    return match.clamp(4.0, 14.0);
  }

  static Future<double> resolveExportPixelRatio({
    required RenderRepaintBoundary boundary,
    required File dimensionFile,
  }) async {
    final tier = await currentTier();
    final logicalW = boundary.size.width;
    final imgW = await decodeImageWidth(dimensionFile);
    return pixelRatioForTier(
      tier: tier,
      logicalWidth: logicalW,
      imageWidthPx: imgW,
    );
  }
}
