// File: lib/core/storage/local_storage_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dịch vụ lưu trữ cục bộ SharedPreferences (Hỗ trợ 100% cả Windows Desktop và Flutter Web)
/// Quản lý ghi nhớ đăng nhập cho cả Quản trị viên (/admin) và Người dùng
class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  // Keys cho Admin
  static const String _keyAdminRemember = 'auth_admin_remember_me';
  static const String _keyAdminUsername = 'auth_admin_saved_username';
  static const String _keyAdminPassword = 'auth_admin_saved_password';
  static const String _keyAdminIsLoggedIn = 'auth_admin_is_logged_in';

  // Keys cho Người dùng
  static const String _keyUserRemember = 'auth_user_remember_me';
  static const String _keyUserUsername = 'auth_user_saved_username';
  static const String _keyUserPassword = 'auth_user_saved_password';
  static const String _keyUserIsLoggedIn = 'auth_user_is_logged_in';

  // ===========================================================================
  // QUẢN LÝ GHI NHỚ ĐĂNG NHẬP ADMIN (/admin)
  // ===========================================================================

  /// Lưu thông tin tài khoản Admin khi đăng nhập thành công
  Future<void> saveAdminCredentials({
    required bool rememberMe,
    required String username,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAdminRemember, rememberMe);
      if (rememberMe) {
        await prefs.setString(_keyAdminUsername, username);
        await prefs.setString(_keyAdminPassword, password);
        await prefs.setBool(_keyAdminIsLoggedIn, true);
        debugPrint('[LocalStorage] Đã ghi nhớ tài khoản Admin: $username');
      } else {
        await prefs.remove(_keyAdminUsername);
        await prefs.remove(_keyAdminPassword);
        await prefs.setBool(_keyAdminIsLoggedIn, false);
        debugPrint('[LocalStorage] Đã xóa ghi nhớ tài khoản Admin');
      }
    } catch (e) {
      debugPrint('[LocalStorage] Lỗi lưu thông tin Admin: $e');
    }
  }

  /// Nạp thông tin tài khoản Admin đã ghi nhớ (dùng để tự điền form)
  Future<Map<String, dynamic>> loadAdminCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_keyAdminRemember) ?? true;
      final username = prefs.getString(_keyAdminUsername) ?? '';
      final password = prefs.getString(_keyAdminPassword) ?? '';
      final isLoggedIn = prefs.getBool(_keyAdminIsLoggedIn) ?? false;

      return {
        'rememberMe': rememberMe,
        'username': username,
        'password': password,
        'isLoggedIn': isLoggedIn,
      };
    } catch (e) {
      debugPrint('[LocalStorage] Lỗi đọc thông tin Admin: $e');
      return {
        'rememberMe': true,
        'username': '',
        'password': '',
        'isLoggedIn': false,
      };
    }
  }

  /// Đăng xuất và xóa phiên đăng nhập Admin
  Future<void> clearAdminSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAdminIsLoggedIn, false);
      // Giữ lại username/password nếu rememberMe đang bật, hoặc xóa hẳn nếu uncheck
      final rememberMe = prefs.getBool(_keyAdminRemember) ?? false;
      if (!rememberMe) {
        await prefs.remove(_keyAdminUsername);
        await prefs.remove(_keyAdminPassword);
      }
    } catch (e) {
      debugPrint('[LocalStorage] Lỗi xóa phiên Admin: $e');
    }
  }

  // ===========================================================================
  // QUẢN LÝ GHI NHỚ ĐĂNG NHẬP NGƯỜI DÙNG (USER APP)
  // ===========================================================================

  /// Lưu thông tin tài khoản Người dùng khi đăng nhập
  Future<void> saveUserCredentials({
    required bool rememberMe,
    required String username,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyUserRemember, rememberMe);
      if (rememberMe) {
        await prefs.setString(_keyUserUsername, username);
        await prefs.setString(_keyUserPassword, password);
        await prefs.setBool(_keyUserIsLoggedIn, true);
        debugPrint('[LocalStorage] Đã ghi nhớ tài khoản người dùng: $username');
      } else {
        await prefs.remove(_keyUserUsername);
        await prefs.remove(_keyUserPassword);
        await prefs.setBool(_keyUserIsLoggedIn, false);
        debugPrint('[LocalStorage] Đã xóa ghi nhớ tài khoản người dùng');
      }
    } catch (e) {
      debugPrint('[LocalStorage] Lỗi lưu thông tin người dùng: $e');
    }
  }

  /// Nạp thông tin tài khoản Người dùng đã ghi nhớ
  Future<Map<String, dynamic>> loadUserCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_keyUserRemember) ?? true;
      final username = prefs.getString(_keyUserUsername) ?? '';
      final password = prefs.getString(_keyUserPassword) ?? '';
      final isLoggedIn = prefs.getBool(_keyUserIsLoggedIn) ?? false;

      return {
        'rememberMe': rememberMe,
        'username': username,
        'password': password,
        'isLoggedIn': isLoggedIn,
      };
    } catch (e) {
      debugPrint('[LocalStorage] Lỗi đọc thông tin người dùng: $e');
      return {
        'rememberMe': true,
        'username': '',
        'password': '',
        'isLoggedIn': false,
      };
    }
  }

  /// Đăng xuất tài khoản người dùng
  Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyUserIsLoggedIn, false);
      final rememberMe = prefs.getBool(_keyUserRemember) ?? false;
      if (!rememberMe) {
        await prefs.remove(_keyUserUsername);
        await prefs.remove(_keyUserPassword);
      }
    } catch (e) {
      debugPrint('[LocalStorage] Lỗi xóa phiên người dùng: $e');
    }
  }
}
