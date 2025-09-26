import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'theme.dart';
import '../features/settings/settings_controller.dart';
import 'gate.dart';

class InsightMateApp extends StatelessWidget {
  const InsightMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return MaterialApp(
      title: 'Insight Mate',
      themeMode: settings.themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}


