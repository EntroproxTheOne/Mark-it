import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mark_it/src/models/brand_kit.dart';
import 'package:mark_it/src/models/watermark_data.dart';
import 'package:mark_it/src/models/watermark_template.dart';
import 'package:mark_it/src/services/color_service.dart';
import 'package:mark_it/src/services/exif_service.dart';
import 'package:mark_it/src/services/export_service.dart';
import 'package:mark_it/src/services/font_service.dart';
import 'package:mark_it/src/services/monetization_service.dart';
import 'package:mark_it/src/services/preset_service.dart';
import 'package:mark_it/src/widgets/animated_feedback.dart';
import 'package:mark_it/src/widgets/frosted_surface.dart';
import 'package:mark_it/src/widgets/watermark_preview.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.imageFile,
    this.explorePreset,
    this.savedStyle,
  });
  final File imageFile;
  final WatermarkPreset? explorePreset;
  final WatermarkData? savedStyle;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late WatermarkData _data;
  ImagePalette? _palette;
  bool _loading = true;
  bool _exporting = false;
  String? _error;
  final _previewKey = GlobalKey();
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      var exif = await ExifService.extractFromFile(widget.imageFile);
      final palette = await ColorService.extractPalette(widget.imageFile);

      if (widget.explorePreset != null) {
        exif = widget.explorePreset!.applyTo(exif);
      } else if (widget.savedStyle != null) {
        exif = WatermarkData.mergeSavedLook(exif, widget.savedStyle!);
      } else {
        final saved = await PresetService.loadLastUsed();
        if (saved != null) {
          exif = exif.copyWith(
            frameType: saved.frameType,
            watermarkPosition: saved.watermarkPosition,
            fontFamily: saved.fontFamily,
            borderRadius: saved.borderRadius,
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _data = exif;
        _palette = palette;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _data = WatermarkData();
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _update(WatermarkData Function(WatermarkData) updater) {
    setState(() => _data = updater(_data));
  }

  Future<void> _export() async {
    final allowed = await MonetizationService.instance
        .requestExportPermission(context, bulk: false);
    if (!allowed || !mounted) return;

    setState(() => _exporting = true);
    try {
      final path = await ExportService.exportWatermarked(
        imageFile: widget.imageFile,
        previewKey: _previewKey,
      );
      if (!mounted) return;
      setState(() => _exporting = false);
      PresetService.saveLastUsed(_data);
      await showSuccessOverlay(context, 'Saved to gallery');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to $path'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => ExportService.share(path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Text('Edit Watermark',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: theme.colorScheme.onSurface,
            )),
        actions: [
          if (_exporting)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Lottie.asset(
                'assets/animations/processing.json',
                width: 28,
                height: 28,
                repeat: true,
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.save_alt_rounded),
              tooltip: 'Export',
              onPressed: _export,
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share',
              onPressed: _export,
            ),
          ],
        ],
      ),
      body: _loading
          ? Center(
              child: Lottie.asset(
                'assets/animations/processing.json',
                width: 80,
                height: 80,
                repeat: true,
              ),
            )
          : Column(
              children: [
                if (_error != null)
                  Material(
                    color: Colors.orange.withValues(alpha: 0.15),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 18,
                              color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Some data could not be loaded. You can still edit manually.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                        12,
                        MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            8,
                        12,
                        8),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: WatermarkPreview(
                        imageFile: widget.imageFile,
                        data: _data,
                        previewKey: _previewKey,
                        palette: _palette,
                      ),
                    ),
                  ),
                ),
                _EditorTabBar(
                  activeTab: _activeTab,
                  onTap: (i) => setState(() => _activeTab = i),
                ),
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      height: 240,
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF2A2A2A).withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.65),
                      ),
                      child: switch (_activeTab) {
                        0 => _FramePanel(
                            data: _data,
                            onUpdate: _update,
                            palette: _palette),
                        1 => _LogoPanel(data: _data, onUpdate: _update),
                        2 => _InfoPanel(data: _data, onUpdate: _update),
                        3 => _FontPanel(data: _data, onUpdate: _update),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB BAR
// ─────────────────────────────────────────────────────────────────────────────
class _EditorTabBar extends StatelessWidget {
  const _EditorTabBar({required this.activeTab, required this.onTap});
  final int activeTab;
  final ValueChanged<int> onTap;

  static const _tabs = ['Frame', 'Logo', 'Info', 'Font'];
  static const _icons = [
    Icons.dashboard_rounded,
    Icons.branding_watermark_rounded,
    Icons.info_outline_rounded,
    Icons.font_download_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A2A2A).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final sel = i == activeTab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: sel
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _icons[i],
                          size: 19,
                          color: sel
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _tabs[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FRAME PANEL (merged: templates + position + frame color + opacity + corners)
// ─────────────────────────────────────────────────────────────────────────────
class _FramePanel extends StatelessWidget {
  const _FramePanel({
    required this.data,
    required this.onUpdate,
    this.palette,
  });
  final WatermarkData data;
  final void Function(WatermarkData Function(WatermarkData)) onUpdate;
  final ImagePalette? palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        // -- Template row --
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: WatermarkTemplates.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final t = WatermarkTemplates.all[i];
              final active = data.frameType == t.frameType &&
                  data.watermarkPosition == t.position;
              return GestureDetector(
                onTap: () => onUpdate((d) => t.applyTo(d)),
                child: FrostedSurface(
                  borderRadius: BorderRadius.circular(10),
                  color: active
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : null,
                  borderColor: active
                      ? theme.colorScheme.primary.withValues(alpha: 0.5)
                      : null,
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    width: 64,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconFor(t.frameType),
                          size: 20,
                          color: active
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.name,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // -- Position chips --
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: WatermarkPosition.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 4),
            itemBuilder: (context, i) {
              final p = WatermarkPosition.values[i];
              final sel = data.watermarkPosition == p;
              return GestureDetector(
                onTap: () =>
                    onUpdate((d) => d.copyWith(watermarkPosition: p)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: sel
                          ? theme.colorScheme.primary.withValues(alpha: 0.5)
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    p.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // -- Frame color + Opacity + Corners --
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Color',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6))),
            const SizedBox(width: 8),
            ...[
              Colors.white,
              const Color(0xFFF5F5F5),
              const Color(0xFF1A2332),
              Colors.black,
            ].map((c) => _colorDot(theme, c, data.frameColor == c,
                () => onUpdate((d) => d.copyWith(frameColor: c)))),
            const Spacer(),
            Text('${(data.frameOpacity * 100).round()}%',
                style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4))),
            SizedBox(
              width: 90,
              child: Slider(
                value: data.frameOpacity,
                onChanged: (v) =>
                    onUpdate((d) => d.copyWith(frameOpacity: v)),
              ),
            ),
            Text('R${data.borderRadius.round()}',
                style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4))),
            SizedBox(
              width: 70,
              child: Slider(
                value: data.borderRadius,
                min: 0,
                max: 32,
                onChanged: (v) =>
                    onUpdate((d) => d.copyWith(borderRadius: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _colorDot(
      ThemeData theme, Color c, bool sel, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(
              color: sel
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.15),
              width: sel ? 2.5 : 1,
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(FrameType ft) {
    return switch (ft) {
      FrameType.blurFrame => Icons.blur_on_rounded,
      FrameType.whiteFrame => Icons.crop_square_rounded,
      FrameType.blackFrame => Icons.square_rounded,
      FrameType.darkGrayFrame => Icons.square_rounded,
      FrameType.glassFrame => Icons.auto_awesome_rounded,
      FrameType.colorFrame => Icons.color_lens_rounded,
      FrameType.vignetteFrame => Icons.vignette_rounded,
      FrameType.filmFrame => Icons.local_movies_rounded,
      FrameType.noFrame => Icons.photo_rounded,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGO PANEL (icon-only grid + logo color)
// ─────────────────────────────────────────────────────────────────────────────
class _LogoPanel extends StatelessWidget {
  const _LogoPanel({required this.data, required this.onUpdate});
  final WatermarkData data;
  final void Function(WatermarkData Function(WatermarkData)) onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeBrand = BrandKits.findById(data.brandId);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        // -- Logo color row (only if brand selected) --
        if (activeBrand != null) ...[
          SizedBox(
            height: 30,
            child: Row(
              children: [
                Text('Logo Color',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    )),
                const SizedBox(width: 10),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: BrandKits.colorOptions.map((opt) {
                      final isDefault = opt.color == null;
                      final effectiveColor =
                          opt.color ?? activeBrand.primaryColor;
                      final sel = isDefault
                          ? data.logoColor == null
                          : data.logoColor == opt.color;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () {
                            if (isDefault) {
                              onUpdate(
                                  (d) => d.copyWith(clearLogoColor: true));
                            } else {
                              onUpdate(
                                  (d) => d.copyWith(logoColor: opt.color));
                            }
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: effectiveColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: sel
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.15),
                                width: sel ? 2.5 : 1,
                              ),
                            ),
                            child: sel
                                ? Icon(Icons.check,
                                    size: 12,
                                    color:
                                        effectiveColor.computeLuminance() >
                                                0.5
                                            ? Colors.black
                                            : Colors.white)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // -- "None" option --
        _sectionTitle(theme, 'Tap to select brand'),
        const SizedBox(height: 6),

        // -- Phones --
        _logoGrid(context, theme, isDark, 'Phones', BrandKits.phones),
        const SizedBox(height: 8),

        // -- Cameras --
        _logoGrid(context, theme, isDark, 'Cameras', BrandKits.cameras),
        const SizedBox(height: 8),

        // -- Lenses --
        _logoGrid(context, theme, isDark, 'Lenses', BrandKits.lenses),
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, String label) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            )),
        const Spacer(),
        if (data.brandId != 'none')
          GestureDetector(
            onTap: () =>
                onUpdate((d) => d.copyWith(brandId: 'none', clearLogoColor: true)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Text('Clear',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }

  Widget _logoGrid(BuildContext context, ThemeData theme, bool isDark,
      String title, List<BrandKit> brands) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            )),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: brands.map((b) {
            final sel = data.brandId == b.id;
            return GestureDetector(
              onTap: () => onUpdate(
                  (d) => d.copyWith(brandId: b.id, clearLogoColor: true)),
              child: Tooltip(
                message: b.name,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sel
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel
                          ? theme.colorScheme.primary.withValues(alpha: 0.6)
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.08),
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: b.logo(22,
                        color: sel
                            ? theme.colorScheme.primary
                            : isDark
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.black.withValues(alpha: 0.7)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.data, required this.onUpdate});
  final WatermarkData data;
  final void Function(WatermarkData Function(WatermarkData)) onUpdate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _field('Device Name', data.deviceName,
            (v) => onUpdate((d) => d.copyWith(deviceName: v))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _field('Focal', data.focalLength,
                  (v) => onUpdate((d) => d.copyWith(focalLength: v)))),
          const SizedBox(width: 8),
          Expanded(
              child: _field('Aperture', data.aperture,
                  (v) => onUpdate((d) => d.copyWith(aperture: v)))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _field('Shutter', data.shutterSpeed,
                  (v) => onUpdate((d) => d.copyWith(shutterSpeed: v)))),
          const SizedBox(width: 8),
          Expanded(
              child: _field('ISO', data.iso,
                  (v) => onUpdate((d) => d.copyWith(iso: v)))),
        ]),
        const SizedBox(height: 8),
        _field('Date/Time', data.dateTime,
            (v) => onUpdate((d) => d.copyWith(dateTime: v))),
      ],
    );
  }

  Widget _field(String label, String value, ValueChanged<String> onChange) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label, isDense: true),
      onChanged: onChange,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FONT PANEL (merged: font family + text color)
// ─────────────────────────────────────────────────────────────────────────────
class _FontPanel extends StatefulWidget {
  const _FontPanel({required this.data, required this.onUpdate});
  final WatermarkData data;
  final void Function(WatermarkData Function(WatermarkData)) onUpdate;

  @override
  State<_FontPanel> createState() => _FontPanelState();
}

class _FontPanelState extends State<_FontPanel> {
  FontCategory? _selectedCat;

  List<FontEntry> get _filtered => _selectedCat == null
      ? FontService.allFonts
      : FontService.byCategory(_selectedCat!);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cats = <(String, FontCategory?)>[
      ('All', null),
      ('Script', FontCategory.script),
      ('Display', FontCategory.display),
      ('Clean', FontCategory.clean),
      ('Decorative', FontCategory.decorative),
      ('Google', FontCategory.google),
    ];

    return Column(
      children: [
        // -- Category pills + Text color in one row --
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: cats.map((entry) {
                      final (label, cat) = entry;
                      final sel = cat == _selectedCat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCat = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: sel
                                  ? theme.colorScheme.primary
                                      .withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: sel
                                    ? theme.colorScheme.primary
                                        .withValues(alpha: 0.5)
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.12),
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w500,
                                color: sel
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // -- Text color dots --
              ...[
                Colors.black,
                const Color(0xFF333333),
                Colors.white,
                const Color(0xFFCCCCCC),
              ].map((c) {
                final sel = widget.data.textColor == c;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () =>
                        widget.onUpdate((d) => d.copyWith(textColor: c)),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.15),
                          width: sel ? 2.5 : 1,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // -- Font list --
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            itemCount: _filtered.length,
            itemBuilder: (context, i) {
              final font = _filtered[i];
              final sel = widget.data.fontFamily == font.name;
              final previewStyle = FontService.getFont(font.name,
                  fontSize: 22, fontWeight: FontWeight.w600);
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => widget
                      .onUpdate((d) => d.copyWith(fontFamily: font.name)),
                  child: FrostedSurface(
                    borderRadius: BorderRadius.circular(12),
                    color: sel
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : null,
                    borderColor: sel
                        ? theme.colorScheme.primary.withValues(alpha: 0.5)
                        : null,
                    child: SizedBox(
                      width: 100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Abc', style: previewStyle),
                          const SizedBox(height: 4),
                          Text(
                            font.displayName,
                            style: TextStyle(
                              fontSize: 9,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
