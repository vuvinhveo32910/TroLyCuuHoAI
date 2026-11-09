// File: lib/core/feedback/ai_feedback_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../supabase/supabase_service.dart';
import 'ai_feedback_model.dart';

/// Dịch vụ quản lý phản hồi & đánh giá AI từ người dùng (User Feedback Loop)
/// Đồng bộ trực tiếp với cơ sở dữ liệu Supabase (Bảng 'ai_feedbacks')
class AiFeedbackService extends ChangeNotifier {
  static final AiFeedbackService instance = AiFeedbackService._internal();

  AiFeedbackService._internal() {
    fetchFeedbacksFromSupabase();
  }

  final List<AiFeedbackModel> _feedbacks = [];

  List<AiFeedbackModel> get feedbacks => List.unmodifiable(_feedbacks);

  int get totalCount => _feedbacks.length;

  int get inaccurateCount =>
      _feedbacks.where((f) => f.feedbackType == AiFeedbackType.inaccurate).length;

  int get helpfulCount =>
      _feedbacks.where((f) => f.feedbackType == AiFeedbackType.helpful).length;

  double get accuracyRate =>
      totalCount > 0 ? (helpfulCount / totalCount * 100.0) : 100.0;

  /// Tải danh sách đánh giá từ Supabase
  Future<void> fetchFeedbacksFromSupabase() async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;

      final res = await client
          .from('ai_feedbacks')
          .select()
          .order('created_at', ascending: false);

      _feedbacks.clear();
      for (final row in res) {
        _feedbacks.add(AiFeedbackModel.fromMap(row));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[AiFeedbackService] Tải feedbacks Supabase (chuẩn bị bảng): $e');
    }
  }

  /// Người dùng gửi đánh giá đúng / sai về kết quả AI
  Future<void> submitFeedback(AiFeedbackModel feedback) async {
    _feedbacks.insert(0, feedback);
    notifyListeners();

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client.from('ai_feedbacks').insert(feedback.toMap());
      }
    } catch (e) {
      debugPrint('[AiFeedbackService] Gửi feedback lên Supabase: $e');
    }
  }

  /// Xóa phản hồi
  Future<void> deleteFeedback(String id) async {
    _feedbacks.removeWhere((f) => f.id == id);
    notifyListeners();

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client.from('ai_feedbacks').delete().eq('id', id);
      }
    } catch (e) {
      debugPrint('[AiFeedbackService] Xóa feedback trên Supabase: $e');
    }
  }

  /// Xuất tập dữ liệu phản hồi người dùng dạng JSON để phục vụ phân tích sai số và huấn luyện lại AI
  String exportFeedbackDatasetJson() {
    final exportData = {
      'exported_at': DateTime.now().toIso8601String(),
      'description':
          'Tập dữ liệu phản hồi từ người dùng về kết quả dự đoán của AI (Đúng/Sai) phục vụ nghiên cứu và cải thiện mô hình.',
      'total_records': _feedbacks.length,
      'stats': {
        'accurate_count': helpfulCount,
        'inaccurate_count': inaccurateCount,
        'accuracy_rate_percent': accuracyRate.toStringAsFixed(1),
      },
      'feedback_records': _feedbacks.map((item) => item.toExportJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Nạp danh sách phản hồi từ cơ sở dữ liệu (Supabase/PostgreSQL)
  void setFeedbacks(List<AiFeedbackModel> items) {
    _feedbacks.clear();
    _feedbacks.addAll(items);
    notifyListeners();
  }
}
