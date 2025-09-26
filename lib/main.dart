import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'shared/services/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Perform any async bootstrap (e.g., hydrate preferences, set up services)
  final bootstrap = AppBootstrap();
  await bootstrap.initialize();

  runApp(
    MultiProvider(
      providers: bootstrap.providers,
      child: const InsightMateApp(),
    ),
  );
}


