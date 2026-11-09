// File: lib/core/supabase/supabase_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Dịch vụ Singleton quản lý kết nối Supabase Cloud
/// Thiết kế an toàn (Fail-safe): Nếu mất mạng hoặc bảng chưa được tạo, app vẫn chạy bình thường
class SupabaseService extends ChangeNotifier {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _lastError;
  String? get lastError => _lastError;

  DateTime? _lastPingTime;
  DateTime? get lastPingTime => _lastPingTime;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Supabase Client dùng để thực hiện các truy vấn dữ liệu từ ViewModel / Service
  SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Khởi tạo Supabase SDK khi chạy ứng dụng
  Future<bool> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      _lastError = 'Chưa cấu hình Supabase URL hoặc Publishable Key.';
      debugPrint('[SupabaseService] $_lastError');
      return false;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      _isConnected = true;
      _lastPingTime = DateTime.now();
      _lastError = null;
      debugPrint('[SupabaseService] Khởi tạo Supabase thành công: ${SupabaseConfig.url}');
      notifyListeners();
      return true;
    } catch (e) {
      // Bắt ngoại lệ để tránh crash app nếu Supabase đã khởi tạo trước đó hoặc lỗi mạng
      if (e.toString().contains('already been initialized')) {
        _isInitialized = true;
        _isConnected = true;
        _lastError = null;
        notifyListeners();
        return true;
      }
      _isInitialized = false;
      _isConnected = false;
      _lastError = e.toString();
      debugPrint('[SupabaseService] Ngoại lệ khởi tạo Supabase SDK: $e');
      notifyListeners();
      return false;
    }
  }

  /// Kiểm tra trạng thái kết nối tới máy chủ Supabase Cloud
  Future<Map<String, dynamic>> pingConnection() async {
    if (!_isInitialized || client == null) {
      final initOk = await initialize();
      if (!initOk) {
        return {
          'success': false,
          'message': _lastError ?? 'Chưa khởi tạo được kết nối Supabase.',
        };
      }
    }

    try {
      // Gửi ping nhẹ tới Auth Gateway của Supabase
      await client!.auth.getSession();
      _isConnected = true;
      _lastPingTime = DateTime.now();
      notifyListeners();
      return {
        'success': true,
        'message': 'Kết nối máy chủ Supabase thành công! Cổng Auth và API đã sẵn sàng.',
        'timestamp': _lastPingTime,
      };
    } catch (e) {
      _isConnected = false;
      _lastError = e.toString();
      notifyListeners();
      return {
        'success': false,
        'message': 'Lỗi kết nối Supabase: $e',
      };
    }
  }
}
