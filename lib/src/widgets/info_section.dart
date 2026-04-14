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
  });

  final WatermarkData data;
  final BrandKit? brand;
  final InfoLayout layout;
  final double logoSize;
  final bool compact;

  Widget _brandLogo(double size, Color fallbackColor) {
    if (brand == null) return const SizedBox.shrink();
    return brand!.logo(size, color: data.logoColor ?? fallbackColor);
  }

  @override
  Widget build(BuildContext context) {
    final font = FontService.getFont(
      data.fontFamily,
      color: data.textColor,
    );

    if (layout == InfoLayout.centered) return _centered(font);
    if (layout == InfoLayout.column) return _column(font);
    return _row(font);
  }

  Widget _row(TextStyle font) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 16,
        vertical: compact ? 6 : 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              data.deviceName,
              style: font.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (brand != null) ...[
            _brandLogo(logoSize, data.textColor),
            if (data.exifString.isNotEmpty)
              Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: data.textColor.withValues(alpha: 0.3),
              ),
          ],
          if (data.exifString.isNotEmpty)
            Text(
              data.exifString,
              style: font.copyWith(fontSize: compact ? 10 : 12),
            ),
        ],
      ),
    );
  }

  Widget _column(TextStyle font) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (brand != null) ...[
            _brandLogo(logoSize, data.textColor),
            const SizedBox(height: 8),
          ],
          Text(
            data.deviceName,
            style: font.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          if (data.exifString.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              data.exifString,
              style: font.copyWith(
                fontSize: 12,
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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (brand != null) ...[
            _brandLogo(logoSize * 1.2, data.textColor),
            const SizedBox(height: 10),
          ],
          if (brand != null)
            Text(
              brand!.tagline,
              style: font.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          if (data.exifString.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              data.exifString,
              style: font.copyWith(
                fontSize: 12,
                color: data.textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
