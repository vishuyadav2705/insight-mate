import 'package:flutter/material.dart';

import '../features/shell/shell_screen.dart';
import '../features/auth/sign_in_screen.dart';

class AppRouter {
  static const String initialRoute = SignInScreen.routeName;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SignInScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case ShellScreen.routeName:
        return MaterialPageRoute(builder: (_) => const ShellScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}


