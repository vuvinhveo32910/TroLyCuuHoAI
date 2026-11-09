import 'package:flutter/material.dart';

/// Mức độ ưu tiên / tính chất nghiêm trọng của tổn thương do Rule Engine đánh giá
enum RuleSeverityLevel {
  normal, // Nhẹ - Có thể tự sơ cứu và theo dõi tại nhà
  warning, // Cần chú ý - Cần sơ cứu cẩn thận, theo dõi sát hoặc khám bác sĩ
  emergency, // Khẩn cấp / Nguy kịch - Cần đến ngay cơ sở y tế / bệnh viện cấp cứu
}

extension RuleSeverityLevelExt on RuleSeverityLevel {
  String get label {
    switch (this) {
      case RuleSeverityLevel.normal:
        return 'Nhẹ - Tự xử lý tại nhà';
      case RuleSeverityLevel.warning:
        return 'Cần chú ý - Theo dõi sát';
      case RuleSeverityLevel.emergency:
        return 'Khẩn cấp - Cần đến cơ sở y tế ngay';
    }
  }

  Color get color {
    switch (this) {
      case RuleSeverityLevel.normal:
        return const Color(0xFF16A34A); // Xanh lá
      case RuleSeverityLevel.warning:
        return const Color(0xFFD97706); // Vàng hổ phách
      case RuleSeverityLevel.emergency:
        return const Color(0xFFDC2626); // Đỏ khẩn cấp
    }
  }

  Color get backgroundColor {
    switch (this) {
      case RuleSeverityLevel.normal:
        return const Color(0xFFF0FDF4);
      case RuleSeverityLevel.warning:
        return const Color(0xFFFFFBEB);
      case RuleSeverityLevel.emergency:
        return const Color(0xFFFEF2F2);
    }
  }

  Color get borderColor {
    switch (this) {
      case RuleSeverityLevel.normal:
        return const Color(0xFFBBF7D0);
      case RuleSeverityLevel.warning:
        return const Color(0xFFFDE68A);
      case RuleSeverityLevel.emergency:
        return const Color(0xFFFECACA);
    }
  }

  IconData get icon {
    switch (this) {
      case RuleSeverityLevel.normal:
        return Icons.check_circle_outline_rounded;
      case RuleSeverityLevel.warning:
        return Icons.warning_amber_rounded;
      case RuleSeverityLevel.emergency:
        return Icons.emergency_rounded;
    }
  }
}

/// Mức độ cảm giác đau do người dùng cung cấp qua nút gạt 3 mức
enum PainLevel {
  none, // Không đau (0/10)
  mild, // Đau nhẹ (1-4/10)
  severe, // Đau nặng (7-10/10)
}

extension PainLevelExt on PainLevel {
  String get label {
    switch (this) {
      case PainLevel.none:
        return 'Không đau';
      case PainLevel.mild:
        return 'Đau nhẹ';
      case PainLevel.severe:
        return 'Đau nặng';
    }
  }

  String get description {
    switch (this) {
      case PainLevel.none:
        return 'Không có cảm giác đau rát rõ rệt hoặc tê nhẹ';
      case PainLevel.mild:
        return 'Đau rát nhẹ bề mặt, châm chích, vẫn cử động bình thường';
      case PainLevel.severe:
        return 'Đau nhức dữ dội, đau buốt theo nhịp mạch hoặc khó cử động';
    }
  }

  Color get color {
    switch (this) {
      case PainLevel.none:
        return const Color(0xFF10B981); // Xanh lá
      case PainLevel.mild:
        return const Color(0xFFF59E0B); // Vàng hổ phách
      case PainLevel.severe:
        return const Color(0xFFDC2626); // Đỏ khẩn cấp
    }
  }

  IconData get icon {
    switch (this) {
      case PainLevel.none:
        return Icons.sentiment_satisfied_alt_rounded;
      case PainLevel.mild:
        return Icons.sentiment_neutral_rounded;
      case PainLevel.severe:
        return Icons.sentiment_very_dissatisfied_rounded;
    }
  }
}

/// Nguồn trích xuất y khoa có link tham chiếu chi tiết
class MedicalSourceLink {
  final String id;
  final String title;
  final String organization; // 'Hội Chữ Thập Đỏ Việt Nam', 'Bộ Y Tế', 'WHO', 'Mayo Clinic'
  final String url;
  final String publishYear;
  final String targetTopicId; // 'all' hoặc 'abrasion', 'cut_laceration', 'burn', 'bruise', 'other_wounds'
  final bool isEnabled;

  const MedicalSourceLink({
    this.id = '',
    required this.title,
    required this.organization,
    required this.url,
    this.publishYear = '2025',
    this.targetTopicId = 'all',
    this.isEnabled = true,
  });

  MedicalSourceLink copyWith({
    String? id,
    String? title,
    String? organization,
    String? url,
    String? publishYear,
    String? targetTopicId,
    bool? isEnabled,
  }) {
    return MedicalSourceLink(
      id: id ?? this.id,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      url: url ?? this.url,
      publishYear: publishYear ?? this.publishYear,
      targetTopicId: targetTopicId ?? this.targetTopicId,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'organization': organization,
      'url': url,
      'publish_year': publishYear,
      'target_topic_id': targetTopicId,
      'is_enabled': isEnabled,
    };
  }

  factory MedicalSourceLink.fromMap(Map<String, dynamic> map) {
    return MedicalSourceLink(
      id: map['id']?.toString() ?? '',
      title: map['title'] as String? ?? '',
      organization: map['organization'] as String? ?? '',
      url: map['url'] as String? ?? '',
      publishYear: map['publish_year'] as String? ??
          map['publishYear'] as String? ??
          '2025',
      targetTopicId: map['target_topic_id'] as String? ??
          map['targetTopicId'] as String? ??
          'all',
      isEnabled: map['is_enabled'] as bool? ??
          map['isEnabled'] as bool? ??
          true,
    );
  }
}

/// Ngữ cảnh đánh giá tổn thương đưa vào Rule Engine
class InjuryContext {
  final String injuryTypeId; // 'abrasion', 'cut_laceration', 'burn', 'bruise', 'none'
  final String injuryTypeName;
  final String locationId; // 'head', 'arm', 'leg', 'back', 'other'
  final int confidencePercent;

  // Cảm giác đau (3 mức: Không đau, Đau nhẹ, Đau nặng)
  final PainLevel painLevel;

  // Danh sách các tổn thương phụ đi kèm khi ảnh phát hiện 2-3 vết thương khác nhau
  final List<String> secondaryInjuryTypeIds;
  final List<String> secondaryInjuryTypeNames;

  // Các dấu hiệu cảnh báo do người dùng cung cấp hoặc chọn trực tiếp
  final bool isBleedingHeavy; // Chảy máu nhiều / không cầm sau 10-15 phút
  final bool hasDeepWoundOrForeignBody; // Vết thương sâu, hở miệng lớn hoặc có dị vật đâm vào
  final bool isLargeAreaBurnOrChemical; // Bỏng diện rộng, bỏng bọng nước to hoặc do hóa chất / điện
  final bool isSeverePainOrFractureSuspected; // Đau nhức dữ dội, biến dạng khớp nghi ngờ gãy xương
  final bool hasSignsOfInfection; // Vết thương sưng mủ, sốt cao, đỏ tấy lan rộng
  final bool isChildOrElderly; // Đối tượng dễ tổn thương: trẻ nhỏ hoặc người già

  // Thông tin sức khỏe nền tảng cá nhân của người dùng (từ Hồ sơ cá nhân)
  final List<String> medicalConditions; // 'diabetes', 'hemophilia', 'cardiovascular'...
  final List<String> allergies; // 'alcohol', 'penicillin', 'iodine'...
  final String? userBloodType; // 'A', 'B', 'AB', 'O'
  final String? userRhFactor; // 'Rh+', 'Rh-'

  const InjuryContext({
    required this.injuryTypeId,
    required this.injuryTypeName,
    this.locationId = 'arm',
    this.confidencePercent = 100,
    this.painLevel = PainLevel.mild,
    this.secondaryInjuryTypeIds = const [],
    this.secondaryInjuryTypeNames = const [],
    this.isBleedingHeavy = false,
    this.hasDeepWoundOrForeignBody = false,
    this.isLargeAreaBurnOrChemical = false,
    this.isSeverePainOrFractureSuspected = false,
    this.hasSignsOfInfection = false,
    this.isChildOrElderly = false,
    this.medicalConditions = const [],
    this.allergies = const [],
    this.userBloodType,
    this.userRhFactor,
  });

  bool get hasMultipleInjuries => secondaryInjuryTypeIds.isNotEmpty;

  // Tiện ích kiểm tra bệnh nền & dị ứng
  bool get hasHemophilia => medicalConditions.contains('hemophilia');
  bool get hasDiabetes => medicalConditions.contains('diabetes');
  bool get hasCardiovascular => medicalConditions.contains('cardiovascular');
  bool get hasAlcoholAllergy => allergies.any((a) =>
      a.toLowerCase().contains('cồn') || a.toLowerCase().contains('alcohol'));
  bool get hasPenicillinAllergy => allergies.any((a) =>
      a.toLowerCase().contains('penicillin') ||
      a.toLowerCase().contains('kháng sinh'));
  bool get hasIodineAllergy => allergies.any((a) =>
      a.toLowerCase().contains('iodine') ||
      a.toLowerCase().contains('betadine') ||
      a.toLowerCase().contains('i-ốt'));

  InjuryContext copyWith({
    String? injuryTypeId,
    String? injuryTypeName,
    String? locationId,
    int? confidencePercent,
    PainLevel? painLevel,
    List<String>? secondaryInjuryTypeIds,
    List<String>? secondaryInjuryTypeNames,
    bool? isBleedingHeavy,
    bool? hasDeepWoundOrForeignBody,
    bool? isLargeAreaBurnOrChemical,
    bool? isSeverePainOrFractureSuspected,
    bool? hasSignsOfInfection,
    bool? isChildOrElderly,
    List<String>? medicalConditions,
    List<String>? allergies,
    String? userBloodType,
    String? userRhFactor,
  }) {
    return InjuryContext(
      injuryTypeId: injuryTypeId ?? this.injuryTypeId,
      injuryTypeName: injuryTypeName ?? this.injuryTypeName,
      locationId: locationId ?? this.locationId,
      confidencePercent: confidencePercent ?? this.confidencePercent,
      painLevel: painLevel ?? this.painLevel,
      secondaryInjuryTypeIds:
          secondaryInjuryTypeIds ?? this.secondaryInjuryTypeIds,
      secondaryInjuryTypeNames:
          secondaryInjuryTypeNames ?? this.secondaryInjuryTypeNames,
      isBleedingHeavy: isBleedingHeavy ?? this.isBleedingHeavy,
      hasDeepWoundOrForeignBody:
          hasDeepWoundOrForeignBody ?? this.hasDeepWoundOrForeignBody,
      isLargeAreaBurnOrChemical:
          isLargeAreaBurnOrChemical ?? this.isLargeAreaBurnOrChemical,
      isSeverePainOrFractureSuspected:
          isSeverePainOrFractureSuspected ?? this.isSeverePainOrFractureSuspected,
      hasSignsOfInfection: hasSignsOfInfection ?? this.hasSignsOfInfection,
      isChildOrElderly: isChildOrElderly ?? this.isChildOrElderly,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies ?? this.allergies,
      userBloodType: userBloodType ?? this.userBloodType,
      userRhFactor: userRhFactor ?? this.userRhFactor,
    );
  }
}

/// Một Quy tắc (Rule) trong Rule Engine sơ cứu
class FirstAidRule {
  final String id;
  final String code; // Ví dụ: 'RULE-BLEED-01'
  final String name;
  final String description;
  final RuleSeverityLevel severity;
  final String targetInjuryTypeId; // 'abrasion', 'cut_laceration', 'burn', 'bruise', 'all'
  final bool isEnabled;

  // Cờ điều kiện lâm sàng kích hoạt (Khớp 100% với giao diện quét ảnh & kết quả)
  final bool requireBleedingHeavy; // Khớp Checkbox: Vết thương đang chảy máu (chảy nhiều/liên tục)
  final bool requireForeignBody; // Khớp Checkbox: Dị vật cắm vào vết thương (kim loại, dằm, thủy tinh...)
  final bool requireInfection; // Khớp Checkbox: Vết thương chảy mủ / Sưng đỏ tấy
  final PainLevel? requiredPainLevel; // Khớp Nút gạt 3 mức đau: null = Bất kỳ, mild = Từ đau nhẹ, severe = Đau nặng
  final bool requireMultipleInjuries; // Khớp trường hợp ảnh phát hiện 2-3 vết thương cùng lúc (Đa tổn thương)
  final bool requireLargeBurnOrChemical; // Bỏng diện rộng / hóa chất / bọng nước lớn
  final bool requireSeverePainOrFracture; // Đau nhức dữ dội / nghi ngờ biến dạng

  // Liên kết phác đồ y khoa trong Knowledge Base
  final String? linkedKnowledgeTopicId;

  // Điều kiện kích hoạt luật (hàm logic)
  final bool Function(InjuryContext context) condition;

  // Các hướng dẫn hành động tương ứng khi luật kích hoạt
  final List<String> primaryActions;
  final List<String> contraindications; // Những điều TUYỆT ĐỐI KHÔNG ĐƯỢC LÀM
  final String emergencyRecommendation; // Khuyến nghị đi viện / Gọi 115

  const FirstAidRule({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.severity,
    this.targetInjuryTypeId = 'all',
    this.isEnabled = true,
    this.requireBleedingHeavy = false,
    this.requireForeignBody = false,
    this.requireInfection = false,
    this.requiredPainLevel,
    this.requireMultipleInjuries = false,
    this.requireLargeBurnOrChemical = false,
    this.requireSeverePainOrFracture = false,
    this.linkedKnowledgeTopicId,
    required this.condition,
    required this.primaryActions,
    required this.contraindications,
    required this.emergencyRecommendation,
  });

  /// Kiểm tra xem ngữ cảnh có khớp với quy tắc này hay không
  bool matches(InjuryContext context) {
    if (!isEnabled) return false;
    if (targetInjuryTypeId != 'all' &&
        targetInjuryTypeId != context.injuryTypeId) {
      return false;
    }

    final bool hasSpecificFlag = requireBleedingHeavy ||
        requireForeignBody ||
        requireInfection ||
        requireMultipleInjuries ||
        requiredPainLevel != null ||
        requireLargeBurnOrChemical ||
        requireSeverePainOrFracture;

    if (hasSpecificFlag) {
      // 1. Khớp 3 Checkbox quan sát lâm sàng giao diện
      if (requireBleedingHeavy && !context.isBleedingHeavy) return false;
      if (requireForeignBody && !context.hasDeepWoundOrForeignBody) return false;
      if (requireInfection && !context.hasSignsOfInfection) return false;

      // 2. Khớp điều kiện Mức độ đau
      if (requiredPainLevel != null) {
        if (requiredPainLevel == PainLevel.severe &&
            context.painLevel != PainLevel.severe) {
          return false;
        }
        if (requiredPainLevel == PainLevel.mild &&
            context.painLevel == PainLevel.none) {
          return false;
        }
      }

      // 3. Khớp điều kiện Đa tổn thương (2-3 vết thương cùng lúc)
      if (requireMultipleInjuries && !context.hasMultipleInjuries) {
        return false;
      }

      // Tương thích ngược các cờ bổ trợ cũ
      if (requireLargeBurnOrChemical && !context.isLargeAreaBurnOrChemical) {
        return false;
      }
      if (requireSeverePainOrFracture &&
          !context.isSeverePainOrFractureSuspected &&
          context.painLevel != PainLevel.severe) {
        return false;
      }
      return true;
    }

    return condition(context);
  }

  FirstAidRule copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    RuleSeverityLevel? severity,
    String? targetInjuryTypeId,
    bool? isEnabled,
    bool? requireBleedingHeavy,
    bool? requireForeignBody,
    bool? requireInfection,
    PainLevel? requiredPainLevel,
    bool? requireMultipleInjuries,
    bool? requireLargeBurnOrChemical,
    bool? requireSeverePainOrFracture,
    String? linkedKnowledgeTopicId,
    bool Function(InjuryContext context)? condition,
    List<String>? primaryActions,
    List<String>? contraindications,
    String? emergencyRecommendation,
  }) {
    return FirstAidRule(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      targetInjuryTypeId: targetInjuryTypeId ?? this.targetInjuryTypeId,
      isEnabled: isEnabled ?? this.isEnabled,
      requireBleedingHeavy: requireBleedingHeavy ?? this.requireBleedingHeavy,
      requireForeignBody: requireForeignBody ?? this.requireForeignBody,
      requireInfection: requireInfection ?? this.requireInfection,
      requiredPainLevel: requiredPainLevel ?? this.requiredPainLevel,
      requireMultipleInjuries:
          requireMultipleInjuries ?? this.requireMultipleInjuries,
      requireLargeBurnOrChemical:
          requireLargeBurnOrChemical ?? this.requireLargeBurnOrChemical,
      requireSeverePainOrFracture:
          requireSeverePainOrFracture ?? this.requireSeverePainOrFracture,
      linkedKnowledgeTopicId:
          linkedKnowledgeTopicId ?? this.linkedKnowledgeTopicId,
      condition: condition ?? this.condition,
      primaryActions: primaryActions ?? this.primaryActions,
      contraindications: contraindications ?? this.contraindications,
      emergencyRecommendation:
          emergencyRecommendation ?? this.emergencyRecommendation,
    );
  }
}

/// Kết quả đầu ra sau khi Rule Engine đánh giá ngữ cảnh tổn thương
class RuleEvaluationResult {
  final RuleSeverityLevel finalSeverity;
  final String summaryTitle;
  final String statusDescription;
  final List<FirstAidRule> triggeredRules;
  final List<String> priorityActions;
  final List<String> contraindications; // Việc cấm kỵ
  final List<String> warningSymptoms; // Dấu hiệu nguy hiểm cần đi viện
  final String emergencyHospitalAdvice;
  final List<MedicalSourceLink> sourceLinks;
  final bool shouldCallEmergency115;

  const RuleEvaluationResult({
    required this.finalSeverity,
    required this.summaryTitle,
    required this.statusDescription,
    required this.triggeredRules,
    required this.priorityActions,
    required this.contraindications,
    required this.warningSymptoms,
    required this.emergencyHospitalAdvice,
    required this.sourceLinks,
    this.shouldCallEmergency115 = false,
  });
}
