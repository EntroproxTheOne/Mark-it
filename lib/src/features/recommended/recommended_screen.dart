import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mark_it/src/features/editor/editor_screen.dart';
import 'package:mark_it/src/services/preset_service.dart';
import 'package:mark_it/src/widgets/frosted_surface.dart';

class RecommendedScreen extends StatelessWidget {
  const RecommendedScreen({super.key});

  Future<void> _pickAndApply(
      BuildContext context, WatermarkPreset preset) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorScreen(
          imageFile: File(picked.path),
          initialPreset: preset,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
            child: Text(
              'Recommended',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'Browse curated watermark styles. Tap one, then pick a photo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding:
                  EdgeInsets.fromLTRB(20, 4, 20, mq.padding.bottom + 100),
              itemCount: RecommendedPresets.all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final preset = RecommendedPresets.all[i];
                return GestureDetector(
                  onTap: () => _pickAndApply(context, preset),
                  child: FrostedSurface(
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : theme.colorScheme.primary
                                    .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            preset.icon,
                            size: 24,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                preset.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _previewChip(theme, preset),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.25),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewChip(ThemeData theme, WatermarkPreset preset) {
    return Container(
      width: 36,
      height: 44,
      decoration: BoxDecoration(
        color: preset.frameColor,
        borderRadius: BorderRadius.circular(
            preset.borderRadius > 0 ? 6 : 3),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(
                  preset.borderRadius > 0 ? 3 : 1),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 14,
            height: 2,
            color: preset.textColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 1),
          Container(
            width: 10,
            height: 1.5,
            color: preset.textColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
