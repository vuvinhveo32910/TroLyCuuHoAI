// File: lib/core/auth/google_auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/google_auth_config.dart';
import '../config/supabase_config.dart';
import '../supabase/supabase_service.dart';
import 'desktop_oauth_adapter.dart';

/// Kết quả của quá trình xác thực Google
class GoogleAuthResult {
  final bool isSuccess;
  final String? email;
  final String? displayName;
  final String? id;
  final String? errorMessage;
  final bool isCancelled;
  final bool needsInteractiveChooser;

  const GoogleAuthResult({
    required this.isSuccess,
    this.email,
    this.displayName,
    this.id,
    this.errorMessage,
    this.isCancelled = false,
    this.needsInteractiveChooser = false,
  });

  factory GoogleAuthResult.success({
    required String email,
    String? displayName,
    required String id,
  }) {
    return GoogleAuthResult(
      isSuccess: true,
      email: email,
      displayName: displayName,
      id: id,
    );
  }

  factory GoogleAuthResult.cancelled({String? message}) {
    return GoogleAuthResult(
      isSuccess: false,
      isCancelled: true,
      errorMessage: message ?? 'Đăng nhập bằng Google đã bị hủy.',
    );
  }

  factory GoogleAuthResult.failure(String errorMessage) {
    return GoogleAuthResult(isSuccess: false, errorMessage: errorMessage);
  }

  factory GoogleAuthResult.interactiveChooserRequired({String? message}) {
    return GoogleAuthResult(
      isSuccess: false,
      needsInteractiveChooser: true,
      errorMessage: message ?? 'GOOGLE_ACCOUNT_CHOOSER_REQUIRED',
    );
  }
}

/// Giao diện trừu tượng cho Dịch vụ Xác thực Google
abstract class GoogleAuthService {
  Future<GoogleAuthResult> signIn();
  Future<void> signOut();
  bool get isMockMode;

  /// Factory tạo instance phù hợp dựa trên cấu hình GoogleAuthConfig
  factory GoogleAuthService.create() {
    if (GoogleAuthConfig.isMockMode) {
      return MockGoogleAuthService();
    }
    return LiveGoogleAuthService();
  }
}

/// Dịch vụ Mock xác thực Google cho môi trường kiểm thử và phát triển zero-config (R4)
class MockGoogleAuthService implements GoogleAuthService {
  final String mockEmail;
  final String mockDisplayName;
  final String mockId;
  final bool shouldFail;
  final String? failureMessage;
  final bool shouldCancel;

  MockGoogleAuthService({
    this.mockEmail = GoogleAuthConfig.defaultMockEmail,
    this.mockDisplayName = GoogleAuthConfig.defaultMockDisplayName,
    this.mockId = GoogleAuthConfig.defaultMockId,
    this.shouldFail = false,
    this.failureMessage,
    this.shouldCancel = false,
  });

  @override
  bool get isMockMode => true;

  @override
  Future<GoogleAuthResult> signIn() async {
    // Độ trễ nhẹ mô phỏng tiến trình xác thực thực tế
    await Future.delayed(const Duration(milliseconds: 30));

    if (shouldCancel) {
      return GoogleAuthResult.cancelled();
    }

    if (shouldFail) {
      return GoogleAuthResult.failure(
        failureMessage ?? 'Lỗi xác thực tài khoản Google mô phỏng.',
      );
    }

    return GoogleAuthResult.success(
      email: mockEmail,
      displayName: mockDisplayName,
      id: mockId,
    );
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

/// Dịch vụ xác thực Google thực tế qua Supabase OAuth / Web OAuth / Desktop
class LiveGoogleAuthService implements GoogleAuthService {
  @override
  bool get isMockMode => false;

  /// Chuyển hướng callback tương thích cho từng nền tảng:
  /// - Web: null (Supabase tự động lấy URL hiện tại của web app)
  /// - Windows / Desktop: loopback URI theo chuẩn RFC 8252
  /// - Mobile (Android/iOS): deep link URI scheme tùy chỉnh
  String? get redirectUri {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return 'http://localhost:8080/auth/callback';
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      default:
        return 'io.supabase.cuuho://login-callback';
    }
  }

  /// Kiểm tra xem Google Provider đã được bật trên Supabase Auth Server hay chưa
  /// Ngăn chặn lỗi chuyển hướng trình duyệt sang trang JSON 400:
  /// `{"code":400,"error_code":"validation_failed","msg":"Unsupported provider: provider is not enabled"}`
  Future<bool> _isSupabaseGoogleProviderEnabled() async {
    try {
      final settingsUri = Uri.parse('${SupabaseConfig.url}/auth/v1/settings');
      final response = await http
          .get(
            settingsUri,
            headers: {
              'apikey': SupabaseConfig.publishableKey,
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final externalProviders = decoded['external'];
          if (externalProviders is Map<String, dynamic>) {
            return externalProviders['google'] == true;
          }
        }
      }
    } catch (e) {
      debugPrint(
        '[LiveGoogleAuthService] Không thể kiểm tra /auth/v1/settings: $e',
      );
    }
    return false;
  }

  @override
  Future<GoogleAuthResult> signIn() async {
    try {
      // 1. Ưu tiên luồng Google OAuth 2.0 trực tiếp (Shopee-style Account Chooser `prompt=select_account`):
      // - Trên Web: Mở cửa sổ popup `accounts.google.com/v3/signin/accountchooser` qua Google Identity Services
      // - Trên Windows Desktop: Mở trình duyệt hệ thống tới `accounts.google.com/o/oauth2/v2/auth` qua Loopback RFC 8252
      // Luồng này đi trực tiếp tới Google, tránh hoàn toàn lỗi 400 "Unsupported provider: provider is not enabled" của Supabase.
      final directResult = await runDesktopOAuthFlow();
      if (directResult.isSuccess || directResult.isCancelled) {
        return directResult;
      }

      final client = SupabaseService.instance.client;
      if (client == null) {
        return GoogleAuthResult.interactiveChooserRequired();
      }

      // 2. Nếu luồng trực tiếp yêu cầu fallback (ví dụ chạy trên cổng localhost ngẫu nhiên chưa khai báo Origin),
      // kiểm tra xem Google Provider trên Supabase đã bật hay chưa.
      // Nếu chưa bật (external.google == false), mở ngay giao diện Google Account Chooser (kiểu Shopee) trong ứng dụng.
      final isProviderEnabled = await _isSupabaseGoogleProviderEnabled();
      if (!isProviderEnabled) {
        debugPrint(
          '[LiveGoogleAuthService] Mở giao diện Google Account Chooser (Shopee-style) cho người dùng.',
        );
        return GoogleAuthResult.interactiveChooserRequired();
      }

      // 3. Khi Supabase Google Provider đã bật, kích hoạt OAuth kèm queryParams prompt=select_account
      final response = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUri,
        queryParams: const {'prompt': GoogleAuthConfig.promptSelectAccount},
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );

      if (!response) {
        return GoogleAuthResult.failure(
          'Không thể khởi tạo phiên xác thực Google.',
        );
      }

      final user = client.auth.currentUser;
      if (user != null && user.email != null) {
        final displayName =
            (user.userMetadata?['full_name'] as String?) ??
            (user.userMetadata?['name'] as String?) ??
            user.email!.split('@').first;

        return GoogleAuthResult.success(
          email: user.email!,
          displayName: displayName,
          id: user.id,
        );
      }

      // Chờ sự kiện xác thực từ OAuth loopback / callback chuyển hướng
      try {
        final authData = await client.auth.onAuthStateChange
            .firstWhere(
              (data) =>
                  data.event == AuthChangeEvent.signedIn ||
                  data.event == AuthChangeEvent.userUpdated,
            )
            .timeout(const Duration(seconds: 45));

        final updatedUser = authData.session?.user ?? client.auth.currentUser;
        if (updatedUser != null && updatedUser.email != null) {
          final displayName =
              (updatedUser.userMetadata?['full_name'] as String?) ??
              (updatedUser.userMetadata?['name'] as String?) ??
              updatedUser.email!.split('@').first;

          return GoogleAuthResult.success(
            email: updatedUser.email!,
            displayName: displayName,
            id: updatedUser.id,
          );
        }
      } catch (_) {
        // Hết thời gian chờ (timeout) hoặc người dùng hủy/đóng trình duyệt
      }

      return GoogleAuthResult.failure(
        'Phiên xác thực Google chưa hoàn tất hoặc đã bị hủy bởi người dùng.',
      );
    } catch (e) {
      debugPrint('[LiveGoogleAuthService] Ngoại lệ đăng nhập Google: $e');
      return GoogleAuthResult.failure('Lỗi kết nối máy chủ Google OAuth: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client.auth.signOut();
      }
    } catch (e) {
      debugPrint('[LiveGoogleAuthService] Lỗi đăng xuất: $e');
    }
  }
}
