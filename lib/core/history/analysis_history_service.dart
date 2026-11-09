// File: lib/core/history/analysis_history_service.dart
import 'package:flutter/foundation.dart';

import '../../features/user/models/history_models.dart';
import '../supabase/supabase_service.dart';

/// Dịch vụ Singleton quản lý Lịch sử quét & Phân tích chẩn đoán hình ảnh vết thương
/// Đồng bộ trực tiếp hai chiều với máy chủ cơ sở dữ liệu Supabase (Bảng 'analysis_history')
class AnalysisHistoryService extends ChangeNotifier {
  static final AnalysisHistoryService instance = AnalysisHistoryService._internal();

  AnalysisHistoryService._internal() {
    fetchHistoryFromSupabase();
  }

  final List<AnalysisHistoryItemModel> _items = [];
  List<AnalysisHistoryItemModel> get items => List.unmodifiable(_items);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _lastError;
  String? get lastError => _lastError;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  // ===========================================================================
  // CÁC CHỈ SỐ THỐNG KÊ THỜI GIAN THỰC (TÍNH TỪ DỮ LIỆU THẬT TRÊN SUPABASE)
  // ===========================================================================

  /// Tổng số ca quét đã thực hiện
  int get totalScans => _items.length;

  /// Độ tin cậy AI trung bình (%)
  double get averageConfidence {
    if (_items.isEmpty) return 0.0;
    final total = _items.fold<double>(
      0.0,
      (sum, item) => sum + (item.confidencePercent ?? 80).toDouble(),
    );
    return double.parse((total / _items.length).toStringAsFixed(1));
  }

  /// Số ca có mức độ nghiêm trọng (Nặng / Khẩn cấp)
  int get severeCount => _items
      .where((i) =>
          i.severityLevel.toLowerCase() == 'severe' ||
          i.severityLevel.toLowerCase() == 'nặng' ||
          i.severityLevel.toLowerCase() == 'nang')
      .length;

  /// Số ca mức độ trung bình (Vừa)
  int get moderateCount => _items
      .where((i) =>
          i.severityLevel.toLowerCase() == 'moderate' ||
          i.severityLevel.toLowerCase() == 'vừa' ||
          i.severityLevel.toLowerCase() == 'vua')
      .length;

  /// Số ca mức độ nhẹ
  int get mildCount => _items
      .where((i) =>
          i.severityLevel.toLowerCase() == 'mild' ||
          i.severityLevel.toLowerCase() == 'nhẹ' ||
          i.severityLevel.toLowerCase() == 'nhe')
      .length;

  /// Số người dùng riêng biệt đã quét
  int get uniqueUsersCount {
    final users = _items
        .map((i) => i.username?.trim().toLowerCase())
        .where((u) => u != null && u.isNotEmpty)
        .toSet();
    return users.length;
  }

  /// Thống kê phân bố theo từng nhóm loại vết thương
  Map<String, int> get injuryDistribution {
    final Map<String, int> counts = {};
    for (final item in _items) {
      final name = item.injuryType.trim();
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts;
  }

  // ===========================================================================
  // CÁC HÀM TRUY VẤN VÀ ĐỒNG BỘ DỮ LIỆU VỚI SUPABASE
  // ===========================================================================

  /// Nạp toàn bộ lịch sử phân tích từ bảng 'analysis_history' trên Supabase
  Future<void> fetchHistoryFromSupabase({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        _lastError = 'Chưa kết nối máy chủ Supabase.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final res = await client
          .from('analysis_history')
          .select()
          .order('created_at', ascending: false);

      _items.clear();
      for (final row in res) {
        _items.add(AnalysisHistoryItemModel.fromMap(row));
      }

      _lastError = null;
      _lastSyncTime = DateTime.now();
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[AnalysisHistoryService] Tải lịch sử Supabase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ghi nhận một ca phân tích mới trực tiếp vào Supabase
  Future<bool> recordAnalysis({
    String? username,
    required String injuryTypeId,
    required String injuryTypeName,
    required double confidenceScore,
    String severityLevel = 'moderate',
    String? imageUrl,
    List<String> symptoms = const [],
    int painLevel = 0,
    String? firstAidSummary,
  }) async {
    final now = DateTime.now();

    final optimisticItem = AnalysisHistoryItemModel(
      id: 'local_${now.millisecondsSinceEpoch}',
      username: username,
      injuryType: injuryTypeName,
      confidencePercent: confidenceScore.round(),
      severityLevel: severityLevel,
      locationLabel: 'Vùng tổn thương',
      timestamp: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      dateTime: now,
      imageSourceName: imageUrl,
      relatedTopicId: injuryTypeId,
      symptoms: symptoms,
      painLevel: painLevel,
      firstAidSummary: firstAidSummary,
    );

    _items.insert(0, optimisticItem);
    notifyListeners();

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        final inserted = await client.from('analysis_history').insert({
          'username': username,
          'injury_type_id': injuryTypeId,
          'injury_type_name': injuryTypeName,
          'confidence_score': confidenceScore,
          'severity_level': severityLevel,
          'image_url': imageUrl,
          'symptoms': symptoms,
          'pain_level': painLevel,
          'first_aid_summary': firstAidSummary,
          'created_at': now.toIso8601String(),
        }).select().maybeSingle();

        if (inserted != null && inserted['id'] != null) {
          // Cập nhật ID thật từ Supabase
          final idx = _items.indexOf(optimisticItem);
          if (idx != -1) {
            _items[idx] = AnalysisHistoryItemModel.fromMap(inserted);
            notifyListeners();
          }
        }
        return true;
      }
    } catch (e) {
      debugPrint('[AnalysisHistoryService] Ghi nhận lịch sử Supabase lỗi: $e');
    }
    return false;
  }

  /// Xóa một ca quét khỏi bảng 'analysis_history' trên Supabase
  Future<bool> deleteRecord(String id) async {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client.from('analysis_history').delete().eq('id', id);
        return true;
      }
    } catch (e) {
      debugPrint('[AnalysisHistoryService] Lỗi xóa bản ghi Supabase: $e');
    }
    return false;
  }

  /// Thêm dữ liệu mẫu thực tế vào Supabase (dành cho người quản trị muốn khởi tạo dữ liệu mẫu kiểm thử)
  Future<void> seedSampleDataToSupabase() async {
    _isLoading = true;
    notifyListeners();

    final samples = [
      {
        'username': 'admin',
        'injury_type_id': 'abrasion',
        'injury_type_name': 'Trầy xước ngoài da',
        'confidence_score': 92.5,
        'severity_level': 'mild',
        'pain_level': 2,
        'symptoms': ['Chảy máu rỉ rỉ', 'Rát bề mặt biểu bì', 'Bụi cát bám dính'],
        'first_aid_summary': 'Rửa sạch bằng nước muối 0.9%, sát khuẩn bằng Povidone-Iodine và dán gạc vô trùng thoáng.',
        'created_at': DateTime.now().subtract(const Duration(minutes: 35)).toIso8601String(),
      },
      {
        'username': 'benhnhan_01',
        'injury_type_id': 'cut_laceration',
        'injury_type_name': 'Vết cắt / rách da',
        'confidence_score': 88.0,
        'severity_level': 'severe',
        'pain_level': 7,
        'symptoms': ['Chảy máu nhiều', 'Vết rách sâu quá 0.5cm', 'Vết cắt kim loại sắc'],
        'first_aid_summary': 'Ấn ép trực tiếp gạc vô trùng cầm máu khẩn cấp, nâng cao chi tổn thương và khẩn trương đến viện khâu vết thương.',
        'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'username': 'benhnhan_02',
        'injury_type_id': 'burn',
        'injury_type_name': 'Bỏng nhiệt',
        'confidence_score': 85.0,
        'severity_level': 'moderate',
        'pain_level': 5,
        'symptoms': ['Da đỏ rát', 'Phồng rộp bọng nước', 'Bỏng nước sôi diện tích nhỏ'],
        'first_aid_summary': 'Xả nước mát sạch (15-25°C) liên tục trong 15-20 phút. Tuyệt đối không chườm đá lạnh buốt hay chọc vỡ bọng nước.',
        'created_at': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
      },
      {
        'username': null, // Khách vãng lai
        'injury_type_id': 'bruise',
        'injury_type_name': 'Bầm tím phần mềm',
        'confidence_score': 79.5,
        'severity_level': 'mild',
        'pain_level': 3,
        'symptoms': ['Tụ máu dưới da', 'Đổi màu xanh tím', 'Đau khi ấn vào'],
        'first_aid_summary': 'Chườm lạnh gián tiếp qua khăn sạch 15 phút để co mạch giảm phù nề, nghỉ ngơi vùng va đập.',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client.from('analysis_history').insert(samples);
        await fetchHistoryFromSupabase(silent: true);
      }
    } catch (e) {
      debugPrint('[AnalysisHistoryService] Lỗi tạo dữ liệu mẫu: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
