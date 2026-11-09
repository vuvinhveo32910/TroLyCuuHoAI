// File: lib/core/feedback/ai_feedback_model.dart
import 'dart:typed_data';

/// Loại đánh giá của người dùng về kết quả AI
enum AiFeedbackType {
  helpful, // Đúng / Hài lòng / Hữu ích
  inaccurate, // Sai / Không chính xác / Nhận diện nhầm
}

/// Nguồn mô hình AI tạo ra kết quả
enum AiSourceModel {
  yoloVision, // Mô hình thị giác máy tính YOLO nhận diện vết thương
  medgemma, // Mô hình ngôn ngữ MedGemma cục bộ tư vấn tài liệu
  gemini, // Mô hình Google Gemini Flash API
}

/// Mô hình phản hồi & đánh giá AI của người dùng (User Feedback)
/// Phục vụ thu thập dữ liệu thực nghiệm để nâng cấp mô hình AI trong tương lai.
class AiFeedbackModel {
  final String id;
  final String? analysisId; // ID phiên quét ảnh hoặc tin nhắn chat
  final DateTime timestamp;
  final String userDisplayName; // Zero-Knowledge: @username hoặc 'Khách ẩn danh'
  final AiSourceModel sourceModel;
  final AiFeedbackType feedbackType; // helpful (Đúng) / inaccurate (Sai)
  final String issueCategory; // Phân loại lỗi người dùng chọn
  final String userComment; // Lý do phản ánh chi tiết của người dùng
  final String? userProposedLabel; // Nhãn người dùng nhận định (ví dụ: 'Trầy xước ngoài da')
  final String detectedWoundSummary; // Kết quả AI dự đoán ban đầu (ví dụ: 'Bỏng nhiệt (88%)')
  final String? woundLocation; // Vị trí tổn thương (ví dụ: 'Cẳng tay')
  final String? painLevel; // Mức độ đau (ví dụ: 'Đau nhẹ 1-4/10')
  final List<String> observedSymptoms; // Triệu chứng kèm theo
  final Uint8List? imageBytes; // Ảnh vết thương (nếu có)
  final String? imageFileName; // Tên file ảnh (nếu có)

  const AiFeedbackModel({
    required this.id,
    this.analysisId,
    required this.timestamp,
    this.userDisplayName = 'Khách ẩn danh',
    this.sourceModel = AiSourceModel.yoloVision,
    required this.feedbackType,
    required this.issueCategory,
    required this.userComment,
    this.userProposedLabel,
    required this.detectedWoundSummary,
    this.woundLocation,
    this.painLevel,
    this.observedSymptoms = const [],
    this.imageBytes,
    this.imageFileName,
  });

  bool get isInaccurate => feedbackType == AiFeedbackType.inaccurate;
  bool get isHelpful => feedbackType == AiFeedbackType.helpful;

  String get sourceModelLabel {
    switch (sourceModel) {
      case AiSourceModel.yoloVision:
        return 'YOLO Vision';
      case AiSourceModel.medgemma:
        return 'MedGemma Local';
      case AiSourceModel.gemini:
        return 'Gemini API';
    }
  }

  String get feedbackTypeLabel =>
      isInaccurate ? 'Sai / Không chính xác' : 'Đúng / Hữu ích';

  AiFeedbackModel copyWith({
    String? id,
    String? analysisId,
    DateTime? timestamp,
    String? userDisplayName,
    AiSourceModel? sourceModel,
    AiFeedbackType? feedbackType,
    String? issueCategory,
    String? userComment,
    String? userProposedLabel,
    String? detectedWoundSummary,
    String? woundLocation,
    String? painLevel,
    List<String>? observedSymptoms,
    Uint8List? imageBytes,
    String? imageFileName,
  }) {
    return AiFeedbackModel(
      id: id ?? this.id,
      analysisId: analysisId ?? this.analysisId,
      timestamp: timestamp ?? this.timestamp,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      sourceModel: sourceModel ?? this.sourceModel,
      feedbackType: feedbackType ?? this.feedbackType,
      issueCategory: issueCategory ?? this.issueCategory,
      userComment: userComment ?? this.userComment,
      userProposedLabel: userProposedLabel ?? this.userProposedLabel,
      detectedWoundSummary: detectedWoundSummary ?? this.detectedWoundSummary,
      woundLocation: woundLocation ?? this.woundLocation,
      painLevel: painLevel ?? this.painLevel,
      observedSymptoms: observedSymptoms ?? this.observedSymptoms,
      imageBytes: imageBytes ?? this.imageBytes,
      imageFileName: imageFileName ?? this.imageFileName,
    );
  }

  Map<String, dynamic> toExportJson() {
    return {
      'feedback_id': id,
      'analysis_id': analysisId,
      'timestamp': timestamp.toIso8601String(),
      'source_model': sourceModel.name,
      'user_evaluation': isInaccurate ? 'inaccurate' : 'helpful',
      'ai_prediction': detectedWoundSummary,
      'user_proposed_label': userProposedLabel,
      'issue_category': issueCategory,
      'user_comment': userComment,
      'clinical_context': {
        'location': woundLocation,
        'pain_level': painLevel,
        'symptoms': observedSymptoms,
      },
      'image_file': imageFileName,
    };
  }

  /// Chuyển đổi Model sang Map JSON tương thích với bảng 'ai_feedbacks' trong Supabase (PostgreSQL)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'analysis_id': analysisId,
      'created_at': timestamp.toIso8601String(),
      'user_display_name': userDisplayName,
      'source_model': sourceModel.name,
      'feedback_type': feedbackType.name,
      'issue_category': issueCategory,
      'user_comment': userComment,
      'user_proposed_label': userProposedLabel,
      'detected_wound_summary': detectedWoundSummary,
      'wound_location': woundLocation,
      'pain_level': painLevel,
      'observed_symptoms': observedSymptoms,
      'image_file_name': imageFileName,
    };
  }

  /// Khởi tạo Model từ dữ liệu truy vấn Supabase (hỗ trợ cả snake_case và camelCase)
  factory AiFeedbackModel.fromMap(Map<String, dynamic> map) {
    final rawDate = map['created_at'] as String? ??
        map['timestamp'] as String?;
    final parsedDate = rawDate != null
        ? (DateTime.tryParse(rawDate) ?? DateTime.now())
        : DateTime.now();

    final rawSource = map['source_model'] as String? ?? map['sourceModel'] as String?;
    AiSourceModel resolvedSource = AiSourceModel.yoloVision;
    if (rawSource != null) {
      for (final sm in AiSourceModel.values) {
        if (sm.name.toLowerCase() == rawSource.toLowerCase()) {
          resolvedSource = sm;
          break;
        }
      }
    }

    final rawType = map['feedback_type'] as String? ?? map['feedbackType'] as String?;
    AiFeedbackType resolvedType = AiFeedbackType.helpful;
    if (rawType != null && rawType.toLowerCase() == 'inaccurate') {
      resolvedType = AiFeedbackType.inaccurate;
    }

    return AiFeedbackModel(
      id: map['id']?.toString() ?? '',
      analysisId: map['analysis_id'] as String? ?? map['analysisId'] as String?,
      timestamp: parsedDate,
      userDisplayName: map['user_display_name'] as String? ??
          map['userDisplayName'] as String? ??
          'Khách ẩn danh',
      sourceModel: resolvedSource,
      feedbackType: resolvedType,
      issueCategory: map['issue_category'] as String? ??
          map['issueCategory'] as String? ??
          '',
      userComment: map['user_comment'] as String? ??
          map['userComment'] as String? ??
          '',
      userProposedLabel: map['user_proposed_label'] as String? ??
          map['userProposedLabel'] as String?,
      detectedWoundSummary: map['detected_wound_summary'] as String? ??
          map['detectedWoundSummary'] as String? ??
          '',
      woundLocation: map['wound_location'] as String? ??
          map['woundLocation'] as String?,
      painLevel: map['pain_level'] as String? ??
          map['painLevel'] as String?,
      observedSymptoms: List<String>.from(
        map['observed_symptoms'] as List? ??
            map['observedSymptoms'] as List? ??
            const [],
      ),
      imageFileName: map['image_file_name'] as String? ??
          map['imageFileName'] as String? ??
          map['image_url'] as String?,
      imageBytes: null,
    );
  }
}
