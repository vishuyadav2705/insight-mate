import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../features/settings/settings_controller.dart';
import '../../features/auth/auth_controller.dart';
import 'history_service.dart';

class AppBootstrap {
  List<ChangeNotifierProvider> get providers => <ChangeNotifierProvider>[
        ChangeNotifierProvider<SettingsController>(
          create: (_) => SettingsController(_prefs),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(_prefs),
        ),
        ChangeNotifierProvider<HistoryService>(
          create: (_) => HistoryService(_prefs)..load(),
        ),
      ];

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    await dotenv.load(fileName: '.env', mergeWith: {});
    _prefs = await SharedPreferences.getInstance();
  }
}


