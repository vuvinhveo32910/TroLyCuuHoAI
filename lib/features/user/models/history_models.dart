import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Mô hình dữ liệu cho từng bản ghi trong Lịch sử phân tích quét vết thương
/// Đồng bộ trực tiếp với bảng 'analysis_history' trên Supabase PostgreSQL
class AnalysisHistoryItemModel {
  final String id;
  final String? username;
  final String injuryType;
  final int? confidencePercent;
  final String severityLevel; // 'mild' (nhẹ), 'moderate' (vừa), 'severe' (nặng)
  final String locationLabel;
  final String timestamp;
  final DateTime dateTime;
  final String? imageSourceName;
  final String? relatedTopicId;
  final List<String> symptoms;
  final int painLevel;
  final String? firstAidSummary;
  final Color baseSkinColor;
  final Color woundAccentColor;
  final Uint8List? rawImageBytes;

  const AnalysisHistoryItemModel({
    required this.id,
    this.username,
    required this.injuryType,
    this.confidencePercent,
    this.severityLevel = 'moderate',
    required this.locationLabel,
    required this.timestamp,
    required this.dateTime,
    this.imageSourceName,
    this.relatedTopicId,
    this.symptoms = const [],
    this.painLevel = 0,
    this.firstAidSummary,
    this.baseSkinColor = const Color(0xFFE8BEAC),
    this.woundAccentColor = const Color(0xFFD9383A),
    this.rawImageBytes,
  });

  /// Hiển thị tiêu đề kèm phần trăm độ tin cậy (Ví dụ: "Trầy xước (82%)")
  String get displayTitle => confidencePercent != null
      ? '$injuryType ($confidencePercent%)'
      : injuryType;

  /// Hiển thị nhãn mức độ nghiêm trọng bằng tiếng Việt
  String get severityLabelVi {
    switch (severityLevel.toLowerCase()) {
      case 'severe':
      case 'nang':
      case 'nặng':
        return 'Nghiêm trọng';
      case 'moderate':
      case 'vua':
      case 'vừa':
        return 'Trung bình';
      case 'mild':
      case 'nhe':
      case 'nhẹ':
      default:
        return 'Nhẹ';
    }
  }

  /// Màu sắc đại diện cho mức độ nghiêm trọng
  Color get severityColor {
    switch (severityLevel.toLowerCase()) {
      case 'severe':
      case 'nang':
      case 'nặng':
        return const Color(0xFFDC2626); // Đỏ
      case 'moderate':
      case 'vua':
      case 'vừa':
        return const Color(0xFFEA580C); // Cam
      case 'mild':
      case 'nhe':
      case 'nhẹ':
      default:
        return const Color(0xFF16A34A); // Xanh lá
    }
  }

  AnalysisHistoryItemModel copyWith({
    String? id,
    String? username,
    String? injuryType,
    int? confidencePercent,
    String? severityLevel,
    String? locationLabel,
    String? timestamp,
    DateTime? dateTime,
    String? imageSourceName,
    String? relatedTopicId,
    List<String>? symptoms,
    int? painLevel,
    String? firstAidSummary,
    Color? baseSkinColor,
    Color? woundAccentColor,
    Uint8List? rawImageBytes,
  }) {
    return AnalysisHistoryItemModel(
      id: id ?? this.id,
      username: username ?? this.username,
      injuryType: injuryType ?? this.injuryType,
      confidencePercent: confidencePercent ?? this.confidencePercent,
      severityLevel: severityLevel ?? this.severityLevel,
      locationLabel: locationLabel ?? this.locationLabel,
      timestamp: timestamp ?? this.timestamp,
      dateTime: dateTime ?? this.dateTime,
      imageSourceName: imageSourceName ?? this.imageSourceName,
      relatedTopicId: relatedTopicId ?? this.relatedTopicId,
      symptoms: symptoms ?? this.symptoms,
      painLevel: painLevel ?? this.painLevel,
      firstAidSummary: firstAidSummary ?? this.firstAidSummary,
      baseSkinColor: baseSkinColor ?? this.baseSkinColor,
      woundAccentColor: woundAccentColor ?? this.woundAccentColor,
      rawImageBytes: rawImageBytes ?? this.rawImageBytes,
    );
  }

  /// Chuyển đổi Model sang Map JSON tương thích với bảng 'analysis_history' trong Supabase (PostgreSQL)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'injury_type_id': relatedTopicId ?? 'abrasion',
      'injury_type_name': injuryType,
      'confidence_score': (confidencePercent ?? 80).toDouble(),
      'severity_level': severityLevel,
      'image_url': imageSourceName,
      'symptoms': symptoms,
      'pain_level': painLevel,
      'first_aid_summary': firstAidSummary,
      'created_at': dateTime.toIso8601String(),
    };
  }

  /// Khởi tạo Model từ dữ liệu truy vấn bảng Supabase (hỗ trợ cả snake_case và camelCase)
  factory AnalysisHistoryItemModel.fromMap(Map<String, dynamic> map) {
    final dateRaw = map['created_at'] as String? ??
        map['dateTime'] as String? ??
        map['date_time'] as String?;
    final parsedDate = dateRaw != null
        ? (DateTime.tryParse(dateRaw) ?? DateTime.now())
        : DateTime.now();

    final confScore = (map['confidence_score'] as num?)?.toDouble() ??
        (map['confidence_percent'] as num?)?.toDouble() ??
        (map['confidencePercent'] as num?)?.toDouble();

    List<String> parsedSymptoms = [];
    if (map['symptoms'] is List) {
      parsedSymptoms = (map['symptoms'] as List).map((e) => e.toString()).toList();
    }

    return AnalysisHistoryItemModel(
      id: map['id']?.toString() ?? '',
      username: map['username'] as String?,
      injuryType: map['injury_type_name'] as String? ??
          map['injury_type'] as String? ??
          map['injuryType'] as String? ??
          'Chưa xác định',
      confidencePercent: confScore?.round(),
      severityLevel: map['severity_level'] as String? ?? 'moderate',
      locationLabel: map['location_label'] as String? ??
          map['locationLabel'] as String? ??
          '-',
      timestamp: map['timestamp'] as String? ??
          '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')} ${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}',
      dateTime: parsedDate,
      imageSourceName: map['image_url'] as String? ??
          map['image_source_name'] as String? ??
          map['imageSourceName'] as String?,
      relatedTopicId: map['injury_type_id'] as String? ??
          map['related_topic_id'] as String? ??
          map['relatedTopicId'] as String?,
      symptoms: parsedSymptoms,
      painLevel: (map['pain_level'] as num?)?.toInt() ?? 0,
      firstAidSummary: map['first_aid_summary'] as String?,
      baseSkinColor: const Color(0xFFE8BEAC),
      woundAccentColor: const Color(0xFFD9383A),
      rawImageBytes: null,
    );
  }
}
