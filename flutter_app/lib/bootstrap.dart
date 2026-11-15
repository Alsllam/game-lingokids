import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/di/injection.dart';

/// Ordered startup: binding, device setup, dependencies, then the app.
Future<void> bootstrap() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // A wide, full-screen canvas suits small hands and side-by-side cards.
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      await configureDependencies();
      runApp(const App());
    },
    (error, stack) {
      // Hook a crash reporter in here when one is added.
      debugPrint('Uncaught error: $error\n$stack');
    },
  );
}
