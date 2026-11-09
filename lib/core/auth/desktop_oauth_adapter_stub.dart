// File: lib/core/auth/desktop_oauth_adapter_stub.dart
import 'google_auth_service.dart';

/// Fallback adapter cho môi trường không hỗ trợ dart:io (Web)
Future<GoogleAuthResult> runDesktopOAuthFlow() async {
  return GoogleAuthResult.interactiveChooserRequired();
}
