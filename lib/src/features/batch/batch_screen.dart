import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lottie/lottie.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mark_it/src/models/watermark_data.dart';
import 'package:mark_it/src/services/color_service.dart';
import 'package:mark_it/src/services/exif_service.dart';
import 'package:mark_it/src/services/preset_service.dart';
import 'package:mark_it/src/widgets/frosted_surface.dart';
import 'package:mark_it/src/widgets/watermark_preview.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key, required this.files});
  final List<File> files;

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  bool _processing = false;
  int _done = 0;
  int _failed = 0;
  bool _finished = false;
  WatermarkData? _preset;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreset();
  }

  Future<void> _loadPreset() async {
    final saved = await PresetService.loadLastUsed();
    if (!mounted) return;
    setState(() {
      _preset = saved ?? WatermarkData();
      _loading = false;
    });
  }

  Future<void> _process() async {
    if (_preset == null) return;
    setState(() {
      _processing = true;
      _done = 0;
      _failed = 0;
      _finished = false;
    });

    final docDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${docDir.path}/Mark-it');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    for (final file in widget.files) {
      if (!mounted) return;
      try {
        var data = await ExifService.extractFromFile(file);
        final palette = await ColorService.extractPalette(file);
        data = data.copyWith(
          frameType: _preset!.frameType,
          watermarkPosition: _preset!.watermarkPosition,
          textColor: _preset!.textColor,
          frameColor: _preset!.frameColor,
          frameOpacity: _preset!.frameOpacity,
          borderRadius: _preset!.borderRadius,
          fontFamily: _preset!.fontFamily,
          brandId: _preset!.brandId != 'none' ? _preset!.brandId : data.brandId,
          logoColor: _preset!.logoColor,
        );

        final key = GlobalKey();
        final entry = OverlayEntry(
          builder: (_) => Positioned(
            left: -9999,
            top: -9999,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 1200,
                child: WatermarkPreview(
                  imageFile: file,
                  data: data,
                  palette: palette,
                ),
              ),
            ),
          ),
        );

        if (!mounted) return;
        Overlay.of(context).insert(entry);
        await Future.delayed(const Duration(milliseconds: 500));

        final boundary =
            key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 3.0);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final ts = DateTime.now().millisecondsSinceEpoch;
            final outPath = '${exportDir.path}/markit_batch_$ts.png';
            await File(outPath)
                .writeAsBytes(byteData.buffer.asUint8List());
            try { await Gal.putImage(outPath, album: 'Mark-it'); } catch (_) {}
            if (mounted) setState(() => _done++);
          } else {
            if (mounted) setState(() => _failed++);
          }
        } else {
          if (mounted) setState(() => _failed++);
        }

        entry.remove();
      } catch (_) {
        if (mounted) setState(() => _failed++);
      }
    }

    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bulk Watermark',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: theme.colorScheme.onSurface,
            )),
      ),
      body: _loading
          ? Center(
              child: Lottie.asset('assets/animations/processing.json',
                  width: 80, height: 80, repeat: true))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FrostedSurface(
                    borderRadius: BorderRadius.circular(14),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.photo_library_rounded,
                            color: theme.colorScheme.primary, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.files.length} photos selected',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Last-used watermark style will be applied',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_preset != null) ...[
                    FrostedSurface(
                      borderRadius: BorderRadius.circular(14),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Preset Style',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              )),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _infoTag(
                                  theme, _preset!.frameType.label),
                              const SizedBox(width: 6),
                              _infoTag(theme,
                                  _preset!.watermarkPosition.label),
                              const SizedBox(width: 6),
                              _infoTag(theme, _preset!.fontFamily),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_processing) ...[
                    LinearProgressIndicator(
                      value: widget.files.isEmpty
                          ? 0
                          : (_done + _failed) / widget.files.length,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _finished
                          ? 'Done! $_done saved${_failed > 0 ? ', $_failed failed' : ''}'
                          : 'Processing ${_done + _failed + 1} of ${widget.files.length}...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    if (_finished) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Done'),
                        ),
                      ),
                    ],
                  ] else ...[
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _preset == null ? null : _process,
                        icon: const Icon(Icons.auto_fix_high_rounded),
                        label: Text(
                            'Apply to ${widget.files.length} photos'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_preset == null)
                      Center(
                        child: Text(
                          'Export at least one photo first to save a preset',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    const Spacer(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _infoTag(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
