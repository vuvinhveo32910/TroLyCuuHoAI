// File: lib/core/auth/desktop_oauth_adapter_web.dart
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

import '../config/google_auth_config.dart';
import 'google_auth_service.dart';

@JS('triggerShopeeStyleGooglePopup')
external JSPromise<JSString>? _triggerShopeeStyleGooglePopup(JSString clientId);

/// Triển khai luồng xác thực Google OAuth 2.0 Popup (Shopee-style Account Chooser) trên Flutter Web
/// Gọi trực tiếp Google Identity Services (`accounts.google.com/v3/signin/accountchooser`)
/// với `prompt=select_account`, hoàn toàn không đi qua Supabase `/auth/v1/authorize`
Future<GoogleAuthResult> runDesktopOAuthFlow() async {
  try {
    final promise = _triggerShopeeStyleGooglePopup(
      GoogleAuthConfig.clientId.toJS,
    );
    if (promise == null) {
      return GoogleAuthResult.interactiveChooserRequired();
    }

    final jsResult = await promise.toDart;
    final rawJson = jsResult.toDart;
    final decoded = jsonDecode(rawJson);

    if (decoded is Map<String, dynamic>) {
      if (decoded['isSuccess'] == true) {
        final email = decoded['email'] as String?;
        final id = decoded['id'] as String?;
        final displayName = decoded['displayName'] as String?;
        if (email != null && id != null) {
          return GoogleAuthResult.success(
            email: email,
            displayName: displayName ?? email.split('@').first,
            id: id,
          );
        }
      }
      if (decoded['isCancelled'] == true) {
        return GoogleAuthResult.cancelled();
      }
    }
    return GoogleAuthResult.interactiveChooserRequired();
  } catch (e) {
    debugPrint('[WebGoogleOAuth] Fallback sang hộp thoại Account Chooser: $e');
    return GoogleAuthResult.interactiveChooserRequired();
  }
}
