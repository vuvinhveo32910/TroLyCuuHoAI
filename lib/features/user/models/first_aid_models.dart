import 'package:flutter/material.dart';
import '../../../core/rule_engine/rule_models.dart';

export '../../../core/rule_engine/rule_models.dart';

/// Mô hình dữ liệu cho từng bước trong danh sách "Các bước sơ cứu" (Màn hình 4)
class FirstAidStepModel {
  final int stepNumber;
  final String id;
  final String title;
  final String description;
  final IconData fallbackIcon;

  const FirstAidStepModel({
    required this.stepNumber,
    required this.id,
    required this.title,
    required this.description,
    required this.fallbackIcon,
  });
}

/// Mô hình dữ liệu cho toàn bộ màn hình "Hướng dẫn sơ cứu (Người dùng)" (Màn hình 4)
class FirstAidGuideModel {
  final String topicId;
  final String screenTitle;
  final String statusBoxTitle;
  final String severityText;
  final String safetyNoteText;
  final String stepsSectionTitle;
  final List<FirstAidStepModel> steps;
  final String redWarningTitle;
  final List<String> redWarningBullets;
  final String backButtonLabel;

  // Dữ liệu từ Rule Engine và nguồn y khoa chuẩn
  final RuleEvaluationResult? ruleResult;
  final List<MedicalSourceLink> sourceLinks;
  final List<String> contraindications; // Những điều TUYỆT ĐỐI TRÁNH

  const FirstAidGuideModel({
    required this.topicId,
    required this.screenTitle,
    required this.statusBoxTitle,
    required this.severityText,
    required this.safetyNoteText,
    required this.stepsSectionTitle,
    required this.steps,
    required this.redWarningTitle,
    required this.redWarningBullets,
    required this.backButtonLabel,
    this.ruleResult,
    this.sourceLinks = const [],
    this.contraindications = const [],
  });

  FirstAidGuideModel copyWith({
    String? topicId,
    String? screenTitle,
    String? statusBoxTitle,
    String? severityText,
    String? safetyNoteText,
    String? stepsSectionTitle,
    List<FirstAidStepModel>? steps,
    String? redWarningTitle,
    List<String>? redWarningBullets,
    String? backButtonLabel,
    RuleEvaluationResult? ruleResult,
    List<MedicalSourceLink>? sourceLinks,
    List<String>? contraindications,
  }) {
    return FirstAidGuideModel(
      topicId: topicId ?? this.topicId,
      screenTitle: screenTitle ?? this.screenTitle,
      statusBoxTitle: statusBoxTitle ?? this.statusBoxTitle,
      severityText: severityText ?? this.severityText,
      safetyNoteText: safetyNoteText ?? this.safetyNoteText,
      stepsSectionTitle: stepsSectionTitle ?? this.stepsSectionTitle,
      steps: steps ?? this.steps,
      redWarningTitle: redWarningTitle ?? this.redWarningTitle,
      redWarningBullets: redWarningBullets ?? this.redWarningBullets,
      backButtonLabel: backButtonLabel ?? this.backButtonLabel,
      ruleResult: ruleResult ?? this.ruleResult,
      sourceLinks: sourceLinks ?? this.sourceLinks,
      contraindications: contraindications ?? this.contraindications,
    );
  }
}
