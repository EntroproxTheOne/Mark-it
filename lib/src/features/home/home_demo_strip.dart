import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mark_it/src/models/watermark_data.dart';
import 'package:mark_it/src/widgets/watermark_preview.dart';
import 'package:path_provider/path_provider.dart';

/// Horizontal auto-scrolling previews using bundled PNGs + varied [WatermarkData].
class HomeDemoStrip extends StatefulWidget {
  const HomeDemoStrip({super.key});

  @override
  State<HomeDemoStrip> createState() => _HomeDemoStripState();
}

class _HomeDemoStripState extends State<HomeDemoStrip> {
  final ScrollController _scroll = ScrollController();
  Timer? _timer;
  List<File>? _files;

  /// Raster assets from the project (see `pubspec.yaml`).
  static const _assetPaths = <String>[
    'assets/mark_it_icon.png',
    'assets/branding/app_logo.png',
  ];

  static List<WatermarkData> _demoConfigs() => [
        WatermarkData(
          brandId: 'canon',
          deviceName: 'EOS R5',
          subtitle: 'Shot on Canon',
          focalLength: '85mm',
          aperture: 'f/1.4',
          shutterSpeed: '1/500',
          iso: '100',
          frameType: FrameType.whiteFrame,
          watermarkPosition: WatermarkPosition.belowImage,
          textColor: const Color(0xFF1A1A1A),
          frameColor: Colors.white,
          borderRadius: 0,
          fontFamily: 'Roboto',
          watermarkGroupScale: 1.05,
        ),
        WatermarkData(
          brandId: 'leica',
          deviceName: 'Q3',
          subtitle: 'Shot on Leica',
          focalLength: '28mm',
          aperture: 'f/2.8',
          shutterSpeed: '1/250',
          iso: '400',
          frameType: FrameType.noFrame,
          watermarkPosition: WatermarkPosition.overlayBottomRight,
          textColor: Colors.white,
          frameColor: Colors.black,
          fontFamily: 'Roboto',
          watermarkGroupScale: 0.95,
        ),
        WatermarkData(
          brandId: 'sony_camera',
          deviceName: 'ILCE-7M4',
          subtitle: 'Shot on Sony',
          focalLength: '50mm',
          aperture: 'f/2.0',
          shutterSpeed: '1/125',
          iso: '200',
          frameType: FrameType.blackFrame,
          watermarkPosition: WatermarkPosition.bottomBar,
          textColor: Colors.white,
          frameColor: Colors.black,
          borderRadius: 12,
          fontFamily: 'Roboto',
        ),
        WatermarkData(
          brandId: 'google',
          deviceName: 'Pixel 9 Pro',
          subtitle: 'Shot on Pixel',
          focalLength: '24mm',
          aperture: 'f/1.7',
          shutterSpeed: '1/60',
          iso: '320',
          frameType: FrameType.glassFrame,
          watermarkPosition: WatermarkPosition.belowImage,
          textColor: Colors.white,
          borderRadius: 18,
          fontFamily: 'Roboto',
        ),
        WatermarkData(
          brandId: 'fujifilm',
          deviceName: 'X-T5',
          subtitle: 'Shot on Fujifilm',
          focalLength: '35mm',
          aperture: 'f/2',
          shutterSpeed: '1/320',
          iso: '160',
          frameType: FrameType.blurFrame,
          watermarkPosition: WatermarkPosition.belowImage,
          textColor: const Color(0xFF1A1A1A),
          borderRadius: 14,
          fontFamily: 'Roboto',
        ),
        WatermarkData(
          brandId: 'apple',
          deviceName: 'iPhone 16 Pro',
          subtitle: 'Shot on iPhone',
          focalLength: '48mm',
          aperture: 'f/1.8',
          shutterSpeed: '1/120',
          iso: '80',
          frameType: FrameType.vignetteFrame,
          watermarkPosition: WatermarkPosition.overlayBottomLeft,
          textColor: Colors.white,
          fontFamily: 'Roboto',
          watermarkGroupScale: 1.1,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _prepareAssets();
  }

  Future<void> _prepareAssets() async {
    try {
      final dir = await getTemporaryDirectory();
      final out = <File>[];
      for (final path in _assetPaths) {
        final bytes = (await rootBundle.load(path)).buffer.asUint8List();
        final f = File('${dir.path}/home_demo_${path.hashCode}.png');
        await f.writeAsBytes(bytes, flush: true);
        out.add(f);
      }
      if (!mounted) return;
      setState(() => _files = out);
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
    } catch (_) {
      if (mounted) setState(() => _files = []);
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 36), (_) {
      if (!mounted || !_scroll.hasClients) return;
      final pos = _scroll.position;
      const step = 0.72;
      var next = pos.pixels + step;
      if (next >= pos.maxScrollExtent - 1) {
        next = 0;
      }
      _scroll.jumpTo(next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final files = _files;

    if (files == null) {
      return SizedBox(
        height: 272,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    final configs = _demoConfigs();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              Icon(
                Icons.style_rounded,
                size: 18,
                color: theme.colorScheme.primary.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 8),
              Text(
                'Live style demos',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 272,
          child: ListView.separated(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 2, right: 20),
            itemCount: configs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final file = files[i % files.length];
              return _DemoCard(
                imageFile: file,
                data: configs[i],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.imageFile,
    required this.data,
  });

  final File imageFile;
  final WatermarkData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 172,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.14),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: WatermarkPreview(
              imageFile: imageFile,
              data: data,
              maxContentWidth: 172,
            ),
          ),
        ),
      ),
    );
  }
}
