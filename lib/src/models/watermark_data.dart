import 'package:flutter/material.dart';

class WatermarkData {
  String deviceName;
  String focalLength;
  String aperture;
  String shutterSpeed;
  String iso;
  String dateTime;
  String brandId;
  /// Second line under device (e.g. "Shot on Pixel"); user-editable, not hardcoded from style.
  String subtitle;
  /// When true, picking a new brand replaces [subtitle] with that brand's default tagline.
  bool subtitleTiedToBrand;
  String fontFamily;
  FrameType frameType;
  WatermarkPosition watermarkPosition;
  Color textColor;
  Color frameColor;
  double frameOpacity;
  double borderRadius;
  Color? logoColor;
  /// Scales the whole watermark block (brand logo, device, subtitle, EXIF line) together.
  double watermarkGroupScale;
  /// Scales only the brand logo (1.0 = default).
  double brandLogoScale;
  /// Scales device name, subtitle/tagline, and EXIF line (1.0 = default).
  double infoTextScale;

  WatermarkData({
    this.deviceName = '',
    this.focalLength = '',
    this.aperture = '',
    this.shutterSpeed = '',
    this.iso = '',
    this.dateTime = '',
    this.brandId = 'none',
    this.subtitle = '',
    this.subtitleTiedToBrand = true,
    this.fontFamily = 'Roboto',
    this.frameType = FrameType.whiteFrame,
    this.watermarkPosition = WatermarkPosition.belowImage,
    this.textColor = Colors.black,
    this.frameColor = Colors.white,
    this.frameOpacity = 1.0,
    this.borderRadius = 0,
    this.logoColor,
    this.watermarkGroupScale = 1.0,
    this.brandLogoScale = 1.0,
    this.infoTextScale = 1.0,
  });

  /// Applies saved watermark style onto [exif] while keeping photo-specific fields.
  static WatermarkData mergeSavedLook(WatermarkData exif, WatermarkData saved) {
    return exif.copyWith(
      frameType: saved.frameType,
      watermarkPosition: saved.watermarkPosition,
      textColor: saved.textColor,
      frameColor: saved.frameColor,
      frameOpacity: saved.frameOpacity,
      borderRadius: saved.borderRadius,
      fontFamily: saved.fontFamily,
      brandId: saved.brandId != 'none' ? saved.brandId : exif.brandId,
      logoColor: saved.logoColor,
      subtitle: saved.subtitle.isNotEmpty ? saved.subtitle : exif.subtitle,
      subtitleTiedToBrand: saved.subtitleTiedToBrand,
      watermarkGroupScale: saved.watermarkGroupScale,
      brandLogoScale: saved.brandLogoScale,
      infoTextScale: saved.infoTextScale,
    );
  }

  String get exifString {
    final parts = <String>[];
    if (focalLength.isNotEmpty) parts.add(focalLength);
    if (aperture.isNotEmpty) parts.add(aperture);
    if (shutterSpeed.isNotEmpty) parts.add(shutterSpeed);
    if (iso.isNotEmpty) parts.add('ISO$iso');
    return parts.join('  ');
  }

  WatermarkData copyWith({
    String? deviceName,
    String? focalLength,
    String? aperture,
    String? shutterSpeed,
    String? iso,
    String? dateTime,
    String? brandId,
    String? subtitle,
    bool? subtitleTiedToBrand,
    String? fontFamily,
    FrameType? frameType,
    WatermarkPosition? watermarkPosition,
    Color? textColor,
    Color? frameColor,
    double? frameOpacity,
    double? borderRadius,
    Color? logoColor,
    bool clearLogoColor = false,
    double? watermarkGroupScale,
    double? brandLogoScale,
    double? infoTextScale,
  }) {
    return WatermarkData(
      deviceName: deviceName ?? this.deviceName,
      focalLength: focalLength ?? this.focalLength,
      aperture: aperture ?? this.aperture,
      shutterSpeed: shutterSpeed ?? this.shutterSpeed,
      iso: iso ?? this.iso,
      dateTime: dateTime ?? this.dateTime,
      brandId: brandId ?? this.brandId,
      subtitle: subtitle ?? this.subtitle,
      subtitleTiedToBrand: subtitleTiedToBrand ?? this.subtitleTiedToBrand,
      fontFamily: fontFamily ?? this.fontFamily,
      frameType: frameType ?? this.frameType,
      watermarkPosition: watermarkPosition ?? this.watermarkPosition,
      textColor: textColor ?? this.textColor,
      frameColor: frameColor ?? this.frameColor,
      frameOpacity: frameOpacity ?? this.frameOpacity,
      borderRadius: borderRadius ?? this.borderRadius,
      logoColor: clearLogoColor ? null : (logoColor ?? this.logoColor),
      watermarkGroupScale: watermarkGroupScale ?? this.watermarkGroupScale,
      brandLogoScale: brandLogoScale ?? this.brandLogoScale,
      infoTextScale: infoTextScale ?? this.infoTextScale,
    );
  }
}

enum FrameType {
  whiteFrame('White Frame'),
  blackFrame('Black Frame'),
  darkGrayFrame('Dark Gray'),
  blurFrame('Blur Frame'),
  glassFrame('Glass Frame'),
  colorFrame('Color Frame'),
  vignetteFrame('Vignette'),
  filmFrame('Film Strip'),
  noFrame('No Frame'),
  /// Full-width bottom banner: device + divider + logo, then EXIF (Samsung-style).
  whiteChinSlip('White Chin Slip'),
  blackChinSlip('Black Chin Slip'),
  /// Same layout; banner uses blurred bottom of the photo.
  blurChinSlip('Blur Chin Slip');

  const FrameType(this.label);
  final String label;
}

enum WatermarkPosition {
  belowImage('Below Image'),
  bottomBar('Bottom Bar'),
  overlayBottomLeft('Overlay BL'),
  overlayBottomRight('Overlay BR'),
  overlayTopLeft('Overlay TL'),
  overlayTopRight('Overlay TR'),
  overlayCenter('Center Logo'),
  aboveImage('Above Image');

  const WatermarkPosition(this.label);
  final String label;
}
