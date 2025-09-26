import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Avoid importing dart:io on web builds
String _defaultBackendUrl() {
  if (kIsWeb) {
    return 'http://localhost:8080';
  }
  try {
    // dart:io's Platform is not available on web; wrapped in try
    // ignore: avoid_web_libraries_in_flutter
    // ignore: import_of_legacy_library_into_null_safe
    // ignore_for_file: implementation_imports
    // We only reference Platform through dynamic to avoid analyzer issues on web
    final platform = (Object? p) {
      return p as dynamic;
    }(null);
  } catch (_) {
    // Fallback
  }
  // Use Android emulator loopback by default for non-web mobile
  // 10.0.2.2 works for Android emulator; on iOS simulator localhost works too
  // Defaulting to 10.0.2.2 is safe for Android; users can override via .env
  return 'http://10.0.2.2:8080';
}

class EnvConfig {
  static String get backendBaseUrl =>
      (dotenv.maybeGet('BACKEND_BASE_URL')?.trim().isNotEmpty ?? false)
          ? dotenv.get('BACKEND_BASE_URL')
          : _defaultBackendUrl();
  static String? get openaiApiKey => dotenv.maybeGet('OPENAI_API_KEY');
}


