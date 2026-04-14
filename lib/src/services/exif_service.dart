import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:exif/exif.dart';
import 'package:mark_it/src/models/watermark_data.dart';

class ExifService {
  static Future<WatermarkData> extractFromFile(File file) async {
    try {
      final raf = await file.open(mode: FileMode.read);
      final fileLen = await raf.length();
      // EXIF lives in the first few KB; 256KB covers all cameras including 200MP
      final readLen = min(fileLen, 256 * 1024);
      final bytes = await raf.read(readLen);
      await raf.close();

      final tags = await readExifFromBytes(bytes);

      return WatermarkData(
        deviceName: _readTag(tags, 'Image Model') ??
            _readTag(tags, 'EXIF LensModel') ??
            '',
        focalLength: _formatFocalLength(tags),
        aperture: _formatAperture(tags),
        shutterSpeed: _formatShutterSpeed(tags),
        iso: _readTag(tags, 'EXIF ISOSpeedRatings') ?? '',
        dateTime: _readTag(tags, 'EXIF DateTimeOriginal') ??
            _readTag(tags, 'Image DateTime') ??
            '',
        brandId: _guessBrandId(tags),
      );
    } catch (e) {
      debugPrint('ExifService: extraction failed: $e');
      return WatermarkData(
        deviceName: file.uri.pathSegments.last.split('.').first,
      );
    }
  }

  static String? _readTag(Map<String, IfdTag> tags, String key) {
    final tag = tags[key];
    if (tag == null) return null;
    final val = tag.printable.trim();
    return val.isEmpty ? null : val;
  }

  static String _formatFocalLength(Map<String, IfdTag> tags) {
    final raw = _readTag(tags, 'EXIF FocalLength') ??
        _readTag(tags, 'EXIF FocalLengthIn35mmFilm');
    if (raw == null) return '';
    final clean = raw.replaceAll(RegExp(r'[^\d./]'), '');
    if (clean.contains('/')) {
      final parts = clean.split('/');
      if (parts.length == 2) {
        final num = double.tryParse(parts[0]);
        final den = double.tryParse(parts[1]);
        if (num != null && den != null && den != 0) {
          return '${(num / den).round()}mm';
        }
      }
    }
    return '${clean}mm';
  }

  static String _formatAperture(Map<String, IfdTag> tags) {
    final raw = _readTag(tags, 'EXIF FNumber');
    if (raw == null) return '';
    if (raw.contains('/')) {
      final parts = raw.split('/');
      if (parts.length == 2) {
        final num = double.tryParse(parts[0]);
        final den = double.tryParse(parts[1]);
        if (num != null && den != null && den != 0) {
          return 'f/${(num / den).toStringAsFixed(1)}';
        }
      }
    }
    return 'f/$raw';
  }

  static String _formatShutterSpeed(Map<String, IfdTag> tags) {
    final raw = _readTag(tags, 'EXIF ExposureTime');
    if (raw == null) return '';
    if (raw.contains('/')) return '${raw}s';
    final val = double.tryParse(raw);
    if (val != null && val > 0 && val < 1) {
      return '1/${(1 / val).round()}s';
    }
    return '${raw}s';
  }

  static String _guessBrandId(Map<String, IfdTag> tags) {
    final make = (_readTag(tags, 'Image Make') ?? '').toLowerCase();
    if (make.contains('xiaomi')) return 'xiaomi';
    if (make.contains('oppo')) return 'oppo';
    if (make.contains('samsung')) return 'samsung';
    if (make.contains('apple')) return 'apple';
    if (make.contains('google')) return 'google';
    if (make.contains('oneplus')) return 'oneplus';
    if (make.contains('huawei')) return 'huawei';
    if (make.contains('vivo')) return 'vivo';
    if (make.contains('honor')) return 'honor';
    if (make.contains('nothing')) return 'nothing';
    if (make.contains('realme')) return 'realme';
    if (make.contains('motorola')) return 'motorola';
    if (make.contains('sony')) return 'sony_camera';
    if (make.contains('nikon')) return 'nikon';
    if (make.contains('canon')) return 'canon';
    if (make.contains('fuji')) return 'fujifilm';
    if (make.contains('panasonic')) return 'panasonic';
    if (make.contains('olympus') || make.contains('om digital')) return 'olympus';
    if (make.contains('pentax')) return 'pentax';
    if (make.contains('ricoh')) return 'ricoh';
    if (make.contains('dji')) return 'dji';
    if (make.contains('iqoo')) return 'iqoo';
    if (make.contains('nubia') || make.contains('zte')) return 'nubia';
    return 'none';
  }

  static const rawExtensions = {
    '.dng', '.cr2', '.cr3', '.nef', '.arw', '.orf', '.rw2',
    '.raf', '.pef', '.srw', '.raw',
  };

  static bool isRawFile(String path) {
    final ext = path.toLowerCase();
    return rawExtensions.any((r) => ext.endsWith(r));
  }
}
