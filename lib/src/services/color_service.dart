import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ColorService {
  /// Extract palette using the native image codec which efficiently
  /// downscales even 200MP images without decoding full resolution.
  static Future<ImagePalette> extractPalette(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 64,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      codec.dispose();
      image.dispose();

      if (byteData == null) return ImagePalette.fallback();

      final pixels = byteData.buffer.asUint8List();
      final colorCounts = <int, int>{};

      for (int i = 0; i < pixels.length; i += 4) {
        final r = (pixels[i] ~/ 32) * 32;
        final g = (pixels[i + 1] ~/ 32) * 32;
        final b = (pixels[i + 2] ~/ 32) * 32;
        final key = (r << 16) | (g << 8) | b;
        colorCounts[key] = (colorCounts[key] ?? 0) + 1;
      }

      final sorted = colorCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final colors = sorted.take(6).map((e) {
        return Color.fromARGB(
          255,
          (e.key >> 16) & 0xFF,
          (e.key >> 8) & 0xFF,
          e.key & 0xFF,
        );
      }).toList();

      if (colors.isEmpty) return ImagePalette.fallback();

      final primary = colors.first;
      final dominant = colors.length > 1 ? colors[1] : primary;

      return ImagePalette(
        primary: primary,
        dominant: dominant,
        accent: colors.length > 2 ? colors[2] : primary,
        palette: colors,
        contrastColor: _contrastColor(primary),
        contrastTextColor: _textContrast(primary),
      );
    } catch (e) {
      debugPrint('ColorService: palette extraction failed: $e');
      return ImagePalette.fallback();
    }
  }

  static Color _contrastColor(Color c) {
    final luminance = c.computeLuminance();
    if (luminance > 0.5) {
      final hsl = HSLColor.fromColor(c);
      return hsl.withLightness(max(0, hsl.lightness - 0.5)).toColor();
    } else {
      final hsl = HSLColor.fromColor(c);
      return hsl.withLightness(min(1, hsl.lightness + 0.5)).toColor();
    }
  }

  static Color _textContrast(Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}

class ImagePalette {
  final Color primary;
  final Color dominant;
  final Color accent;
  final List<Color> palette;
  final Color contrastColor;
  final Color contrastTextColor;

  const ImagePalette({
    required this.primary,
    required this.dominant,
    required this.accent,
    required this.palette,
    required this.contrastColor,
    required this.contrastTextColor,
  });

  factory ImagePalette.fallback() => const ImagePalette(
        primary: Color(0xFF888888),
        dominant: Color(0xFF666666),
        accent: Color(0xFFAAAAAA),
        palette: [],
        contrastColor: Colors.white,
        contrastTextColor: Colors.white,
      );
}
