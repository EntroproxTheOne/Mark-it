import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mark_it/src/app/theme/app_theme.dart';
import 'package:mark_it/src/features/home/home_screen.dart';
import 'package:mark_it/src/features/gallery/gallery_screen.dart';
import 'package:mark_it/src/features/settings/settings_screen.dart';
import 'package:mark_it/src/features/recommended/recommended_screen.dart';
import 'package:mark_it/src/features/editor/editor_screen.dart';
import 'package:mark_it/src/features/onboarding/first_launch_tutorial.dart';
import 'package:mark_it/src/services/preset_service.dart';
import 'package:mark_it/src/services/tutorial_service.dart';
import 'package:mark_it/src/models/watermark_data.dart';
import 'package:mark_it/src/widgets/app_brand_logo.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

class MarkItApp extends StatelessWidget {
  const MarkItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, _) => MaterialApp(
        title: 'Mark-it',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        home: const _SplashGate(),
      ),
    );
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  late final Animation<double> _slideUp;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    );
    _fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.58, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _slideUp = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.18, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    FlutterNativeSplash.remove();
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 1380), () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: _done
          ? const AppShell(key: ValueKey('shell'))
          : _SplashBody(
              key: const ValueKey('splash'),
              fadeIn: _fadeIn,
              scale: _scale,
              slideUp: _slideUp,
            ),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody({
    super.key,
    required this.fadeIn,
    required this.scale,
    required this.slideUp,
  });

  final Animation<double> fadeIn;
  final Animation<double> scale;
  final Animation<double> slideUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const coral = Color(0xFFFF5F52);
    const coralDeep = Color(0xFFE04A3D);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF1A1A1A), Color(0xFF242424)]
                : [coral, Color.lerp(coral, coralDeep, 0.4)!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: fadeIn,
              child: ScaleTransition(
                scale: scale,
                child: AnimatedBuilder(
                  animation: slideUp,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, slideUp.value),
                    child: child,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: const AppBrandLogo(height: 112, width: 112),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Mark-it',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: isDark
                              ? theme.colorScheme.primary
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Beautiful watermarks',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.42)
                              : Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  static const _shareChannel = MethodChannel('com.markit/share');

  static const _pages = <Widget>[
    HomeScreen(),
    RecommendedScreen(),
    GalleryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForSharedFile();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTutorial());
  }

  Future<void> _maybeShowTutorial() async {
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    if (await TutorialService.isCompleted()) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (ctx, animation, secondary) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: FirstLaunchTutorial(
              onFinished: () => Navigator.of(ctx).pop(),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForSharedFile();
    }
  }

  Future<void> _checkForSharedFile() async {
    try {
      final path = await _shareChannel.invokeMethod<String>('getSharedFile');
      if (path != null && path.isNotEmpty && mounted) {
        final file = File(path);
        if (await file.exists()) {
          final autoApply = await PresetService.isAutoApplyEnabled();
          if (autoApply) {
            final preset = await PresetService.loadLastUsed();
            if (preset != null && mounted) {
              _autoApplyAndSave(file, preset);
              return;
            }
          }
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditorScreen(imageFile: file),
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _autoApplyAndSave(File file, WatermarkData preset) async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EditorScreen(imageFile: file, savedStyle: preset),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Auto-applied last watermark style'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A2A2A).withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.75),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.6),
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (v) => setState(() => _currentIndex = v),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome_rounded),
                  label: 'Explore',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.photo_library_outlined),
                  selectedIcon: Icon(Icons.photo_library_rounded),
                  label: 'Gallery',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
