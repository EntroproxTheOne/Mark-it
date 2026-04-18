import 'package:flutter/material.dart';
import 'package:mark_it/src/services/tutorial_service.dart';
import 'package:mark_it/src/widgets/app_brand_logo.dart';

/// Multi-step intro shown once per install (until completed or skipped).
class FirstLaunchTutorial extends StatefulWidget {
  const FirstLaunchTutorial({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<FirstLaunchTutorial> createState() => _FirstLaunchTutorialState();
}

class _FirstLaunchTutorialState extends State<FirstLaunchTutorial> {
  final PageController _page = PageController();
  int _index = 0;

  static const _pages = 4;

  Future<void> _done() async {
    await TutorialService.complete();
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    theme.scaffoldBackgroundColor,
                    theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                  ]
                : [
                    theme.scaffoldBackgroundColor,
                    primary.withValues(alpha: 0.06),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _done,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    _TutorialPage(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: const AppBrandLogo(height: 120, width: 120),
                      ),
                      title: 'Welcome to Mark-it',
                      body:
                          'Add clean, professional watermarks with your camera brand, '
                          'EXIF details, and frames that match your style.',
                    ),
                    _TutorialPage(
                      child: _IconCircle(
                        icon: Icons.photo_library_rounded,
                        color: primary,
                      ),
                      title: 'Bring in any photo',
                      body:
                          'Use the gallery, camera, or browse files — including HEIC/HEIF '
                          'and RAW. Your EXIF is read from the original.',
                    ),
                    _TutorialPage(
                      child: _IconCircle(
                        icon: Icons.tune_rounded,
                        color: primary,
                      ),
                      title: 'Style & export',
                      body:
                          'Pick frames, logos, fonts, and positions. Choose export quality '
                          'in Settings, including original-resolution output when you need it.',
                    ),
                    _TutorialPage(
                      child: _IconCircle(
                        icon: Icons.auto_awesome_rounded,
                        color: primary,
                      ),
                      title: 'Explore presets',
                      body:
                          'Open the Explore tab for ready-made looks. Tap a preset to jump '
                          'into the editor with that style.',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _index == i ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _index == i
                                ? primary
                                : primary.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          if (_index < _pages - 1) {
                            _page.nextPage(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                            );
                          } else {
                            _done();
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _index < _pages - 1 ? 'Next' : 'Get started',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialPage extends StatelessWidget {
  const _TutorialPage({
    required this.child,
    required this.title,
    required this.body,
  });

  final Widget child;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          child,
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, size: 56, color: color),
    );
  }
}
