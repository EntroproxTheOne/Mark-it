import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mark_it/src/models/brand_kit.dart';
import 'package:mark_it/src/models/watermark_data.dart';
import 'package:mark_it/src/services/color_service.dart';
import 'package:mark_it/src/widgets/info_section.dart';

class WatermarkPreview extends StatelessWidget {
  const WatermarkPreview({
    super.key,
    required this.imageFile,
    required this.data,
    this.previewKey,
    this.palette,
  });

  final File imageFile;
  final WatermarkData data;
  final GlobalKey? previewKey;
  final ImagePalette? palette;

  BrandKit? get _brand => BrandKits.findById(data.brandId);

  Color get _resolvedFrameColor {
    if (data.frameType == FrameType.colorFrame && palette != null) {
      return palette!.dominant;
    }
    return data.frameColor;
  }

  Color get _resolvedTextColor {
    if (data.frameType == FrameType.colorFrame && palette != null) {
      return palette!.contrastTextColor;
    }
    return data.textColor;
  }

  Widget _mainImage({BoxFit fit = BoxFit.contain}) {
    return Image.file(
      imageFile,
      fit: fit,
      cacheWidth: 1200,
      errorBuilder: (_, e, __) => Container(
        width: 300,
        height: 400,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _blurBgImage() {
    return Image.file(
      imageFile,
      fit: BoxFit.cover,
      cacheWidth: 200,
      errorBuilder: (_, __, ___) => const SizedBox.expand(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: previewKey,
      child: _buildLayout(),
    );
  }

  Widget _buildLayout() {
    return switch (data.frameType) {
      FrameType.blurFrame => _blurFrame(),
      FrameType.whiteFrame => _solidFrame(Colors.white),
      FrameType.blackFrame => _solidFrame(Colors.black),
      FrameType.darkGrayFrame => _solidFrame(const Color(0xFF1A2332)),
      FrameType.glassFrame => _glassFrame(),
      FrameType.colorFrame => _solidFrame(_resolvedFrameColor),
      FrameType.vignetteFrame => _vignetteFrame(),
      FrameType.filmFrame => _filmFrame(),
      FrameType.noFrame => _noFrame(),
    };
  }

  // ── SOLID FRAME ─────────────────────────────────────────────────────
  Widget _solidFrame(Color bg) {
    final textC = _resolvedTextColor;
    return Container(
      color: bg.withValues(alpha: data.frameOpacity),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (data.watermarkPosition == WatermarkPosition.aboveImage)
            _aboveInfo(textColor: textC),
          Padding(
            padding: EdgeInsets.all(data.borderRadius > 0 ? 16 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(data.borderRadius),
              child: _isOverlayPosition
                  ? _imageWithOverlay(textC)
                  : _mainImage(),
            ),
          ),
          if (data.watermarkPosition == WatermarkPosition.belowImage)
            _belowInfo(textC),
          if (data.watermarkPosition == WatermarkPosition.bottomBar)
            _bottomBar(bg, textC),
        ],
      ),
    );
  }

  // ── BLUR FRAME ──────────────────────────────────────────────────────
  Widget _blurFrame() {
    final textC = _resolvedTextColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(data.borderRadius > 0 ? 4 : 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: _blurBgImage(),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.15)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.watermarkPosition == WatermarkPosition.aboveImage)
                _aboveInfo(textColor: textC),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(data.borderRadius),
                  child: _isOverlayPosition
                      ? _imageWithOverlay(textC)
                      : _mainImage(),
                ),
              ),
              if (data.watermarkPosition == WatermarkPosition.belowImage)
                _belowInfo(textC),
              if (data.watermarkPosition == WatermarkPosition.bottomBar)
                _bottomBar(Colors.transparent, textC),
            ],
          ),
          if (_isOverlayPosition) _overlayWidget(textColor: textC),
        ],
      ),
    );
  }

  // ── GLASS FRAME ─────────────────────────────────────────────────────
  Widget _glassFrame() {
    final textC = _resolvedTextColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(data.borderRadius > 0 ? 4 : 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: _blurBgImage(),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.1)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.watermarkPosition == WatermarkPosition.aboveImage)
                _glassInfoBar(textC),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(data.borderRadius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        data.borderRadius > 0 ? data.borderRadius - 1 : 0),
                    child: _isOverlayPosition
                        ? _imageWithOverlay(textC)
                        : _mainImage(),
                  ),
                ),
              ),
              if (data.watermarkPosition == WatermarkPosition.belowImage ||
                  data.watermarkPosition == WatermarkPosition.bottomBar)
                _glassInfoBar(textC),
              if (data.watermarkPosition == WatermarkPosition.belowImage ||
                  data.watermarkPosition == WatermarkPosition.bottomBar ||
                  data.watermarkPosition == WatermarkPosition.aboveImage)
                const SizedBox(height: 8),
            ],
          ),
          if (_isOverlayPosition) _overlayWidget(textColor: textC),
        ],
      ),
    );
  }

  Widget _glassInfoBar(Color textC) {
    final isBar = data.watermarkPosition == WatermarkPosition.bottomBar;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InfoSection(
              data: data.copyWith(textColor: textC),
              brand: _brand,
              layout: isBar ? InfoLayout.row : InfoLayout.centered,
              compact: true,
            ),
          ),
        ),
      ),
    );
  }

  // ── VIGNETTE FRAME ──────────────────────────────────────────────────
  Widget _vignetteFrame() {
    final textC = _resolvedTextColor;
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data.watermarkPosition == WatermarkPosition.aboveImage)
              _aboveInfo(textColor: textC),
            _mainImage(),
            if (data.watermarkPosition == WatermarkPosition.belowImage)
              _belowInfo(textC),
            if (data.watermarkPosition == WatermarkPosition.bottomBar)
              _bottomBar(Colors.black, textC),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
        if (_isOverlayPosition)
          Positioned.fill(child: _overlayWidget(textColor: Colors.white)),
      ],
    );
  }

  // ── FILM FRAME ──────────────────────────────────────────────────────
  Widget _filmFrame() {
    final textC = _resolvedTextColor;
    return Container(
      color: data.frameColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _filmSprocketRow(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _isOverlayPosition
                ? _imageWithOverlay(textC)
                : _mainImage(),
          ),
          _filmSprocketRow(),
          if (data.watermarkPosition == WatermarkPosition.aboveImage ||
              data.watermarkPosition == WatermarkPosition.belowImage ||
              data.watermarkPosition == WatermarkPosition.bottomBar ||
              !_isOverlayPosition)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    data.dateTime.isNotEmpty ? data.dateTime : 'KODAK 400',
                    style: TextStyle(
                      color: textC,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  if (_brand != null)
                    _brand!.logo(24, color: data.logoColor ?? textC),
                  const SizedBox(width: 8),
                  Text(
                    data.exifString,
                    style: TextStyle(
                      color: textC.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _filmSprocketRow() {
    return Container(
      height: 14,
      color: data.frameColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          20,
          (_) => Container(
            width: 8,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }

  // ── NO FRAME ────────────────────────────────────────────────────────
  Widget _noFrame() {
    final textC = _resolvedTextColor;
    if (_isOverlayPosition) {
      return _imageWithOverlay(textC);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data.watermarkPosition == WatermarkPosition.aboveImage)
          _aboveInfo(textColor: textC),
        _mainImage(),
        if (data.watermarkPosition == WatermarkPosition.belowImage)
          _belowInfo(textC),
        if (data.watermarkPosition == WatermarkPosition.bottomBar)
          _bottomBar(Colors.transparent, textC),
      ],
    );
  }

  // ── SHARED HELPERS ──────────────────────────────────────────────────
  Widget _imageWithOverlay(Color textC) {
    return Stack(
      children: [
        _mainImage(),
        if (_isOverlayPosition)
          Positioned.fill(child: _overlayWidget(textColor: textC)),
      ],
    );
  }

  Widget _aboveInfo({Color? textColor}) {
    final c = textColor ?? _resolvedTextColor;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: _brand != null
          ? _brand!.logo(36, color: data.logoColor ?? c)
          : Text(
              data.deviceName,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
    );
  }

  Widget _belowInfo(Color textC) {
    return InfoSection(
      data: data.copyWith(textColor: textC),
      brand: _brand,
      layout: InfoLayout.centered,
    );
  }

  Widget _bottomBar(Color bg, Color textC) {
    return Container(
      color: bg == Colors.transparent ? null : bg,
      child: InfoSection(
        data: data.copyWith(textColor: textC),
        brand: _brand,
        layout: InfoLayout.row,
      ),
    );
  }

  bool get _isOverlayPosition =>
      data.watermarkPosition == WatermarkPosition.overlayBottomLeft ||
      data.watermarkPosition == WatermarkPosition.overlayBottomRight ||
      data.watermarkPosition == WatermarkPosition.overlayTopLeft ||
      data.watermarkPosition == WatermarkPosition.overlayTopRight ||
      data.watermarkPosition == WatermarkPosition.overlayCenter;

  Widget _overlayWidget({Color? textColor}) {
    final c = textColor ?? data.textColor;
    final align = switch (data.watermarkPosition) {
      WatermarkPosition.overlayBottomLeft => Alignment.bottomLeft,
      WatermarkPosition.overlayBottomRight => Alignment.bottomRight,
      WatermarkPosition.overlayTopLeft => Alignment.topLeft,
      WatermarkPosition.overlayTopRight => Alignment.topRight,
      WatermarkPosition.overlayCenter => Alignment.center,
      _ => Alignment.bottomRight,
    };

    const shadow = [Shadow(blurRadius: 6, color: Colors.black54)];

    if (data.watermarkPosition == WatermarkPosition.overlayCenter) {
      return Align(
        alignment: align,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_brand != null)
              _brand!.logo(40, color: data.logoColor ?? c),
            if (_brand != null) ...[
              const SizedBox(height: 4),
              Text(
                _brand!.tagline,
                style: TextStyle(
                  color: c.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  shadows: shadow,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: align.x < 0
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_brand != null) ...[
                  _brand!.logo(18, color: data.logoColor ?? c),
                  const SizedBox(width: 5),
                ],
                Text(
                  data.deviceName,
                  style: TextStyle(
                    color: c,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    shadows: shadow,
                  ),
                ),
              ],
            ),
            if (data.exifString.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(
                data.exifString,
                style: TextStyle(
                  color: c.withValues(alpha: 0.8),
                  fontSize: 9,
                  shadows: shadow,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
