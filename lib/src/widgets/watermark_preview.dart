import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mark_it/src/models/brand_kit.dart';
import 'package:mark_it/src/models/watermark_data.dart';
import 'package:mark_it/src/services/color_service.dart';
import 'package:mark_it/src/services/font_service.dart';
import 'package:mark_it/src/widgets/info_section.dart';

class WatermarkPreview extends StatefulWidget {
  const WatermarkPreview({
    super.key,
    required this.imageFile,
    required this.data,
    required this.maxContentWidth,
    this.previewKey,
    this.palette,
    this.fullResolutionDecode = false,
    this.lightweightDecode = false,
  });

  final File imageFile;
  final WatermarkData data;
  final double maxContentWidth;
  final GlobalKey? previewKey;
  final ImagePalette? palette;
  /// When true, loads the photo without downscaling (use briefly during export).
  final bool fullResolutionDecode;
  /// Small-card previews (e.g. home demos): lower decode size, less GPU/RAM.
  final bool lightweightDecode;

  @override
  State<WatermarkPreview> createState() => _WatermarkPreviewState();
}

class _WatermarkPreviewState extends State<WatermarkPreview> {
  int? _natW;
  int? _natH;

  BrandKit? get _brand => BrandKits.findById(widget.data.brandId);

  double get _contentW =>
      widget.maxContentWidth > 0 ? widget.maxContentWidth : 360;

  double get _layoutScale =>
      (_contentW / 1080.0).clamp(0.55, 1.45);

  /// User-controlled multiplier for logo + text block (grouped).
  double get _groupScale =>
      widget.data.watermarkGroupScale.clamp(0.25, 3.0);

  /// Passed into [InfoSection] so brand, device, subtitle, and EXIF scale together.
  double get _infoLayoutScale => _layoutScale * _groupScale;

  double _s(double px) => px * _layoutScale;

  /// Like [_s] but includes grouped watermark scale (overlays, film strip text, etc.).
  double _g(double px) => px * _layoutScale * _groupScale;

  double get _brandS => widget.data.brandLogoScale.clamp(0.5, 2.0);
  double get _infoS => widget.data.infoTextScale.clamp(0.5, 2.0);

  double _gLogo(double px) => px * _layoutScale * _groupScale * _brandS;
  double _gTxt(double px) => px * _layoutScale * _groupScale * _infoS;

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  @override
  void didUpdateWidget(WatermarkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageFile.path != widget.imageFile.path) {
      _resolveImageSize();
    }
  }

  void _resolveImageSize() {
    _natW = null;
    _natH = null;
    // Cheap decode (downscaled) for aspect ratio — avoids a full-resolution
    // [FileImage] probe that spikes CPU/RAM on large camera files.
    Future(() async {
      try {
        final bytes = await widget.imageFile.readAsBytes();
        if (!mounted) return;
        final codec = await instantiateImageCodec(bytes, targetWidth: 160);
        final frame = await codec.getNextFrame();
        final img = frame.image;
        if (!mounted) {
          img.dispose();
          codec.dispose();
          return;
        }
        setState(() {
          _natW = img.width;
          _natH = img.height;
        });
        img.dispose();
        codec.dispose();
      } catch (_) {}
    });
  }

  Color get _resolvedFrameColor {
    if (widget.data.frameType == FrameType.colorFrame && widget.palette != null) {
      return widget.palette!.dominant;
    }
    return widget.data.frameColor;
  }

  Color get _resolvedTextColor {
    if (widget.data.frameType == FrameType.colorFrame && widget.palette != null) {
      return widget.palette!.contrastTextColor;
    }
    return widget.data.textColor;
  }

  int? get _cacheDecodeWidth {
    if (widget.fullResolutionDecode) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final px = (_contentW * dpr).round();
    if (widget.lightweightDecode) {
      // Never return null: a full-res decode before [_natW] arrives was a main
      // source of jank in home thumbnails / lists.
      return px.clamp(240, 400);
    }
    final w = _natW;
    if (w == null) {
      return px.clamp(720, 2048);
    }
    return px.clamp(720, 8192);
  }

  Widget _mainImage({BoxFit fit = BoxFit.contain}) {
    final cw = _cacheDecodeWidth;
    return Image.file(
      widget.imageFile,
      fit: fit,
      cacheWidth: cw,
      filterQuality: widget.fullResolutionDecode
          ? FilterQuality.high
          : widget.lightweightDecode
              ? FilterQuality.low
              : FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: _contentW,
        height: _contentW * 4 / 3,
        child: ColoredBox(
          color: Colors.grey.shade300,
          child: const Center(
            child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _blurBgImage() {
    final int? cw = widget.fullResolutionDecode
        ? null
        : (_s(200)).round().clamp(120, 600);
    return Image.file(
      widget.imageFile,
      fit: BoxFit.cover,
      cacheWidth: cw,
      filterQuality:
          widget.fullResolutionDecode ? FilterQuality.high : FilterQuality.low,
      errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
    );
  }

  Widget _photoColumn(Widget imageChild) {
    final w = _natW ?? 3;
    final h = _natH ?? 4;
    return SizedBox(
      width: _contentW,
      child: AspectRatio(
        aspectRatio: w / h,
        child: imageChild,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.previewKey,
      child: _buildLayout(),
    );
  }

  Widget _buildLayout() {
    final d = widget.data;
    return switch (d.frameType) {
      FrameType.blurFrame => _blurFrame(),
      FrameType.whiteFrame => _solidFrame(Colors.white),
      FrameType.blackFrame => _solidFrame(Colors.black),
      FrameType.darkGrayFrame => _solidFrame(const Color(0xFF1A2332)),
      FrameType.glassFrame => _glassFrame(),
      FrameType.colorFrame => _solidFrame(_resolvedFrameColor),
      FrameType.vignetteFrame => _vignetteFrame(),
      FrameType.filmFrame => _filmFrame(),
      FrameType.noFrame => _noFrame(),
      FrameType.whiteChinSlip => _chinSlipFrame(_ChinSlipStyle.white),
      FrameType.blackChinSlip => _chinSlipFrame(_ChinSlipStyle.black),
      FrameType.blurChinSlip => _chinSlipFrame(_ChinSlipStyle.blur),
    };
  }

  /// Bottom “chin” strip: row with device | divider | brand logo, then EXIF line.
  Widget _chinSlipFrame(_ChinSlipStyle style) {
    final d = widget.data;
    final (Color solidBg, Color fg) = switch (style) {
      _ChinSlipStyle.white => (Colors.white, Colors.black),
      _ChinSlipStyle.black => (Colors.black, Colors.white),
      _ChinSlipStyle.blur => (Colors.transparent, Colors.white),
    };

    Widget photoBlock() => Padding(
          padding: EdgeInsets.all(d.borderRadius > 0 ? _s(12) : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(d.borderRadius),
            child: _isOverlayPosition
                ? _photoColumn(_imageWithOverlay(fg))
                : _photoColumn(_mainImage()),
          ),
        );

    Widget slipContent({required Widget child}) {
      if (style == _ChinSlipStyle.blur) {
        final barH = _chinSlipBarHeight();
        return SizedBox(
          width: _contentW,
          height: barH,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            fit: StackFit.expand,
            children: [
              _chinSlipBlurBackdrop(barH),
              ColoredBox(color: Colors.black.withValues(alpha: 0.32)),
              child,
            ],
          ),
        );
      }
      return Container(
        width: _contentW,
        color: solidBg.withValues(alpha: d.frameOpacity),
        child: child,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (d.watermarkPosition == WatermarkPosition.aboveImage)
          _aboveInfo(textColor: fg),
        photoBlock(),
        slipContent(child: _chinSlipContent(fg)),
      ],
    );
  }

  /// Blurred strip sampled from the bottom of the photo.
  Widget _chinSlipBlurBackdrop(double barH) {
    final cw = _cacheDecodeWidth;
    return ClipRect(
      child: SizedBox(
        height: barH,
        width: _contentW,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: OverflowBox(
            maxHeight: barH * 5,
            minHeight: barH * 5,
            alignment: Alignment.bottomCenter,
            child: Image.file(
              widget.imageFile,
              width: _contentW,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              cacheWidth: cw,
              filterQuality: widget.fullResolutionDecode
                  ? FilterQuality.high
                  : FilterQuality.medium,
              errorBuilder: (_, __, ___) =>
                  ColoredBox(color: Colors.grey.shade800),
            ),
          ),
        ),
      ),
    );
  }

  double _chinSlipBarHeight() {
    final d = widget.data;
    final t = _infoLayoutScale * d.infoTextScale.clamp(0.5, 2.0);
    final hasExif = d.exifString.isNotEmpty;
    var base = 52.0 + (hasExif ? 22.0 : 6.0);
    if (d.subtitle.isNotEmpty) base += 14;
    return base * t.clamp(0.85, 1.35);
  }

  Widget _chinSlipContent(Color fg) {
    final d = widget.data;
    final font = FontService.getFont(d.fontFamily, color: fg);
    final tScale = _infoLayoutScale * d.infoTextScale.clamp(0.5, 2.0);
    final lScale = _infoLayoutScale * d.brandLogoScale.clamp(0.5, 2.0);
    double ts(double px) => px * tScale;
    double ls(double px) => px * lScale;

    final dividerColor = fg.withValues(alpha: 0.35);
    final padH = ts(18);
    final padV = ts(14);
    final showMidDivider =
        d.deviceName.isNotEmpty && _brand != null;

    Widget topRow() {
      if (d.deviceName.isEmpty && _brand == null) {
        return const SizedBox.shrink();
      }
      if (d.deviceName.isEmpty && _brand != null) {
        return Center(
          child: _brand!.logo(ls(30), color: d.logoColor ?? fg),
        );
      }
      if (_brand == null) {
        return Text(
          d.deviceName,
          style: font.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: ts(15),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  d.deviceName,
                  style: font.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: ts(15),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (d.subtitle.isNotEmpty) ...[
                  SizedBox(height: ts(4)),
                  Text(
                    d.subtitle,
                    style: font.copyWith(
                      fontSize: ts(12),
                      color: fg.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (showMidDivider) ...[
            Container(
              width: 1,
              height: ts(30),
              margin: EdgeInsets.symmetric(horizontal: ts(14)),
              color: dividerColor,
            ),
            _brand!.logo(ls(28), color: d.logoColor ?? fg),
          ],
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          topRow(),
          if (d.exifString.isNotEmpty) ...[
            SizedBox(height: ts(10)),
            Text(
              d.exifString,
              textAlign: TextAlign.center,
              style: font.copyWith(
                fontSize: ts(12),
                color: fg.withValues(alpha: 0.88),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.15,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _solidFrame(Color bg) {
    final textC = _resolvedTextColor;
    final d = widget.data;
    return Container(
      color: bg.withValues(alpha: d.frameOpacity),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (d.watermarkPosition == WatermarkPosition.aboveImage)
            _aboveInfo(textColor: textC),
          Padding(
            padding: EdgeInsets.all(d.borderRadius > 0 ? _s(16) : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(d.borderRadius),
              child: _isOverlayPosition
                  ? _photoColumn(_imageWithOverlay(textC))
                  : _photoColumn(_mainImage()),
            ),
          ),
          if (d.watermarkPosition == WatermarkPosition.belowImage)
            _belowInfo(textC),
          if (d.watermarkPosition == WatermarkPosition.bottomBar)
            _bottomBar(bg, textC),
        ],
      ),
    );
  }

  Widget _blurFrame() {
    final textC = _resolvedTextColor;
    final d = widget.data;
    return ClipRRect(
      borderRadius: BorderRadius.circular(d.borderRadius > 0 ? 4 : 0),
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
              if (d.watermarkPosition == WatermarkPosition.aboveImage)
                _aboveInfo(textColor: textC),
              Padding(
                padding: EdgeInsets.all(_s(20)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(d.borderRadius),
                  child: _isOverlayPosition
                      ? _photoColumn(_imageWithOverlay(textC))
                      : _photoColumn(_mainImage()),
                ),
              ),
              if (d.watermarkPosition == WatermarkPosition.belowImage)
                _belowInfo(textC),
              if (d.watermarkPosition == WatermarkPosition.bottomBar)
                _bottomBar(Colors.transparent, textC),
            ],
          ),
          if (_isOverlayPosition) _overlayWidget(textColor: textC),
        ],
      ),
    );
  }

  Widget _glassFrame() {
    final textC = _resolvedTextColor;
    final d = widget.data;
    return ClipRRect(
      borderRadius: BorderRadius.circular(d.borderRadius > 0 ? 4 : 0),
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
              if (d.watermarkPosition == WatermarkPosition.aboveImage)
                _glassInfoBar(textC),
              Padding(
                padding: EdgeInsets.all(_s(20)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(d.borderRadius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        d.borderRadius > 0 ? d.borderRadius - 1 : 0),
                    child: _isOverlayPosition
                        ? _photoColumn(_imageWithOverlay(textC))
                        : _photoColumn(_mainImage()),
                  ),
                ),
              ),
              if (d.watermarkPosition == WatermarkPosition.belowImage ||
                  d.watermarkPosition == WatermarkPosition.bottomBar)
                _glassInfoBar(textC),
              if (d.watermarkPosition == WatermarkPosition.belowImage ||
                  d.watermarkPosition == WatermarkPosition.bottomBar ||
                  d.watermarkPosition == WatermarkPosition.aboveImage)
                SizedBox(height: _s(8)),
            ],
          ),
          if (_isOverlayPosition) _overlayWidget(textColor: textC),
        ],
      ),
    );
  }

  Widget _glassInfoBar(Color textC) {
    final d = widget.data;
    final isBar = d.watermarkPosition == WatermarkPosition.bottomBar;
    final glassW = (_contentW - _s(40)).clamp(80.0, 4000.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _s(20), vertical: _s(4)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_s(12)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: glassW,
            padding: EdgeInsets.all(_s(10)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(_s(12)),
            ),
            child: InfoSection(
              data: d.copyWith(textColor: textC),
              brand: _brand,
              layout: isBar ? InfoLayout.row : InfoLayout.centered,
              compact: true,
              layoutScale: _infoLayoutScale,
              contentWidth: glassW,
            ),
          ),
        ),
      ),
    );
  }

  Widget _vignetteFrame() {
    final textC = _resolvedTextColor;
    final d = widget.data;
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (d.watermarkPosition == WatermarkPosition.aboveImage)
              _aboveInfo(textColor: textC),
            _photoColumn(_mainImage()),
            if (d.watermarkPosition == WatermarkPosition.belowImage)
              _belowInfo(textC),
            if (d.watermarkPosition == WatermarkPosition.bottomBar)
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

  Widget _filmFrame() {
    final textC = _resolvedTextColor;
    final d = widget.data;
    return Container(
      color: d.frameColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _filmSprocketRow(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _s(12)),
            child: _isOverlayPosition
                ? _photoColumn(_imageWithOverlay(textC))
                : _photoColumn(_mainImage()),
          ),
          _filmSprocketRow(),
          if (d.watermarkPosition == WatermarkPosition.aboveImage ||
              d.watermarkPosition == WatermarkPosition.belowImage ||
              d.watermarkPosition == WatermarkPosition.bottomBar ||
              !_isOverlayPosition)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _s(12), vertical: _s(8)),
              child: SizedBox(
                width: _contentW - _s(24),
                child: Row(
                  children: [
                    Text(
                      d.dateTime.isNotEmpty ? d.dateTime : 'KODAK 400',
                      style: TextStyle(
                        color: textC,
                        fontSize: _gTxt(10),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    if (_brand != null)
                      _brand!.logo(_gLogo(24), color: d.logoColor ?? textC),
                    SizedBox(width: _g(8)),
                    Text(
                      d.exifString,
                      style: TextStyle(
                        color: textC.withValues(alpha: 0.8),
                        fontSize: _gTxt(10),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filmSprocketRow() {
    return Container(
      height: _s(14),
      color: widget.data.frameColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          20,
          (_) => Container(
            width: _s(8),
            height: _s(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _noFrame() {
    final textC = _resolvedTextColor;
    final d = widget.data;
    if (_isOverlayPosition) {
      return _photoColumn(_imageWithOverlay(textC));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (d.watermarkPosition == WatermarkPosition.aboveImage)
          _aboveInfo(textColor: textC),
        _photoColumn(_mainImage()),
        if (d.watermarkPosition == WatermarkPosition.belowImage)
          _belowInfo(textC),
        if (d.watermarkPosition == WatermarkPosition.bottomBar)
          _bottomBar(Colors.transparent, textC),
      ],
    );
  }

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
    final d = widget.data;
    return Padding(
      padding: EdgeInsets.only(top: _s(12), bottom: _s(4)),
      child: _brand != null
          ? _brand!.logo(_gLogo(36), color: d.logoColor ?? c)
          : Text(
              d.deviceName,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w700,
                fontSize: _gTxt(15),
              ),
            ),
    );
  }

  Widget _belowInfo(Color textC) {
    final d = widget.data;
    return InfoSection(
      data: d.copyWith(textColor: textC),
      brand: _brand,
      layout: InfoLayout.centered,
      layoutScale: _infoLayoutScale,
      contentWidth: _contentW,
    );
  }

  Widget _bottomBar(Color bg, Color textC) {
    final d = widget.data;
    return Container(
      width: _contentW,
      color: bg == Colors.transparent ? null : bg,
      child: InfoSection(
        data: d.copyWith(textColor: textC),
        brand: _brand,
        layout: InfoLayout.row,
        layoutScale: _infoLayoutScale,
        contentWidth: _contentW,
      ),
    );
  }

  bool get _isOverlayPosition {
    final p = widget.data.watermarkPosition;
    return p == WatermarkPosition.overlayBottomLeft ||
        p == WatermarkPosition.overlayBottomRight ||
        p == WatermarkPosition.overlayTopLeft ||
        p == WatermarkPosition.overlayTopRight ||
        p == WatermarkPosition.overlayCenter;
  }

  Widget _overlayWidget({Color? textColor}) {
    final d = widget.data;
    final c = textColor ?? d.textColor;
    final align = switch (d.watermarkPosition) {
      WatermarkPosition.overlayBottomLeft => Alignment.bottomLeft,
      WatermarkPosition.overlayBottomRight => Alignment.bottomRight,
      WatermarkPosition.overlayTopLeft => Alignment.topLeft,
      WatermarkPosition.overlayTopRight => Alignment.topRight,
      WatermarkPosition.overlayCenter => Alignment.center,
      _ => Alignment.bottomRight,
    };

    final shadow = const [Shadow(blurRadius: 6, color: Colors.black54)];

    if (d.watermarkPosition == WatermarkPosition.overlayCenter) {
      return Align(
        alignment: align,
        child: Padding(
          padding: EdgeInsets.all(_g(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_brand != null)
                _brand!.logo(_gLogo(40), color: d.logoColor ?? c),
              if (d.deviceName.isNotEmpty) ...[
                SizedBox(height: _g(4)),
                Text(
                  d.deviceName,
                  style: TextStyle(
                    color: c,
                    fontSize: _gTxt(12),
                    fontWeight: FontWeight.w700,
                    shadows: shadow,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (d.subtitle.isNotEmpty) ...[
                SizedBox(height: _g(2)),
                Text(
                  d.subtitle,
                  style: TextStyle(
                    color: c.withValues(alpha: 0.9),
                    fontSize: _gTxt(11),
                    fontWeight: FontWeight.w500,
                    shadows: shadow,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: align,
      child: Padding(
        padding: EdgeInsets.all(_g(10)),
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
                  _brand!.logo(_gLogo(18), color: d.logoColor ?? c),
                  SizedBox(width: _g(5)),
                ],
                Text(
                  d.deviceName,
                  style: TextStyle(
                    color: c,
                    fontWeight: FontWeight.w700,
                    fontSize: _gTxt(11),
                    shadows: shadow,
                  ),
                ),
              ],
            ),
            if (d.subtitle.isNotEmpty) ...[
              SizedBox(height: _g(1)),
              Text(
                d.subtitle,
                style: TextStyle(
                  color: c.withValues(alpha: 0.9),
                  fontSize: _gTxt(9),
                  fontWeight: FontWeight.w500,
                  shadows: shadow,
                ),
              ),
            ],
            if (d.exifString.isNotEmpty) ...[
              SizedBox(height: _g(1)),
              Text(
                d.exifString,
                style: TextStyle(
                  color: c.withValues(alpha: 0.8),
                  fontSize: _gTxt(9),
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

enum _ChinSlipStyle { white, black, blur }
