import 'package:flutter/material.dart';

class WatermarkData {
  String deviceName;
  String focalLength;
  String aperture;
  String shutterSpeed;
  String iso;
  String dateTime;
  String brandId;
  String fontFamily;
  FrameType frameType;
  WatermarkPosition watermarkPosition;
  Color textColor;
  Color frameColor;
  double frameOpacity;
  double borderRadius;
  Color? logoColor;

  WatermarkData({
    this.deviceName = '',
    this.focalLength = '',
    this.aperture = '',
    this.shutterSpeed = '',
    this.iso = '',
    this.dateTime = '',
    this.brandId = 'none',
    this.fontFamily = 'Roboto',
    this.frameType = FrameType.whiteFrame,
    this.watermarkPosition = WatermarkPosition.belowImage,
    this.textColor = Colors.black,
    this.frameColor = Colors.white,
    this.frameOpacity = 1.0,
    this.borderRadius = 0,
    this.logoColor,
  });

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
    String? fontFamily,
    FrameType? frameType,
    WatermarkPosition? watermarkPosition,
    Color? textColor,
    Color? frameColor,
    double? frameOpacity,
    double? borderRadius,
    Color? logoColor,
    bool clearLogoColor = false,
  }) {
    return WatermarkData(
      deviceName: deviceName ?? this.deviceName,
      focalLength: focalLength ?? this.focalLength,
      aperture: aperture ?? this.aperture,
      shutterSpeed: shutterSpeed ?? this.shutterSpeed,
      iso: iso ?? this.iso,
      dateTime: dateTime ?? this.dateTime,
      brandId: brandId ?? this.brandId,
      fontFamily: fontFamily ?? this.fontFamily,
      frameType: frameType ?? this.frameType,
      watermarkPosition: watermarkPosition ?? this.watermarkPosition,
      textColor: textColor ?? this.textColor,
      frameColor: frameColor ?? this.frameColor,
      frameOpacity: frameOpacity ?? this.frameOpacity,
      borderRadius: borderRadius ?? this.borderRadius,
      logoColor: clearLogoColor ? null : (logoColor ?? this.logoColor),
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
  noFrame('No Frame');

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
