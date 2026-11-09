import '../../../core/rule_engine/rule_models.dart';
import 'ai_sensitivity_mode.dart';

export 'ai_sensitivity_mode.dart';

/// Danh sách tên các phạm trù vết thương chuẩn
const Map<String, String> kInjuryTopicNames = {
  'abrasion': 'Trầy xước ngoài da',
  'cut_laceration': 'Vết cắt / rách da',
  'burn': 'Bỏng nhiệt / hóa chất',
  'bruise': 'Bầm tím phần mềm',
  'other_wounds': 'Vết thương khác',
};

String getInjuryTopicName(String topicId) {
  return kInjuryTopicNames[topicId] ?? 'Vết thương khác';
}

/// Mô hình bài viết kiến thức trong Knowledge Base (Admin CRUD)
class KnowledgeArticleModel {
  final String id;
  final String title;
  final String categoryId;
  final String categoryName;
  final String summary;
  final String targetInjuryTypeId; // 'abrasion', 'cut_laceration', 'burn', 'bruise', 'other_wounds'
  final String targetInjuryTypeName;
  final RuleSeverityLevel defaultSeverity;
  final List<String> steps;
  final List<String> warnings;
  final List<String> contraindications; // Việc cấm kỵ
  final String lastUpdated;
  final bool isPublished;
  final String? sourceUrl; // Đường dẫn web tài liệu nguồn
  final String? sourceOrganization; // Tên tổ chức y tế (Bộ Y Tế, WHO, Hội Chữ Thập Đỏ...)

  const KnowledgeArticleModel({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.summary,
    required this.targetInjuryTypeId,
    this.targetInjuryTypeName = '',
    this.defaultSeverity = RuleSeverityLevel.normal,
    required this.steps,
    required this.warnings,
    this.contraindications = const [],
    required this.lastUpdated,
    this.isPublished = true,
    this.sourceUrl,
    this.sourceOrganization,
  });

  String get effectiveInjuryTypeName =>
      targetInjuryTypeName.isNotEmpty ? targetInjuryTypeName : getInjuryTopicName(targetInjuryTypeId);

  KnowledgeArticleModel copyWith({
    String? id,
    String? title,
    String? categoryId,
    String? categoryName,
    String? summary,
    String? targetInjuryTypeId,
    String? targetInjuryTypeName,
    RuleSeverityLevel? defaultSeverity,
    List<String>? steps,
    List<String>? warnings,
    List<String>? contraindications,
    String? lastUpdated,
    bool? isPublished,
    String? sourceUrl,
    String? sourceOrganization,
  }) {
    return KnowledgeArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      summary: summary ?? this.summary,
      targetInjuryTypeId: targetInjuryTypeId ?? this.targetInjuryTypeId,
      targetInjuryTypeName: targetInjuryTypeName ?? this.targetInjuryTypeName,
      defaultSeverity: defaultSeverity ?? this.defaultSeverity,
      steps: steps ?? this.steps,
      warnings: warnings ?? this.warnings,
      contraindications: contraindications ?? this.contraindications,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isPublished: isPublished ?? this.isPublished,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceOrganization: sourceOrganization ?? this.sourceOrganization,
    );
  }

  /// Chuyển đổi Model sang Map JSON tương thích với bảng 'knowledge_articles' trong Supabase (PostgreSQL)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category_id': categoryId,
      'category_name': categoryName,
      'summary': summary,
      'target_injury_type_id': targetInjuryTypeId,
      'target_injury_type_name': targetInjuryTypeName,
      'default_severity': defaultSeverity.name,
      'steps': steps,
      'warnings': warnings,
      'contraindications': contraindications,
      'last_updated': lastUpdated,
      'is_published': isPublished,
      'source_url': sourceUrl,
      'source_organization': sourceOrganization,
    };
  }

  /// Khởi tạo Model từ dữ liệu truy vấn Supabase (hỗ trợ cả snake_case và camelCase)
  factory KnowledgeArticleModel.fromMap(Map<String, dynamic> map) {
    final rawSeverity = map['default_severity'] as String? ?? map['defaultSeverity'] as String?;
    RuleSeverityLevel severity = RuleSeverityLevel.normal;
    if (rawSeverity != null) {
      for (final s in RuleSeverityLevel.values) {
        if (s.name.toLowerCase() == rawSeverity.toLowerCase()) {
          severity = s;
          break;
        }
      }
    }

    return KnowledgeArticleModel(
      id: map['id']?.toString() ?? '',
      title: map['title'] as String? ?? '',
      categoryId: map['category_id'] as String? ?? map['categoryId'] as String? ?? 'other',
      categoryName: map['category_name'] as String? ?? map['categoryName'] as String? ?? 'Vết thương khác',
      summary: map['summary'] as String? ?? '',
      targetInjuryTypeId: map['target_injury_type_id'] as String? ?? map['targetInjuryTypeId'] as String? ?? 'other_wounds',
      targetInjuryTypeName: map['target_injury_type_name'] as String? ?? map['targetInjuryTypeName'] as String? ?? '',
      defaultSeverity: severity,
      steps: List<String>.from(map['steps'] as List? ?? const []),
      warnings: List<String>.from(map['warnings'] as List? ?? const []),
      contraindications: List<String>.from(map['contraindications'] as List? ?? const []),
      lastUpdated: map['last_updated'] as String? ?? map['lastUpdated'] as String? ?? '',
      isPublished: map['is_published'] as bool? ?? map['isPublished'] as bool? ?? true,
      sourceUrl: map['source_url'] as String? ?? map['sourceUrl'] as String?,
      sourceOrganization: map['source_organization'] as String? ?? map['sourceOrganization'] as String?,
    );
  }
}

/// Mô hình nhóm loại tổn thương được hệ thống hỗ trợ (Admin CRUD)
class SupportedInjuryTypeModel {
  final String id; // 'tray_xuoc', 'vet_cat_rach', 'bong', 'bam_tim', etc.
  final String name;
  final String topicId;
  final RuleSeverityLevel defaultSeverity;
  final AiSensitivityMode sensitivityMode; // Chế độ nhạy AI thay cho ngưỡng số thô
  final bool isAiDetectionEnabled; // Bật/tắt AI nhận diện
  final String description;
  final int totalScansRecorded;

  // Giữ tương thích ngược với code cũ
  double get minConfidenceThreshold => sensitivityMode.thresholdValue;

  const SupportedInjuryTypeModel({
    required this.id,
    required this.name,
    required this.topicId,
    required this.defaultSeverity,
    this.sensitivityMode = AiSensitivityMode.balanced,
    this.isAiDetectionEnabled = true,
    required this.description,
    this.totalScansRecorded = 0,
  });

  SupportedInjuryTypeModel copyWith({
    String? id,
    String? name,
    String? topicId,
    RuleSeverityLevel? defaultSeverity,
    AiSensitivityMode? sensitivityMode,
    double? minConfidenceThreshold,
    bool? isAiDetectionEnabled,
    String? description,
    int? totalScansRecorded,
  }) {
    AiSensitivityMode resolvedSensitivity = sensitivityMode ?? this.sensitivityMode;
    if (minConfidenceThreshold != null) {
      if (minConfidenceThreshold <= 0.40) {
        resolvedSensitivity = AiSensitivityMode.lenient;
      } else if (minConfidenceThreshold >= 0.65) {
        resolvedSensitivity = AiSensitivityMode.strict;
      } else {
        resolvedSensitivity = AiSensitivityMode.balanced;
      }
    }

    return SupportedInjuryTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      topicId: topicId ?? this.topicId,
      defaultSeverity: defaultSeverity ?? this.defaultSeverity,
      sensitivityMode: resolvedSensitivity,
      isAiDetectionEnabled: isAiDetectionEnabled ?? this.isAiDetectionEnabled,
      description: description ?? this.description,
      totalScansRecorded: totalScansRecorded ?? this.totalScansRecorded,
    );
  }

  /// Chuyển đổi Model sang Map JSON tương thích với bảng 'supported_injury_types' trong Supabase (PostgreSQL)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'topic_id': topicId,
      'default_severity': defaultSeverity.name,
      'sensitivity_mode': sensitivityMode.name,
      'is_ai_detection_enabled': isAiDetectionEnabled,
      'description': description,
      'total_scans_recorded': totalScansRecorded,
    };
  }

  /// Khởi tạo Model từ dữ liệu truy vấn Supabase (hỗ trợ cả snake_case và camelCase)
  factory SupportedInjuryTypeModel.fromMap(Map<String, dynamic> map) {
    final rawSeverity = map['default_severity'] as String? ?? map['defaultSeverity'] as String?;
    RuleSeverityLevel severity = RuleSeverityLevel.normal;
    if (rawSeverity != null) {
      for (final s in RuleSeverityLevel.values) {
        if (s.name.toLowerCase() == rawSeverity.toLowerCase()) {
          severity = s;
          break;
        }
      }
    }

    final rawSensitivity = map['sensitivity_mode'] as String? ?? map['sensitivityMode'] as String?;
    AiSensitivityMode sensitivity = AiSensitivityMode.balanced;
    if (rawSensitivity != null) {
      for (final sm in AiSensitivityMode.values) {
        if (sm.name.toLowerCase() == rawSensitivity.toLowerCase()) {
          sensitivity = sm;
          break;
        }
      }
    }

    return SupportedInjuryTypeModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      topicId: map['topic_id'] as String? ?? map['topicId'] as String? ?? 'abrasion',
      defaultSeverity: severity,
      sensitivityMode: sensitivity,
      isAiDetectionEnabled: map['is_ai_detection_enabled'] as bool? ?? map['isAiDetectionEnabled'] as bool? ?? true,
      description: map['description'] as String? ?? '',
      totalScansRecorded: (map['total_scans_recorded'] as num?)?.toInt() ?? (map['totalScansRecorded'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Mô hình cấu hình hệ thống (Admin Settings)
class AdminSystemConfigModel {
  final AiSensitivityMode globalSensitivityMode; // Chế độ nhạy AI toàn hệ thống
  final bool isEmergency115AlertEnabled; // Bật chuông/banner đỏ khi phát hiện nguy cấp
  final bool isAutoGuideEnabled; // Tự động mở hướng dẫn khi độ tin cậy cao
  final String emergencyPhone; // 115
  final String yoloModelVersion; // YOLOv8 best.pt
  final String aiServerEndpoint; // http://127.0.0.1:8000
  final bool isMaintenanceMode;

  double get globalConfidenceThreshold => globalSensitivityMode.thresholdPercent.toDouble();

  const AdminSystemConfigModel({
    this.globalSensitivityMode = AiSensitivityMode.balanced,
    this.isEmergency115AlertEnabled = true,
    this.isAutoGuideEnabled = true,
    this.emergencyPhone = '115',
    this.yoloModelVersion = 'YOLOv8 Wound Detection (best.pt)',
    this.aiServerEndpoint = 'http://127.0.0.1:8000',
    this.isMaintenanceMode = false,
  });

  AdminSystemConfigModel copyWith({
    AiSensitivityMode? globalSensitivityMode,
    double? globalConfidenceThreshold,
    bool? isEmergency115AlertEnabled,
    bool? isAutoGuideEnabled,
    String? emergencyPhone,
    String? yoloModelVersion,
    String? aiServerEndpoint,
    bool? isMaintenanceMode,
  }) {
    AiSensitivityMode resolvedMode = globalSensitivityMode ?? this.globalSensitivityMode;
    if (globalConfidenceThreshold != null) {
      if (globalConfidenceThreshold <= 40) {
        resolvedMode = AiSensitivityMode.lenient;
      } else if (globalConfidenceThreshold >= 65) {
        resolvedMode = AiSensitivityMode.strict;
      } else {
        resolvedMode = AiSensitivityMode.balanced;
      }
    }

    return AdminSystemConfigModel(
      globalSensitivityMode: resolvedMode,
      isEmergency115AlertEnabled:
          isEmergency115AlertEnabled ?? this.isEmergency115AlertEnabled,
      isAutoGuideEnabled: isAutoGuideEnabled ?? this.isAutoGuideEnabled,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      yoloModelVersion: yoloModelVersion ?? this.yoloModelVersion,
      aiServerEndpoint: aiServerEndpoint ?? this.aiServerEndpoint,
      isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
    );
  }

  /// Chuyển đổi Model sang Map JSON tương thích với bảng 'admin_system_config' trong Supabase (PostgreSQL)
  Map<String, dynamic> toMap() {
    return {
      'global_sensitivity_mode': globalSensitivityMode.name,
      'is_emergency_115_alert_enabled': isEmergency115AlertEnabled,
      'is_auto_guide_enabled': isAutoGuideEnabled,
      'emergency_phone': emergencyPhone,
      'yolo_model_version': yoloModelVersion,
      'ai_server_endpoint': aiServerEndpoint,
      'is_maintenance_mode': isMaintenanceMode,
    };
  }

  /// Khởi tạo Model từ dữ liệu truy vấn Supabase (hỗ trợ cả snake_case và camelCase)
  factory AdminSystemConfigModel.fromMap(Map<String, dynamic> map) {
    final rawSensitivity = map['global_sensitivity_mode'] as String? ?? map['globalSensitivityMode'] as String?;
    AiSensitivityMode sensitivity = AiSensitivityMode.balanced;
    if (rawSensitivity != null) {
      for (final sm in AiSensitivityMode.values) {
        if (sm.name.toLowerCase() == rawSensitivity.toLowerCase()) {
          sensitivity = sm;
          break;
        }
      }
    }

    return AdminSystemConfigModel(
      globalSensitivityMode: sensitivity,
      isEmergency115AlertEnabled: map['is_emergency_115_alert_enabled'] as bool? ??
          map['isEmergency115AlertEnabled'] as bool? ??
          true,
      isAutoGuideEnabled: map['is_auto_guide_enabled'] as bool? ??
          map['isAutoGuideEnabled'] as bool? ??
          true,
      emergencyPhone: map['emergency_phone'] as String? ??
          map['emergencyPhone'] as String? ??
          '115',
      yoloModelVersion: map['yolo_model_version'] as String? ??
          map['yoloModelVersion'] as String? ??
          'YOLOv8 Wound Detection (best.pt)',
      aiServerEndpoint: map['ai_server_endpoint'] as String? ??
          map['aiServerEndpoint'] as String? ??
          'http://127.0.0.1:8000',
      isMaintenanceMode: map['is_maintenance_mode'] as bool? ??
          map['isMaintenanceMode'] as bool? ??
          false,
    );
  }
}
