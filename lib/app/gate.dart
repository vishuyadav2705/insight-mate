import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/auth_controller.dart';
import '../features/shell/shell_screen.dart';
import '../features/auth/sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AuthController>().isSignedIn;
    return isSignedIn ? const ShellScreen() : const SignInScreen();
  }
}


