import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mark_it/src/models/watermark_data.dart';

class PresetService {
  static const _lastUsedKey = 'last_used_watermark';
  static const _autoApplyKey = 'auto_apply_enabled';

  static Future<void> saveLastUsed(WatermarkData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUsedKey, jsonEncode(_toMap(data)));
  }

  static Future<WatermarkData?> loadLastUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_lastUsedKey);
    if (json == null) return null;
    try {
      return _fromMap(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isAutoApplyEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoApplyKey) ?? false;
  }

  static Future<void> setAutoApply(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoApplyKey, enabled);
  }

  static Map<String, dynamic> _toMap(WatermarkData d) => {
        'brandId': d.brandId,
        'fontFamily': d.fontFamily,
        'frameType': d.frameType.index,
        'position': d.watermarkPosition.index,
        'textColor': d.textColor.toARGB32(),
        'frameColor': d.frameColor.toARGB32(),
        'frameOpacity': d.frameOpacity,
        'borderRadius': d.borderRadius,
        'logoColor': d.logoColor?.toARGB32(),
      };

  static WatermarkData _fromMap(Map<String, dynamic> m) => WatermarkData(
        brandId: m['brandId'] ?? 'none',
        fontFamily: m['fontFamily'] ?? 'Roboto',
        frameType: FrameType.values[m['frameType'] ?? 0],
        watermarkPosition: WatermarkPosition.values[m['position'] ?? 0],
        textColor: Color(m['textColor'] ?? 0xFF000000),
        frameColor: Color(m['frameColor'] ?? 0xFFFFFFFF),
        frameOpacity: (m['frameOpacity'] ?? 1.0).toDouble(),
        borderRadius: (m['borderRadius'] ?? 0.0).toDouble(),
        logoColor: m['logoColor'] != null ? Color(m['logoColor']) : null,
      );
}

class WatermarkPreset {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final FrameType frameType;
  final WatermarkPosition position;
  final Color textColor;
  final Color frameColor;
  final double borderRadius;
  final String fontFamily;

  const WatermarkPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.frameType,
    required this.position,
    this.textColor = Colors.black,
    this.frameColor = Colors.white,
    this.borderRadius = 0,
    this.fontFamily = 'Roboto',
  });

  WatermarkData applyTo(WatermarkData data) => data.copyWith(
        frameType: frameType,
        watermarkPosition: position,
        textColor: textColor,
        frameColor: frameColor,
        borderRadius: borderRadius,
        fontFamily: fontFamily,
      );
}

class RecommendedPresets {
  static const all = <WatermarkPreset>[
    WatermarkPreset(
      id: 'leica_classic',
      name: 'Leica Classic',
      description: 'White frame with centered logo and EXIF, clean look',
      icon: Icons.camera_rounded,
      frameType: FrameType.whiteFrame,
      position: WatermarkPosition.belowImage,
      textColor: Colors.black,
      frameColor: Colors.white,
      fontFamily: 'Inter',
    ),
    WatermarkPreset(
      id: 'minimal_bar',
      name: 'Minimal Bar',
      description: 'Slim bottom bar with logo, device name, and settings',
      icon: Icons.view_agenda_rounded,
      frameType: FrameType.whiteFrame,
      position: WatermarkPosition.bottomBar,
      textColor: Colors.black,
      frameColor: Colors.white,
      fontFamily: 'Inter',
    ),
    WatermarkPreset(
      id: 'dark_pro',
      name: 'Dark Pro',
      description: 'Dark background with white text, professional feel',
      icon: Icons.dark_mode_rounded,
      frameType: FrameType.blackFrame,
      position: WatermarkPosition.belowImage,
      textColor: Colors.white,
      frameColor: Colors.black,
      fontFamily: 'Space Grotesk',
    ),
    WatermarkPreset(
      id: 'blur_dreamy',
      name: 'Blur Dreamy',
      description: 'Blurred background with rounded image and info below',
      icon: Icons.blur_on_rounded,
      frameType: FrameType.blurFrame,
      position: WatermarkPosition.belowImage,
      textColor: Colors.black,
      frameColor: Colors.white,
      borderRadius: 16,
      fontFamily: 'Poppins',
    ),
    WatermarkPreset(
      id: 'glass_modern',
      name: 'Glass Modern',
      description: 'Frosted glass effect with floating info card',
      icon: Icons.auto_awesome_rounded,
      frameType: FrameType.glassFrame,
      position: WatermarkPosition.belowImage,
      textColor: Colors.white,
      borderRadius: 20,
      fontFamily: 'Outfit',
    ),
    WatermarkPreset(
      id: 'vignette_mood',
      name: 'Vignette Mood',
      description: 'Dark edges fade with subtle corner watermark',
      icon: Icons.vignette_rounded,
      frameType: FrameType.vignetteFrame,
      position: WatermarkPosition.overlayBottomRight,
      textColor: Colors.white,
      fontFamily: 'Inter',
    ),
    WatermarkPreset(
      id: 'film_retro',
      name: 'Film Retro',
      description: 'Film strip sprockets with vintage color text',
      icon: Icons.local_movies_rounded,
      frameType: FrameType.filmFrame,
      position: WatermarkPosition.belowImage,
      textColor: Color(0xFFFF6B35),
      frameColor: Color(0xFF1A1A1A),
      fontFamily: 'Source Code Pro',
    ),
    WatermarkPreset(
      id: 'overlay_subtle',
      name: 'Subtle Overlay',
      description: 'No frame, just a clean logo and text in corner',
      icon: Icons.photo_rounded,
      frameType: FrameType.noFrame,
      position: WatermarkPosition.overlayBottomRight,
      textColor: Colors.white,
      fontFamily: 'Inter',
    ),
    WatermarkPreset(
      id: 'center_stamp',
      name: 'Center Stamp',
      description: 'Large centered logo with tagline, no frame',
      icon: Icons.center_focus_strong_rounded,
      frameType: FrameType.noFrame,
      position: WatermarkPosition.overlayCenter,
      textColor: Colors.white,
      fontFamily: 'Montserrat',
    ),
    WatermarkPreset(
      id: 'rounded_white',
      name: 'Rounded White',
      description: 'White frame with rounded corners, modern feel',
      icon: Icons.rounded_corner_rounded,
      frameType: FrameType.whiteFrame,
      position: WatermarkPosition.belowImage,
      textColor: Colors.black,
      frameColor: Colors.white,
      borderRadius: 20,
      fontFamily: 'Poppins',
    ),
    WatermarkPreset(
      id: 'dark_gray_elegant',
      name: 'Dark Elegant',
      description: 'Dark gray frame with rounded image, elegant typography',
      icon: Icons.square_rounded,
      frameType: FrameType.darkGrayFrame,
      position: WatermarkPosition.belowImage,
      textColor: Colors.white,
      frameColor: Color(0xFF1A2332),
      borderRadius: 20,
      fontFamily: 'Playfair Display',
    ),
    WatermarkPreset(
      id: 'blur_brand_top',
      name: 'Brand Top',
      description: 'Blurred background with brand logo above the image',
      icon: Icons.vertical_align_top_rounded,
      frameType: FrameType.blurFrame,
      position: WatermarkPosition.aboveImage,
      textColor: Colors.black,
      borderRadius: 16,
      fontFamily: 'DM Sans',
    ),
    WatermarkPreset(
      id: 'color_pop',
      name: 'Color Pop',
      description: 'Auto-extracted dominant color as frame background',
      icon: Icons.color_lens_rounded,
      frameType: FrameType.colorFrame,
      position: WatermarkPosition.belowImage,
      textColor: Colors.white,
      fontFamily: 'Quicksand',
    ),
    WatermarkPreset(
      id: 'overlay_top_left',
      name: 'Corner Badge',
      description: 'Tiny logo and info in top-left corner',
      icon: Icons.north_west_rounded,
      frameType: FrameType.noFrame,
      position: WatermarkPosition.overlayTopLeft,
      textColor: Colors.white,
      fontFamily: 'Manrope',
    ),
    WatermarkPreset(
      id: 'film_vintage_gold',
      name: 'Vintage Gold',
      description: 'Film strip with warm gold text on black',
      icon: Icons.movie_filter_rounded,
      frameType: FrameType.filmFrame,
      position: WatermarkPosition.belowImage,
      textColor: Color(0xFFCCAA77),
      frameColor: Color(0xFF0D0D0D),
      fontFamily: 'Playfair Display',
    ),
  ];
}
