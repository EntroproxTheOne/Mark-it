import 'package:flutter/material.dart';
import 'package:mark_it/src/models/watermark_data.dart';

class WatermarkTemplate {
  final String id;
  final String name;
  final String category;
  final FrameType frameType;
  final WatermarkPosition position;
  final String? defaultBrandId;
  final Color defaultTextColor;
  final Color defaultFrameColor;
  final double defaultBorderRadius;
  final String defaultFont;

  const WatermarkTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.frameType,
    required this.position,
    this.defaultBrandId,
    this.defaultTextColor = Colors.black,
    this.defaultFrameColor = Colors.white,
    this.defaultBorderRadius = 0,
    this.defaultFont = 'Roboto',
  });

  WatermarkData applyTo(WatermarkData data) {
    return data.copyWith(
      frameType: frameType,
      watermarkPosition: position,
      textColor: defaultTextColor,
      frameColor: defaultFrameColor,
      borderRadius: defaultBorderRadius,
      fontFamily: defaultFont,
      brandId: defaultBrandId ?? data.brandId,
    );
  }
}

class WatermarkTemplates {
  static const blurFrames = 'Blur Frames';
  static const whiteFrames = 'White Frames';
  static const darkFrames = 'Dark Frames';
  static const glassFrames = 'Glass Frames';
  static const colorFrames = 'Color Frames';
  static const filmFrames = 'Film Frames';
  static const overlays = 'Overlays';

  static final List<String> categories = [
    blurFrames,
    whiteFrames,
    darkFrames,
    glassFrames,
    colorFrames,
    filmFrames,
    overlays,
  ];

  static final List<WatermarkTemplate> all = [
    // -- Blur Frames (like Vivo reference) --
    const WatermarkTemplate(
      id: 'blur_below',
      name: 'Blur + Logo Below',
      category: blurFrames,
      frameType: FrameType.blurFrame,
      position: WatermarkPosition.belowImage,
      defaultTextColor: Colors.black,
      defaultFrameColor: Colors.white,
      defaultBorderRadius: 16,
      defaultFont: 'Inter',
    ),
    const WatermarkTemplate(
      id: 'blur_above_below',
      name: 'Blur + Brand Top',
      category: blurFrames,
      frameType: FrameType.blurFrame,
      position: WatermarkPosition.aboveImage,
      defaultTextColor: Colors.black,
      defaultFrameColor: Colors.white,
      defaultBorderRadius: 16,
      defaultFont: 'Inter',
    ),
    const WatermarkTemplate(
      id: 'blur_overlay_br',
      name: 'Blur + Corner Info',
      category: blurFrames,
      frameType: FrameType.blurFrame,
      position: WatermarkPosition.overlayBottomRight,
      defaultTextColor: Colors.white,
      defaultFrameColor: Colors.white,
      defaultBorderRadius: 16,
      defaultFont: 'Inter',
    ),

    // -- White Frames (like Leica/Xiaomi classic) --
    const WatermarkTemplate(
      id: 'white_classic',
      name: 'Classic White',
      category: whiteFrames,
      frameType: FrameType.whiteFrame,
      position: WatermarkPosition.bottomBar,
      defaultTextColor: Colors.black,
      defaultFrameColor: Colors.white,
      defaultFont: 'Roboto',
    ),
    const WatermarkTemplate(
      id: 'white_below_center',
      name: 'White + Center Logo',
      category: whiteFrames,
      frameType: FrameType.whiteFrame,
      position: WatermarkPosition.belowImage,
      defaultTextColor: Colors.black,
      defaultFrameColor: Colors.white,
      defaultBorderRadius: 0,
      defaultFont: 'Inter',
    ),
    const WatermarkTemplate(
      id: 'white_rounded',
      name: 'White Rounded',
      category: whiteFrames,
      frameType: FrameType.whiteFrame,
      position: WatermarkPosition.belowImage,
      defaultTextColor: Colors.black,
      defaultFrameColor: Colors.white,
      defaultBorderRadius: 20,
      defaultFont: 'Poppins',
    ),

    // -- Dark Frames (like Canon/Pixel reference) --
    const WatermarkTemplate(
      id: 'black_classic',
      name: 'Black Classic',
      category: darkFrames,
      frameType: FrameType.blackFrame,
      position: WatermarkPosition.belowImage,
      defaultTextColor: Colors.white,
      defaultFrameColor: Colors.black,
      defaultFont: 'Inter',
    ),
    const WatermarkTemplate(
      id: 'darkgray_rounded',
      name: 'Dark Gray Rounded',
      category: darkFrames,
      frameType: FrameType.darkGrayFrame,
      position: WatermarkPosition.belowImage,
      defaultTextColor: Colors.white,
      defaultFrameColor: Color(0xFF1A2332),
      defaultBorderRadius: 20,
      defaultFont: 'Space Grotesk',
    ),
    const WatermarkTemplate(
      id: 'dark_overlay_bl',
      name: 'Dark + Overlay',
      category: darkFrames,
      frameType: FrameType.blackFrame,
      position: WatermarkPosition.overlayBottomLeft,
      defaultTextColor: Colors.white,
      defaultFrameColor: Colors.black,
      defaultBorderRadius: 16,
      defaultFont: 'Inter',
    ),

    // -- Glass Frames --
    const WatermarkTemplate(
      id: 'glass_below',
      name: 'Glass Below',
      category: glassFrames,
      frameType: FrameType.glassFrame,
      position: WatermarkPosition.belowImage,
      defaultTextColor: Colors.white,
      defaultFrameColor: Color(0x44FFFFFF),
      defaultBorderRadius: 20,
      defaultFont: 'Inter',
    ),
    const WatermarkTemplate(
      id: 'glass_overlay',
      name: 'Glass Overlay',
      category: glassFrames,
      frameType: FrameType.glassFrame,
      position: WatermarkPosition.overlayBottomRight,
      defaultTextColor: Colors.white,
      defaultFrameColor: Color(0x44FFFFFF),
      defaultBorderRadius: 16,
      defaultFont: 'Inter',
    ),

    // -- Color Frames --
    const WatermarkTemplate(
      id: 'color_contrast',
      name: 'Contrast Color',
      category: colorFrames,
      frameType: FrameType.colorFrame,
      position: WatermarkPosition.belowImage,
      defaultTextColor: Colors.white,
      defaultBorderRadius: 0,
      defaultFont: 'Poppins',
    ),
    const WatermarkTemplate(
      id: 'color_primary',
      name: 'Primary Color',
      category: colorFrames,
      frameType: FrameType.colorFrame,
      position: WatermarkPosition.bottomBar,
      defaultTextColor: Colors.white,
      defaultBorderRadius: 0,
      defaultFont: 'Inter',
    ),

    // -- Film Frames --
    const WatermarkTemplate(
      id: 'film_strip',
      name: 'Film Strip',
      category: filmFrames,
      frameType: FrameType.filmFrame,
      position: WatermarkPosition.belowImage,
      defaultTextColor: Color(0xFFFF6B35),
      defaultFrameColor: Color(0xFF1A1A1A),
      defaultFont: 'Source Code Pro',
    ),
    const WatermarkTemplate(
      id: 'film_vintage',
      name: 'Vintage Film',
      category: filmFrames,
      frameType: FrameType.filmFrame,
      position: WatermarkPosition.bottomBar,
      defaultTextColor: Color(0xFFCCAA77),
      defaultFrameColor: Color(0xFF0D0D0D),
      defaultFont: 'IBM Plex Mono',
    ),

    // -- Overlays (on-image, no frame) --
    const WatermarkTemplate(
      id: 'overlay_bl',
      name: 'Bottom Left',
      category: overlays,
      frameType: FrameType.noFrame,
      position: WatermarkPosition.overlayBottomLeft,
      defaultTextColor: Colors.white,
      defaultFont: 'Inter',
    ),
    const WatermarkTemplate(
      id: 'overlay_br',
      name: 'Bottom Right',
      category: overlays,
      frameType: FrameType.noFrame,
      position: WatermarkPosition.overlayBottomRight,
      defaultTextColor: Colors.white,
      defaultFont: 'Inter',
    ),
    const WatermarkTemplate(
      id: 'overlay_center',
      name: 'Center Logo',
      category: overlays,
      frameType: FrameType.noFrame,
      position: WatermarkPosition.overlayCenter,
      defaultTextColor: Colors.white,
      defaultFont: 'Inter',
    ),
    const WatermarkTemplate(
      id: 'overlay_tl',
      name: 'Top Left',
      category: overlays,
      frameType: FrameType.noFrame,
      position: WatermarkPosition.overlayTopLeft,
      defaultTextColor: Colors.white,
      defaultFont: 'Inter',
    ),
    const WatermarkTemplate(
      id: 'overlay_tr',
      name: 'Top Right',
      category: overlays,
      frameType: FrameType.noFrame,
      position: WatermarkPosition.overlayTopRight,
      defaultTextColor: Colors.white,
      defaultFont: 'Inter',
    ),
  ];

  static List<WatermarkTemplate> byCategory(String category) =>
      all.where((t) => t.category == category).toList();
}
