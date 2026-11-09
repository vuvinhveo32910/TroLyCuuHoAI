import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Mô hình cấu hình hiển thị cho khu vực Tải lên hình ảnh phân tích (Màn hình 2)
class AiUploadSpecModel {
  final String screenTitle;
  final String dropzonePrefixText;
  final String dropzoneActionText;
  final String supportedFormatsText;
  final String selectButtonLabel;
  final String dividerText;
  final String cameraButtonLabel;
  final String noticeBoldText;
  final String noticeDetailText;

  const AiUploadSpecModel({
    required this.screenTitle,
    required this.dropzonePrefixText,
    required this.dropzoneActionText,
    required this.supportedFormatsText,
    required this.selectButtonLabel,
    required this.dividerText,
    required this.cameraButtonLabel,
    required this.noticeBoldText,
    required this.noticeDetailText,
  });
}

/// Mô hình dữ liệu cho tùy chọn trong mục "Chọn vị trí tổn thương" (Màn hình 3)
class InjuryLocationOptionModel {
  final String id;
  final String label;
  final IconData fallbackIcon;

  const InjuryLocationOptionModel({
    required this.id,
    required this.label,
    required this.fallbackIcon,
  });
}

/// Mô hình dữ liệu cho tùy chọn sửa đổi thủ công loại vết thương (Màn hình 3)
class ManualInjuryOptionModel {
  final String id; // 'tray_xuoc', 'vet_cat_rach', 'bong', 'bam_tim'
  final String label;
  final String topicId;
  final String severity;
  final IconData icon;
  final String description;

  const ManualInjuryOptionModel({
    required this.id,
    required this.label,
    required this.topicId,
    required this.severity,
    required this.icon,
    required this.description,
  });
}

/// Một tổn thương riêng biệt được YOLO phát hiện trên ảnh (hỗ trợ phát hiện 2-3 vết thương trên 1 ảnh)
class DetectedWoundItemModel {
  final String label; // Ví dụ: "Vết cắt / Vết rách", "Trầy xước"
  final String topicId; // "cut_laceration", "abrasion", "burn", "bruise"
  final int confidencePercent; // 82
  final String severity; // "Cần chú ý", "Nhẹ", "Quan trọng"
  final List<double> box; // [x1, y1, x2, y2]
  final String classId; // "vet_cat_rach", "tray_xuoc", "bong", "bam_tim"

  const DetectedWoundItemModel({
    required this.label,
    required this.topicId,
    required this.confidencePercent,
    required this.severity,
    required this.box,
    required this.classId,
  });

  factory DetectedWoundItemModel.fromJson(Map<String, dynamic> json) {
    return DetectedWoundItemModel(
      label:
          json['vn_label'] as String? ??
          json['injury_type'] as String? ??
          'Tổn thương da',
      topicId: json['topic_id'] as String? ?? 'abrasion',
      confidencePercent: (json['confidence_percent'] as num?)?.toInt() ?? 0,
      severity: json['severity'] as String? ?? 'Nhẹ',
      box: json['box'] != null && json['box'] is List
          ? (json['box'] as List).map((e) => (e as num).toDouble()).toList()
          : const [],
      classId: json['class_name_raw'] as String? ?? '',
    );
  }

  Color get tagColor {
    switch (topicId) {
      case 'cut_laceration':
        return const Color(0xFFDC2626); // Đỏ
      case 'burn':
        return const Color(0xFFEA580C); // Cam
      case 'bruise':
        return const Color(0xFF7C3AED); // Tím
      case 'abrasion':
      default:
        return const Color(0xFF0284C7); // Xanh dương
    }
  }
}

/// Mô hình dữ liệu Kết quả phân tích hình ảnh AI (Màn hình 3)
class AiAnalysisResultModel {
  final String bannerTitle;
  final String confidenceLabelPrefix;
  final int confidencePercent;
  final String injuryType;
  final String boundingBoxLabel;
  final String infoCardTitle;
  final String injuryTypeLabel;
  final String confidenceRowLabel;
  final String locationRowLabel;
  final String locationSectionTitle;
  final String bottomNoticeText;
  final String primaryActionLabel;
  final String? analyzedImageUrl;

  // Dữ liệu ảnh thực tế & Kết quả từ YOLO model
  final Uint8List? rawImageBytes;
  final String? imageFileName;
  final String detectedTopicId;
  final bool isDetected;
  final List<double>? boundingBox; // [x1, y1, x2, y2]
  final double? originalImageWidth;
  final double? originalImageHeight;
  final String? detectionMessage;
  final String? serverAnalysisId;

  // Danh sách TẤT CẢ các vết thương phát hiện trên ảnh (2-3 vết thương)
  final List<DetectedWoundItemModel> allDetections;

  // Trạng thái can thiệp thủ công & độ tương phản
  final bool isManualSelection;
  final double appliedContrast;

  const AiAnalysisResultModel({
    required this.bannerTitle,
    this.confidenceLabelPrefix = 'Độ tin cậy:',
    required this.confidencePercent,
    required this.injuryType,
    required this.boundingBoxLabel,
    this.infoCardTitle = 'Thông tin nhận diện AI',
    this.injuryTypeLabel = 'Loại tổn thương:',
    this.confidenceRowLabel = 'Độ tin cậy:',
    this.locationRowLabel = 'Vị trí:',
    this.locationSectionTitle = 'Chọn vị trí tổn thương',
    this.bottomNoticeText = 'Hệ thống đã phân tích tổn thương. Vui lòng chọn vị trí cụ thể để xem hướng dẫn sơ cứu phù hợp.',
    this.primaryActionLabel = 'Xem hướng dẫn sơ cứu',
    this.analyzedImageUrl,
    this.rawImageBytes,
    this.imageFileName,
    this.detectedTopicId = 'abrasion',
    this.isDetected = true,
    this.boundingBox,
    this.originalImageWidth,
    this.originalImageHeight,
    this.detectionMessage,
    this.serverAnalysisId,
    this.allDetections = const [],
    this.isManualSelection = false,
    this.appliedContrast = 1.0,
  });

  bool get hasMultipleInjuries => allDetections.length > 1;

  List<String> get allUniqueLabels =>
      allDetections.map((d) => d.label).toSet().toList();

  String get combinedInjurySummary {
    if (allDetections.isEmpty) return injuryType;
    if (allDetections.length == 1) {
      return '${allDetections.first.label} (${allDetections.first.confidencePercent}%)';
    }
    return allDetections
        .map((d) => '${d.label} (${d.confidencePercent}%)')
        .join(', ');
  }

  String get formattedConfidence =>
      isManualSelection ? '100% (Xác nhận thủ công)' : '$confidencePercent%';
  String get bannerConfidenceText => isManualSelection
      ? 'Xác nhận thủ công'
      : '$confidenceLabelPrefix $confidencePercent%';

  AiAnalysisResultModel copyWith({
    String? bannerTitle,
    String? confidenceLabelPrefix,
    int? confidencePercent,
    String? injuryType,
    String? boundingBoxLabel,
    String? infoCardTitle,
    String? injuryTypeLabel,
    String? confidenceRowLabel,
    String? locationRowLabel,
    String? locationSectionTitle,
    String? bottomNoticeText,
    String? primaryActionLabel,
    String? analyzedImageUrl,
    Uint8List? rawImageBytes,
    String? imageFileName,
    String? detectedTopicId,
    bool? isDetected,
    List<double>? boundingBox,
    double? originalImageWidth,
    double? originalImageHeight,
    String? detectionMessage,
    String? serverAnalysisId,
    List<DetectedWoundItemModel>? allDetections,
    bool? isManualSelection,
    double? appliedContrast,
  }) {
    return AiAnalysisResultModel(
      bannerTitle: bannerTitle ?? this.bannerTitle,
      confidenceLabelPrefix:
          confidenceLabelPrefix ?? this.confidenceLabelPrefix,
      confidencePercent: confidencePercent ?? this.confidencePercent,
      injuryType: injuryType ?? this.injuryType,
      boundingBoxLabel: boundingBoxLabel ?? this.boundingBoxLabel,
      infoCardTitle: infoCardTitle ?? this.infoCardTitle,
      injuryTypeLabel: injuryTypeLabel ?? this.injuryTypeLabel,
      confidenceRowLabel: confidenceRowLabel ?? this.confidenceRowLabel,
      locationRowLabel: locationRowLabel ?? this.locationRowLabel,
      locationSectionTitle: locationSectionTitle ?? this.locationSectionTitle,
      bottomNoticeText: bottomNoticeText ?? this.bottomNoticeText,
      primaryActionLabel: primaryActionLabel ?? this.primaryActionLabel,
      analyzedImageUrl: analyzedImageUrl ?? this.analyzedImageUrl,
      rawImageBytes: rawImageBytes ?? this.rawImageBytes,
      imageFileName: imageFileName ?? this.imageFileName,
      detectedTopicId: detectedTopicId ?? this.detectedTopicId,
      isDetected: isDetected ?? this.isDetected,
      boundingBox: boundingBox ?? this.boundingBox,
      originalImageWidth: originalImageWidth ?? this.originalImageWidth,
      originalImageHeight: originalImageHeight ?? this.originalImageHeight,
      detectionMessage: detectionMessage ?? this.detectionMessage,
      serverAnalysisId: serverAnalysisId ?? this.serverAnalysisId,
      allDetections: allDetections ?? this.allDetections,
      isManualSelection: isManualSelection ?? this.isManualSelection,
      appliedContrast: appliedContrast ?? this.appliedContrast,
    );
  }
}
