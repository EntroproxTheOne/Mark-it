import 'package:shared_preferences/shared_preferences.dart';

/// First-launch tutorial (v1 key — bump if you ship a new tutorial flow).
class TutorialService {
  static const _prefsKey = 'mark_it_tutorial_v1_completed';

  static Future<bool> isCompleted() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_prefsKey) ?? false;
  }

  static Future<void> complete() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefsKey, true);
  }

  /// For testing / settings “Show tutorial again”.
  static Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_prefsKey);
  }
}
