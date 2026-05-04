import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mark_it/src/app/app.dart';
import 'package:mark_it/src/services/monetization_service.dart';

void main() {
  runZonedGuarded(() {
    final binding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: binding);

    // Bound GPU/RAM from decoded images when browsing large photos (esp. high DPR).
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 72 << 20;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PlatformError: $error\n$stack');
      return true;
    };

    unawaited(MonetizationService.instance.ensureInitialized());
    runApp(const MarkItApp());
  }, (error, stack) {
    debugPrint('ZoneError: $error\n$stack');
  });
}
