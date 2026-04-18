import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:exif/exif.dart';
import 'package:mark_it/src/models/watermark_data.dart';

class ExifService {
  static Future<WatermarkData> extractFromFile(File file) async {
    try {
      final raf = await file.open(mode: FileMode.read);
      final fileLen = await raf.length();
      // EXIF is usually near the start; some bodies embed large MakerNotes
      final readLen = math.min(fileLen, 512 * 1024);
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

  /// First numeric value from EXIF tag: rationals, ints, or parsed printable.
  static double? _firstNumeric(IfdTag? tag) {
    if (tag == null) return null;
    final v = tag.values;
    if (v is IfdRatios && v.ratios.isNotEmpty) {
      final r = v.ratios.first;
      if (r.denominator == 0) return null;
      return r.numerator / r.denominator;
    }
    if (v is IfdInts && v.ints.isNotEmpty) {
      return v.ints.first.toDouble();
    }
    final p = tag.printable.trim();
    if (p.isEmpty) return null;
    return _parseRationalOrDouble(p);
  }

  static double? _parseRationalOrDouble(String raw) {
    final slash = RegExp(r'^(-?\d+(?:\.\d+)?)\s*/\s*(-?\d+(?:\.\d+)?)$');
    final m = slash.firstMatch(raw.replaceAll(' ', ''));
    if (m != null) {
      final a = double.tryParse(m.group(1)!);
      final b = double.tryParse(m.group(2)!);
      if (a != null && b != null && b != 0) return a / b;
    }
    return double.tryParse(raw.replaceAll(RegExp(r'[^\d.\-eE]'), ''));
  }

  static String _formatFocalLength(Map<String, IfdTag> tags) {
    final flMm = _firstNumeric(tags['EXIF FocalLength']);
    if (flMm != null && flMm > 0.3 && flMm < 3000) {
      return flMm >= 10
          ? '${flMm.round()}mm'
          : '${flMm.toStringAsFixed(1)}mm';
    }

    final eq = _firstNumeric(tags['EXIF FocalLengthIn35mmFilm']);
    if (eq != null && eq > 0 && eq < 3000) {
      return '${eq.round()}mm';
    }

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
    final single = double.tryParse(clean);
    if (single != null && single > 0) {
      return single >= 10
          ? '${single.round()}mm'
          : '${single.toStringAsFixed(1)}mm';
    }
    return '${clean}mm';
  }

  static String _formatAperture(Map<String, IfdTag> tags) {
    final fnum = _firstNumeric(tags['EXIF FNumber']);
    if (fnum != null && fnum > 0 && fnum < 200) {
      return 'f/${fnum.toStringAsFixed(1)}';
    }
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

  /// Human-readable shutter string from exposure time in seconds.
  static String _formatExposureSeconds(double seconds) {
    if (seconds <= 0 || seconds.isInfinite || seconds.isNaN) return '';
    if (seconds >= 10) return '${seconds.round()}s';
    if (seconds >= 1) {
      final r = seconds.round();
      if ((seconds - r).abs() < 0.05) return '${r}s';
      return '${seconds.toStringAsFixed(1)}s';
    }
    final inv = 1.0 / seconds;
    if (inv >= 8000) return '1/${inv.round()}s';
    final rounded = inv.round();
    if (rounded > 0) return '1/${rounded}s';
    return '${seconds.toStringAsFixed(3)}s';
  }

  static String _formatShutterSpeed(Map<String, IfdTag> tags) {
    final etTag = tags['EXIF ExposureTime'];
    final etSec = _firstNumeric(etTag);
    if (etSec != null && etSec > 0 && etSec < 86400) {
      return _formatExposureSeconds(etSec);
    }

    final raw = _readTag(tags, 'EXIF ExposureTime');
    if (raw != null && raw.isNotEmpty) {
      final parsed = _parseRationalOrDouble(raw);
      if (parsed != null && parsed > 0 && parsed < 86400) {
        return _formatExposureSeconds(parsed);
      }
      if (raw.contains('/')) return '${raw}s';
      final val = double.tryParse(raw.replaceAll(RegExp(r'[^\d.]'), ''));
      if (val != null && val > 0 && val < 86400) {
        return _formatExposureSeconds(val);
      }
    }

    // Many phones / cameras only publish APEX shutter speed.
    final sv = _firstNumeric(tags['EXIF ShutterSpeedValue']);
    if (sv != null && sv.abs() < 100) {
      final t = math.pow(2.0, -sv).toDouble();
      if (t > 0 && t < 86400) return _formatExposureSeconds(t);
    }

    return '';
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
