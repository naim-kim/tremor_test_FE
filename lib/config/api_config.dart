import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolve the backend base URL from .env file or fallback to defaults.
///
/// This is written to be **hot-reload safe**: if `.env` wasn't loaded yet
/// (or gets reset), we simply skip it instead of throwing.
String resolveBaseUrl() {
  // First check .env file if it's been initialized.
  try {
    if (dotenv.isInitialized) {
      final fromDotEnv = dotenv.maybeGet('API_BASE_URL');
      if (fromDotEnv != null && fromDotEnv.isNotEmpty) {
        final trimmed = fromDotEnv.trim();
        // Validate URL format
        try {
          final uri = Uri.parse(trimmed);
          if (uri.hasScheme && uri.hasAuthority) {
            debugPrint('Using API URL from .env: $trimmed');
            return trimmed;
          }
        } catch (e) {
          debugPrint('Invalid URL in .env: $trimmed - $e');
        }
      }
    }
  } catch (e) {
    // If dotenv itself isn't ready, just fall back without crashing.
    debugPrint('DotEnv not initialized, skipping .env: $e');
  }

  // Fallback to dart-define if provided
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) {
    debugPrint('Using API URL from dart-define: $fromEnv');
    return fromEnv;
  }

  // Default fallbacks based on platform
  String defaultUrl;
  if (kIsWeb) {
    defaultUrl = 'http://localhost:8080';
  } else if (Platform.isAndroid) {
    // Android emulator cannot reach host localhost directly.
    defaultUrl = 'http://10.0.2.2:8080';
  } else {
    defaultUrl = 'http://localhost:8080';
  }

  debugPrint('Using default API URL: $defaultUrl');
  return defaultUrl;
}
