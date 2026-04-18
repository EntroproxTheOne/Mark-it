import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:mark_it/src/features/editor/editor_screen.dart';
import 'package:mark_it/src/features/batch/batch_screen.dart';
import 'package:mark_it/src/features/home/home_demo_strip.dart';
import 'package:mark_it/src/services/exif_service.dart';
import 'package:mark_it/src/services/image_decode_service.dart';
import 'package:mark_it/src/widgets/frosted_surface.dart';
import 'package:mark_it/src/widgets/app_brand_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _browseFileExtensions = [
    'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif', 'bmp', 'tiff', 'tif',
    'dng', 'cr2', 'cr3', 'nef', 'arw', 'orf', 'rw2', 'raf', 'pef', 'srw', 'raw',
  ];

  void _maybeNoteSpecialImport(BuildContext context, String path) {
    if (!ExifService.isRawFile(path) &&
        !ImageDecodeService.isHeicOrHeif(path)) {
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'RAW & HEIC/HEIF: preview may use a JPEG proxy; EXIF and export use your file as usual.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickAndEdit(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 100);
      if (picked == null) return;
      if (!context.mounted) return;
      _maybeNoteSpecialImport(context, picked.path);
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditorScreen(imageFile: File(picked.path)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _pickBulk(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(imageQuality: 100);
      if (picked.isEmpty) return;
      if (!context.mounted) return;
      final files = picked.map((x) => File(x.path)).toList();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BatchScreen(files: files)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images: $e')),
      );
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _browseFileExtensions,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      if (!context.mounted) return;

      final file = File(path);
      _maybeNoteSpecialImport(context, path);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditorScreen(imageFile: file),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding:
                EdgeInsets.fromLTRB(20, 16, 20, mq.padding.bottom + 108),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const HomeDemoStrip(),
                const SizedBox(height: 26),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.28),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: const AppBrandLogo(height: 58, width: 58),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mark-it',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Watermarks that match your gear',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.52),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary,
                        Color.lerp(primary, const Color(0xFFFF8A7A), 0.35)!,
                        const Color(0xFFFF8A7A).withValues(alpha: 0.95),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.32),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start editing',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Full-resolution export, EXIF-aware text, and gallery HEIC support.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Material(
                        color: Colors.white,
                        elevation: 0,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () =>
                              _pickAndEdit(context, ImageSource.gallery),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_library_rounded,
                                    color: primary, size: 24),
                                const SizedBox(width: 10),
                                Text(
                                  'Choose from gallery',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: const Color(0xFF2C2C2C),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _HomeSecondaryTile(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        isDark: isDark,
                        onTap: () => _pickAndEdit(context, ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HomeSecondaryTile(
                        icon: Icons.folder_open_rounded,
                        label: 'Browse files',
                        subtitle: 'JPEG · HEIC · RAW…',
                        isDark: isDark,
                        onTap: () => _pickFile(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FrostedSurface(
                  borderRadius: BorderRadius.circular(16),
                  color: primary.withValues(alpha: 0.1),
                  borderColor: primary.withValues(alpha: 0.22),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _pickBulk(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.burst_mode_rounded,
                                  color: primary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bulk watermark',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Apply your last style to many photos at once',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.35)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Center(
                  child: Lottie.asset(
                    'assets/animations/empty_state.json',
                    width: 148,
                    height: 148,
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Browse styles on Explore, then open the editor',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSecondaryTile extends StatelessWidget {
  const _HomeSecondaryTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FrostedSurface(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.48),
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
