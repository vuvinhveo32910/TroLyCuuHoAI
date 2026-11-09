// File: lib/core/config/supabase_config.dart

/// Cấu hình kết nối Supabase Cloud (PostgreSQL / Realtime / Auth)
/// Tuân thủ nguyên tắc:
/// - Kéo code về máy khác là chạy ngay được với cấu hình mặc định của nhóm
/// - Hỗ trợ ghi đè linh hoạt qua biến môi trường --dart-define nếu cần
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oageskffhndqypwuuaij.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_G_vCmGysKprr-mnkK4EeSg_CrqsGdCM',
  );

  /// Khóa bí mật Supabase (Service Role Secret Key) - Dành cho backend / RPC / Admin scripts.
  /// Không lưu cứng trong mã nguồn để đảm bảo an toàn Git Push Protection.
  /// Truyền qua `--dart-define=SUPABASE_SECRET_KEY=...` nếu cần dùng ở môi trường cục bộ.
  static const String secretKey = String.fromEnvironment(
    'SUPABASE_SECRET_KEY',
    defaultValue: '',
  );

  /// Đường dẫn JWKS (.well-known/jwks.json) phục vụ xác thực chữ ký số JWT của Supabase Auth
  static const String jwksUrl = String.fromEnvironment(
    'SUPABASE_JWKS_URL',
    defaultValue: 'https://oageskffhndqypwuuaij.supabase.co/auth/v1/.well-known/jwks.json',
  );

  /// Alias tương thích ngược
  static String get anonKey => publishableKey;

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
