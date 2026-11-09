// File: lib/core/config/google_auth_config.dart

/// Cấu hình Google OAuth & Chế độ kiểm thử (Mock / Simulation Mode)
/// Tuân thủ nguyên tắc:
/// - Hỗ trợ thiết lập Client ID qua compile-time define `--dart-define=GOOGLE_CLIENT_ID=...`
/// - Tự động kích hoạt Mock/Simulation Mode khi chưa cấu hình Client ID thực tế (theo Yêu cầu R4)
/// - Hỗ trợ môi trường Flutter Web, Mobile, và Headless Automated Tests
class GoogleAuthConfig {
  GoogleAuthConfig._();

  /// Google Client ID chính thức của dự án (Web / Desktop / Mobile)
  static const String defaultClientId =
      '639331646818-7giedfmjuotg4momqaad9atajbvj0r7r.apps.googleusercontent.com';

  /// Google Client Secret (truyền qua `--dart-define=GOOGLE_CLIENT_SECRET=...` khi cần, không lưu cứng trong git)
  static const String defaultClientSecret = '';

  /// Google OAuth 2.0 Endpoints
  static const String authEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const String tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const String userinfoEndpoint = 'https://www.googleapis.com/oauth2/v3/userinfo';

  /// Tham số Shopee-like Account Chooser & Scopes
  static const String promptSelectAccount = 'select_account';
  static const String oauthScopes = 'openid email profile';

  /// RFC 8252 Desktop Loopback Configuration
  static const int desktopLoopbackPort = 8080;
  static const String desktopRedirectUri = 'http://localhost:8080/auth/callback';
  static const String desktopCallbackPath = '/auth/callback';

  /// Google Client ID cho Web / Desktop / Mobile
  /// Có thể truyền qua: `flutter run --dart-define=GOOGLE_CLIENT_ID=xyz.apps.googleusercontent.com`
  static const String clientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: defaultClientId,
  );

  /// Google Client Secret
  static const String clientSecret = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET',
    defaultValue: defaultClientSecret,
  );

  /// Server Client ID tùy chọn (dùng cho backend verification nếu cần)
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// Biến môi trường chỉ định ép buộc chế độ Mock/Simulation
  static const bool _forceMockEnv = bool.fromEnvironment(
    'GOOGLE_OAUTH_MOCK',
    defaultValue: false,
  );

  /// Cho phép can thiệp ghi đè mock mode trong Unit Test
  static bool? _mockOverride;

  /// Thiết lập ghi đè chế độ Mock (chỉ dùng cho testing)
  static void setMockOverride(bool? override) {
    _mockOverride = override;
  }

  /// Kiểm tra xem Client ID thực tế đã được cấu hình hợp lệ hay chưa
  static bool get isConfigured {
    if (clientId.trim().isEmpty) return false;
    final lower = clientId.toLowerCase();
    if (lower.contains('placeholder') ||
        lower.contains('your_google_client_id') ||
        lower.contains('your_client_id') ||
        lower == 'none') {
      return false;
    }
    return true;
  }

  /// Xác định hệ thống có đang chạy ở chế độ Mock / Simulation hay không
  /// Tự động bật mock khi:
  /// 1. Được ghi đè thủ công qua `setMockOverride(true)`
  /// 2. Được thiết lập qua `--dart-define=GOOGLE_OAUTH_MOCK=true`
  /// 3. Chưa cấu hình Google Client ID thực tế (thỏa mãn R4: kiểm thử zero-config)
  static bool get isMockMode {
    if (_mockOverride != null) return _mockOverride!;
    if (_forceMockEnv) return true;
    return !isConfigured;
  }

  // ===========================================================================
  // DỮ LIỆU NGƯỜI DÙNG MẪU CHO MOCK / KIỂM THỬ (R4)
  // ===========================================================================
  static const String defaultMockEmail = 'testuser.rescue@gmail.com';
  static const String defaultMockDisplayName = 'Người dùng Google Demo';
  static const String defaultMockId = 'google_uid_test_108234918234';
}
