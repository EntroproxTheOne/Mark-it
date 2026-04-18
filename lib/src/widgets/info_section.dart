import 'package:flutter/material.dart';
import 'package:mark_it/src/models/brand_kit.dart';
import 'package:mark_it/src/models/watermark_data.dart';
import 'package:mark_it/src/services/font_service.dart';

enum InfoLayout { row, column, centered }

class InfoSection extends StatelessWidget {
  const InfoSection({
    super.key,
    required this.data,
    required this.brand,
    this.layout = InfoLayout.row,
    this.logoSize = 32,
    this.compact = false,
    this.layoutScale = 1.0,
    this.contentWidth,
  });

  final WatermarkData data;
  final BrandKit? brand;
  final InfoLayout layout;
  final double logoSize;
  final bool compact;
  /// Scales fonts, padding, and logo from preview width (reference 1080).
  final double layoutScale;
  /// When set, constrains the bar to the same width as the photo column.
  final double? contentWidth;

  double _textS(double px) =>
      px * layoutScale * data.infoTextScale.clamp(0.5, 2.0);

  double _logoS(double size) =>
      size * layoutScale * data.brandLogoScale.clamp(0.5, 2.0);

  Widget _brandLogo(double size, Color fallbackColor) {
    if (brand == null) return const SizedBox.shrink();
    return brand!.logo(_logoS(size), color: data.logoColor ?? fallbackColor);
  }

  @override
  Widget build(BuildContext context) {
    final font = FontService.getFont(
      data.fontFamily,
      color: data.textColor,
    );

    Widget inner = switch (layout) {
      InfoLayout.centered => _centered(font),
      InfoLayout.column => _column(font),
      _ => _row(font),
    };

    if (contentWidth != null) {
      inner = SizedBox(width: contentWidth, child: inner);
    }
    return inner;
  }

  Widget _row(TextStyle font) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _textS(compact ? 10 : 16),
        vertical: _textS(compact ? 6 : 12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.deviceName,
                  style: font.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: _textS(compact ? 12 : 14),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (data.subtitle.isNotEmpty)
                  Text(
                    data.subtitle,
                    style: font.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: _textS(compact ? 10 : 11),
                      color: data.textColor.withValues(alpha: 0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (brand != null) ...[
            _brandLogo(logoSize, data.textColor),
            if (data.exifString.isNotEmpty)
              Container(
                width: 1,
                height: _textS(20),
                margin: EdgeInsets.symmetric(horizontal: _textS(10)),
                color: data.textColor.withValues(alpha: 0.3),
              ),
          ],
          if (data.exifString.isNotEmpty)
            Text(
              data.exifString,
              style: font.copyWith(fontSize: _textS(compact ? 10 : 12)),
            ),
        ],
      ),
    );
  }

  Widget _column(TextStyle font) {
    return Padding(
      padding: EdgeInsets.all(_textS(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (brand != null) ...[
            _brandLogo(logoSize, data.textColor),
            SizedBox(height: _textS(8)),
          ],
          Text(
            data.deviceName,
            style: font.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: _textS(15),
            ),
          ),
          if (data.subtitle.isNotEmpty) ...[
            SizedBox(height: _textS(4)),
            Text(
              data.subtitle,
              style: font.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: _textS(13),
                color: data.textColor.withValues(alpha: 0.88),
              ),
            ),
          ],
          if (data.exifString.isNotEmpty) ...[
            SizedBox(height: _textS(4)),
            Text(
              data.exifString,
              style: font.copyWith(
                fontSize: _textS(12),
                color: data.textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _centered(TextStyle font) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _textS(20), horizontal: _textS(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (brand != null) ...[
            _brandLogo(logoSize * 1.2, data.textColor),
            SizedBox(height: _textS(10)),
          ],
          Text(
            data.deviceName,
            style: font.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: _textS(16),
            ),
            textAlign: TextAlign.center,
          ),
          if (data.subtitle.isNotEmpty) ...[
            SizedBox(height: _textS(6)),
            Text(
              data.subtitle,
              style: font.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: _textS(14),
                color: data.textColor.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (data.exifString.isNotEmpty) ...[
            SizedBox(height: _textS(6)),
            Text(
              data.exifString,
              style: font.copyWith(
                fontSize: _textS(12),
                color: data.textColor.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
