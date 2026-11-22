import 'dart:async';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'services/ads_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Google Mobile Ads SDK (runs in background, graceful test fallback)
    unawaited(AdsService.instance.initialize());

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exceptionAsString()}');
    };

    // Support portrait only as per design specifications
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (e) {
      debugPrint('Orientation lock error: $e');
    }

    runApp(const ChaiDhabaEmpireApp());
  }, (error, stack) {
    debugPrint('Uncaught Zone Error: $error\n$stack');
  });
}
