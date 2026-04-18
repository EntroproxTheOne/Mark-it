import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mark_it/src/app/app.dart';
import 'package:mark_it/src/services/export_quality_service.dart';
import 'package:mark_it/src/services/monetization_service.dart';
import 'package:mark_it/src/services/preset_service.dart';
import 'package:mark_it/src/widgets/frosted_surface.dart';
import 'package:mark_it/src/widgets/app_brand_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoApply = false;
  bool? _plusActive;
  bool _debugSkipExportGate = false;
  ExportQualityTier _exportTier = ExportQualityTier.high;

  @override
  void initState() {
    super.initState();
    _loadAutoApply();
    _loadExportTier();
    _refreshPlusStatus();
    _loadDebugGate();
  }

  Future<void> _loadExportTier() async {
    final t = await ExportQualityService.currentTier();
    if (mounted) setState(() => _exportTier = t);
  }

  Future<void> _loadAutoApply() async {
    final v = await PresetService.isAutoApplyEnabled();
    if (mounted) setState(() => _autoApply = v);
  }

  Future<void> _refreshPlusStatus() async {
    final p = await MonetizationService.instance.isPremium();
    if (mounted) setState(() => _plusActive = p);
  }

  Future<void> _loadDebugGate() async {
    if (!kDebugMode) return;
    final v = await MonetizationService.instance.debugSkipGateEnabled();
    if (mounted) setState(() => _debugSkipExportGate = v);
  }

  Future<void> _restorePurchases() async {
    await MonetizationService.instance.restorePurchases();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) await _refreshPlusStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _plusActive == true
                ? 'Mark-it Plus is active.'
                : 'Restore finished. If you subscribed on another device, try again after Play Store syncs.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 24, 20, mq.padding.bottom + 100),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppBrandLogo(height: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Settings',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _sectionLabel(theme, 'General'),
          const SizedBox(height: 8),
          _tile(
            context,
            Icons.palette_outlined,
            'Appearance',
            subtitle: _themeModeLabel(),
            onTap: () => _showAppearanceSheet(context),
          ),
          const SizedBox(height: 8),
          _tile(
            context,
            Icons.high_quality_outlined,
            'Export Quality',
            subtitle: ExportQualityService.label(_exportTier),
            onTap: () => _showExportQualitySheet(context),
          ),
          const SizedBox(height: 8),
          FrostedSurface(
            borderRadius: BorderRadius.circular(14),
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              secondary: Icon(Icons.flash_auto_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              title: Text('Auto-apply on share',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500)),
              subtitle: Text(
                'Instantly apply last watermark when sharing to Mark-it',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              value: _autoApply,
              onChanged: (v) {
                setState(() => _autoApply = v);
                PresetService.setAutoApply(v);
              },
            ),
          ),

          const SizedBox(height: 24),
          _sectionLabel(theme, 'Mark-it Plus'),
          const SizedBox(height: 8),
          FrostedSurface(
            borderRadius: BorderRadius.circular(14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _plusActive == true
                      ? 'Status: Plus active (unlimited exports)'
                      : 'Status: Free (ad or subscription before each export)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _restorePurchases,
                    child: const Text('Restore purchases'),
                  ),
                ),
              ],
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            FrostedSurface(
              borderRadius: BorderRadius.circular(14),
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                title: const Text('Debug: skip export gate'),
                subtitle: const Text('Bypass subscription and ads (debug only)'),
                value: _debugSkipExportGate,
                onChanged: (v) async {
                  setState(() => _debugSkipExportGate = v);
                  await MonetizationService.instance.setDebugSkipGate(v);
                },
              ),
            ),
          ],

          const SizedBox(height: 24),
          _sectionLabel(theme, 'Support'),
          const SizedBox(height: 8),
          _tile(
            context,
            Icons.feedback_outlined,
            'Send Feedback',
            onTap: () => _showFeedbackDialog(context),
          ),
          const SizedBox(height: 8),
          _tile(
            context,
            Icons.help_outline_rounded,
            'Help & FAQ',
            onTap: () => _showHelpDialog(context),
          ),

          const SizedBox(height: 24),
          _sectionLabel(theme, 'About'),
          const SizedBox(height: 8),
          _tile(
            context,
            Icons.info_outline_rounded,
            'About Mark-it',
            onTap: () => _showAboutAppDialog(context),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Mark-it v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel() {
    return switch (themeNotifier.value) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  void _showAppearanceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AppearanceSheet(),
    );
  }

  void _showExportQualitySheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Export quality',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'PNG exports use your chosen scale. “Original resolution” matches photo width when possible (great for HEIC and high-res shots).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            for (final tier in ExportQualityTier.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FrostedSurface(
                  borderRadius: BorderRadius.circular(12),
                  color: _exportTier == tier
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : null,
                  borderColor: _exportTier == tier
                      ? theme.colorScheme.primary.withValues(alpha: 0.4)
                      : null,
                  child: ListTile(
                    title: Text(
                      ExportQualityService.label(tier),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      ExportQualityService.description(tier),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    trailing: _exportTier == tier
                        ? Icon(Icons.check_circle_rounded,
                            color: theme.colorScheme.primary)
                        : null,
                    onTap: () async {
                      await ExportQualityService.setTier(tier);
                      if (!context.mounted) return;
                      setState(() => _exportTier = tier);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                ),
              ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Help us improve Mark-it! Share your thoughts, report bugs, or request features.',
              style: TextStyle(
                  fontSize: 13,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Your feedback...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Thank you for your feedback!')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _faqItem(theme, 'How do I add a watermark?',
                  'Tap "Choose from Gallery" or "Take a Photo" on the home screen. The editor will open automatically with EXIF data pre-filled.'),
              _faqItem(theme, 'Can I change the watermark font?',
                  'Yes! Use the Font tab in the editor to choose from 50+ bundled and Google fonts.'),
              _faqItem(theme, 'What frame types are available?',
                  'White, Black, Dark Gray, Blur, Glass, Color, Vignette, and Film Strip frames are all available in the Template tab.'),
              _faqItem(theme, 'How do I change the brand logo?',
                  'Go to the Brand tab in the editor. Choose from 25+ camera and phone brands.'),
              _faqItem(theme, 'Where are exported photos saved?',
                  'Photos are saved to the app\'s documents folder and appear in the Gallery tab.'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _faqItem(ThemeData theme, String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          Text(a,
              style: TextStyle(
                  fontSize: 12,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Mark-it',
      applicationVersion: '1.0.0',
      applicationLegalese: '\u00a9 2026 Mark-it. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Mark-it adds beautiful watermarks to your photos with brand logos, '
          'EXIF data overlays, and stylish frame templates.',
          style: TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _sectionLabel(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title, {
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return FrostedSurface(
      borderRadius: BorderRadius.circular(14),
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon,
                    size: 22,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearanceSheet extends StatefulWidget {
  const _AppearanceSheet();

  @override
  State<_AppearanceSheet> createState() => _AppearanceSheetState();
}

class _AppearanceSheetState extends State<_AppearanceSheet> {
  late ThemeMode _selected = themeNotifier.value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Appearance',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          for (final mode in ThemeMode.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FrostedSurface(
                borderRadius: BorderRadius.circular(12),
                color: _selected == mode
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : null,
                borderColor: _selected == mode
                    ? theme.colorScheme.primary.withValues(alpha: 0.4)
                    : null,
                child: ListTile(
                  leading: Icon(_iconForMode(mode),
                      color: _selected == mode
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.5)),
                  title: Text(_labelForMode(mode),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: _selected == mode
                      ? Icon(Icons.check_circle,
                          color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _selected = mode);
                    themeNotifier.value = mode;
                  },
                ),
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _labelForMode(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System Default',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  IconData _iconForMode(ThemeMode mode) => switch (mode) {
        ThemeMode.system => Icons.settings_brightness_rounded,
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
      };
}
