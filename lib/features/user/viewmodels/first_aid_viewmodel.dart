import 'package:flutter/material.dart';

import '../../../core/rule_engine/rule_engine_service.dart';
import '../models/first_aid_models.dart';
import 'user_navigation_viewmodel.dart';

mixin HuongDanSoCuuViewModel on DieuHuongCoSoViewModel {
  // Instance của Rule Engine
  final RuleEngineService _ruleEngine = RuleEngineService();

  // Ngữ cảnh tổn thương hiện tại để đưa vào Rule Engine
  InjuryContext _injuryContext = const InjuryContext(
    injuryTypeId: 'abrasion',
    injuryTypeName: 'Trầy xước',
  );
  InjuryContext get injuryContext => _injuryContext;

  // Kết quả đánh giá mới nhất từ Rule Engine
  RuleEvaluationResult? _currentRuleResult;
  RuleEvaluationResult? get currentRuleResult => _currentRuleResult;

  // Khởi tạo ngữ cảnh khi người dùng xem bài sơ cứu
  void updateInjuryContext({
    required String topicId,
    String? injuryTypeName,
    String? locationId,
    int? confidencePercent,
    PainLevel? painLevel,
    List<String>? secondaryInjuryTypeIds,
    List<String>? secondaryInjuryTypeNames,
  }) {
    _injuryContext = _injuryContext.copyWith(
      injuryTypeId: topicId,
      injuryTypeName: injuryTypeName ?? getTopicDisplayName(topicId),
      locationId: locationId,
      confidencePercent: confidencePercent,
      painLevel: painLevel,
      secondaryInjuryTypeIds: secondaryInjuryTypeIds,
      secondaryInjuryTypeNames: secondaryInjuryTypeNames,
    );
    _reEvaluateRuleEngine();
  }

  // Bật/tắt các dấu hiệu cảnh báo nhanh từ người dùng và mức độ đau
  void toggleWarningSymptom({
    String? injuryTypeId,
    String? injuryTypeName,
    bool? isBleedingHeavy,
    bool? hasDeepWoundOrForeignBody,
    bool? isLargeAreaBurnOrChemical,
    bool? isSeverePainOrFractureSuspected,
    bool? hasSignsOfInfection,
    bool? isChildOrElderly,
    PainLevel? painLevel,
    List<String>? secondaryInjuryTypeIds,
    List<String>? secondaryInjuryTypeNames,
  }) {
    _injuryContext = _injuryContext.copyWith(
      injuryTypeId: injuryTypeId ?? _injuryContext.injuryTypeId,
      injuryTypeName: injuryTypeName ?? _injuryContext.injuryTypeName,
      isBleedingHeavy: isBleedingHeavy ?? _injuryContext.isBleedingHeavy,
      hasDeepWoundOrForeignBody: hasDeepWoundOrForeignBody ??
          _injuryContext.hasDeepWoundOrForeignBody,
      isLargeAreaBurnOrChemical: isLargeAreaBurnOrChemical ??
          _injuryContext.isLargeAreaBurnOrChemical,
      isSeverePainOrFractureSuspected: isSeverePainOrFractureSuspected ??
          _injuryContext.isSeverePainOrFractureSuspected,
      hasSignsOfInfection:
          hasSignsOfInfection ?? _injuryContext.hasSignsOfInfection,
      isChildOrElderly: isChildOrElderly ?? _injuryContext.isChildOrElderly,
      painLevel: painLevel ?? _injuryContext.painLevel,
      secondaryInjuryTypeIds:
          secondaryInjuryTypeIds ?? _injuryContext.secondaryInjuryTypeIds,
      secondaryInjuryTypeNames:
          secondaryInjuryTypeNames ?? _injuryContext.secondaryInjuryTypeNames,
    );
    _reEvaluateRuleEngine();
  }

  // Đặt lại các dấu hiệu cảnh báo về mặc định
  void resetWarningSymptoms() {
    _injuryContext = InjuryContext(
      injuryTypeId: selectedGuideTopicId,
      injuryTypeName: getTopicDisplayName(selectedGuideTopicId),
    );
    _reEvaluateRuleEngine();
  }

  // Kích hoạt Rule Engine đánh giá lại kèm thông tin sức khỏe người dùng (nếu có)
  void _reEvaluateRuleEngine() {
    final user = currentUser;
    final contextWithUser = _injuryContext.copyWith(
      medicalConditions: user?.medicalConditions ?? const [],
      allergies: user?.allergies ?? const [],
      userBloodType: user?.bloodType,
      userRhFactor: user?.rhFactor,
    );
    _currentRuleResult = _ruleEngine.evaluate(contextWithUser);
    notifyListeners();
  }

  String getTopicDisplayName(String topicId) {
    switch (topicId) {
      case 'abrasion':
        return 'Trầy xước ngoài da';
      case 'cut_laceration':
        return 'Vết cắt / rách da';
      case 'burn':
        return 'Bỏng nhiệt ngoài da';
      case 'bruise':
        return 'Bầm tím phần mềm';
      case 'other_wounds':
        return 'Vết thương khác & Dị vật';
      default:
        return 'Tổn thương ngoài da';
    }
  }

  // Từ điển dữ liệu Hướng dẫn sơ cứu nền tảng (Knowledge Base)
  @override
  final Map<String, FirstAidGuideModel> firstAidGuidesByTopic = {
    'abrasion': FirstAidGuideModel(
      topicId: 'abrasion',
      screenTitle: 'Hướng dẫn sơ cứu – Trầy xước',
      statusBoxTitle: 'Tình trạng tổn thương',
      severityText: 'Trầy xước nhẹ ngoài da',
      safetyNoteText: 'Không có dấu hiệu tổn thương sâu',
      stepsSectionTitle: 'Các bước sơ cứu chuẩn y tế',
      steps: const [
        FirstAidStepModel(
          stepNumber: 1,
          id: 'wash_hands',
          title: 'Rửa tay sạch bằng xà phòng',
          description:
              'Rửa tay dưới vòi nước chảy ít nhất 20 giây để tránh đưa vi khuẩn vào vết trầy xước.',
          fallbackIcon: Icons.clean_hands_outlined,
        ),
        FirstAidStepModel(
          stepNumber: 2,
          id: 'clean_wound',
          title: 'Làm sạch vết thương',
          description:
              'Dùng nước muối sinh lý 0.9% hoặc nước sạch rửa trôi đất cát, dị vật bám trên bề mặt.',
          fallbackIcon: Icons.water_drop_outlined,
        ),
        FirstAidStepModel(
          stepNumber: 3,
          id: 'antiseptic',
          title: 'Sát khuẩn vết thương',
          description:
              'Dùng dung dịch sát khuẩn povidone-iodine 10% thấm nhẹ xung quanh mép vết thương.',
          fallbackIcon: Icons.medication_liquid_outlined,
        ),
        FirstAidStepModel(
          stepNumber: 4,
          id: 'bandage_wound',
          title: 'Bảo vệ vết thương',
          description:
              'Dán băng dán cá nhân thoáng khí hoặc để hở thoáng nếu vết trầy đã khô và sạch.',
          fallbackIcon: Icons.healing_outlined,
        ),
      ],
      redWarningTitle: 'Khi nào cần đến cơ sở y tế?',
      redWarningBullets: const [
        'Vết trầy xước sâu, dính nhiều đất cát bùn bẩn khó rửa sạch (nguy cơ uốn ván).',
        'Có dấu hiệu nhiễm trùng: Vết thương sưng mọng đỏ, rỉ dịch mủ, sốt hoặc đau tăng dần.',
        'Vết thương không có dấu hiệu lành sau 7 ngày.',
      ],
      backButtonLabel: 'Quay lại phân tích ảnh',
      contraindications: const [
        'Không dùng cồn đỏ hoặc cồn 90 độ đổ trực tiếp vào miệng vết thương hở.',
        'Không bôi mỡ kháng sinh hoặc thuốc lạ chưa có chỉ định.',
      ],
      sourceLinks: RuleEngineService.standardMedicalSources,
    ),
    'cut_laceration': FirstAidGuideModel(
      topicId: 'cut_laceration',
      screenTitle: 'Hướng dẫn sơ cứu – Vết cắt / Vết rách',
      statusBoxTitle: 'Tình trạng tổn thương',
      severityText: 'Vết cắt / rách hở da',
      safetyNoteText: 'Ưu tiên cầm máu và phòng ngừa nhiễm trùng',
      stepsSectionTitle: 'Các bước sơ cứu chuẩn y tế',
      steps: const [
        FirstAidStepModel(
          stepNumber: 1,
          id: 'wash_hands',
          title: 'Cầm máu trực tiếp',
          description:
              'Dùng miếng gạc vô trùng hoặc khăn sạch ấn ép trực tiếp lên vết cắt liên tục từ 5 - 10 phút.',
          fallbackIcon: Icons.clean_hands_outlined,
        ),
        FirstAidStepModel(
          stepNumber: 2,
          id: 'clean_wound',
          title: 'Vệ sinh nhẹ nhàng',
          description:
              'Sau khi máu đã cầm, rửa nhẹ vết thương bằng nước muối sinh lý.',
          fallbackIcon: Icons.water_drop_outlined,
        ),
        FirstAidStepModel(
          stepNumber: 3,
          id: 'antiseptic',
          title: 'Sát trùng mép vết thương',
          description:
              'Thoa dung dịch sát trùng Povidone-iodine nhẹ nhàng từ trong ra ngoài.',
          fallbackIcon: Icons.medication_liquid_outlined,
        ),
        FirstAidStepModel(
          stepNumber: 4,
          id: 'bandage_wound',
          title: 'Băng ép bảo vệ',
          description:
              'Kéo sát hai mép vết cắt lại với nhau và dùng băng dán hoặc băng gạc cố định chắc chắn.',
          fallbackIcon: Icons.healing_outlined,
        ),
      ],
      redWarningTitle: 'Khi nào cần đi khám ngay?',
      redWarningBullets: const [
        'Máu chảy không ngừng sau 15 phút ấn ép liên tục hoặc máu chảy thành tia.',
        'Vết cắt sâu hơn 0.5cm, hở miệng rộng, nhìn thấy lớp mỡ vàng hoặc gân cơ (cần khâu thẩm mỹ).',
        'Vết cắt do dao kéo rỉ sét, thủy tinh vỡ hoặc vật bẩn (cần tiêm phòng uốn ván SAT).',
        'Vết thương ở mặt, khớp tay chân hoặc gây mất cảm giác vùng đầu chi.',
      ],
      backButtonLabel: 'Quay lại phân tích ảnh',
      contraindications: const [
        'Tuyệt đối không đắp thuốc lá, bột cà phê, tro than lên vết thương.',
        'Không tự ý gỡ lớp gạc đầu tiên nếu máu đang thấm qua (hãy đè thêm lớp gạc mới lên trên).',
      ],
      sourceLinks: RuleEngineService.standardMedicalSources,
    ),
    'burn': FirstAidGuideModel(
      topicId: 'burn',
      screenTitle: 'Hướng dẫn sơ cứu – Bỏng nhiệt',
      statusBoxTitle: 'Tình trạng tổn thương',
      severityText: 'Bỏng ngoài da',
      safetyNoteText: 'Cần hạ nhiệt khẩn cấp trong 20 phút đầu',
      stepsSectionTitle: 'Các bước sơ cứu chuẩn y tế',
      steps: const [
        FirstAidStepModel(
          stepNumber: 1,
          id: 'clean_wound',
          title: 'Làm mát tức thì dưới nước sạch',
          description:
              'Xả nước sạch mát nhẹ nhàng (15 - 25°C) lên vùng bỏng liên tục trong 15 - 20 phút.',
          fallbackIcon: Icons.water_drop_outlined,
        ),
        FirstAidStepModel(
          stepNumber: 2,
          id: 'wash_hands',
          title: 'Cởi bỏ đồ trang sức & Quần áo chèn ép',
          description:
              'Nhẹ nhàng tháo nhẫn, đồng hồ, vòng tay trước khi vùng bỏng bị sưng phù nề.',
          fallbackIcon: Icons.clean_hands_outlined,
        ),
        FirstAidStepModel(
          stepNumber: 3,
          id: 'antiseptic',
          title: 'Giữ nguyên bọng nước',
          description:
              'Không chọc vỡ các nốt phồng rộp. Lớp da phồng là màng bảo vệ vô khuẩn tự nhiên tốt nhất.',
          fallbackIcon: Icons.medication_liquid_outlined,
        ),
        FirstAidStepModel(
          stepNumber: 4,
          id: 'bandage_wound',
          title: 'Che phủ bằng gạc vô trùng',
          description:
              'Đặt một lớp gạc vô trùng hoặc màng bọc thực phẩm sạch che nhẹ lên vết bỏng để tránh nhiễm khuẩn.',
          fallbackIcon: Icons.healing_outlined,
        ),
      ],
      redWarningTitle: 'Khi nào cần đi khám ngay?',
      redWarningBullets: const [
        'Vết bỏng lớn hơn kích thước lòng bàn tay nạn nhân.',
        'Bỏng ở các vị trí nguy hiểm: Mặt, mắt, cổ, bàn tay, bàn chân hoặc vùng sinh dục.',
        'Bỏng do điện giật hoặc hóa chất công nghiệp/axit/bazơ.',
        'Vết bỏng màu trắng bệch, xám tro, cháy đen hoặc mất hoàn toàn cảm giác đau (bỏng sâu độ 3).',
      ],
      backButtonLabel: 'Quay lại phân tích ảnh',
      contraindications: const [
        'TUYỆT ĐỐI KHÔNG chườm đá lạnh trực tiếp lên vết bỏng.',
        'TUYỆT ĐỐI KHÔNG bôi kem đánh răng, mỡ trăn, nước mắm hay trứng gà.',
        'TUYỆT ĐỐI KHÔNG bóc lớp quần áo đang dính chặt vào vết bỏng.',
      ],
      sourceLinks: RuleEngineService.standardMedicalSources,
    ),
    'bruise': FirstAidGuideModel(
      topicId: 'bruise',
      screenTitle: 'Hướng dẫn sơ cứu – Bầm tím phần mềm',
      statusBoxTitle: 'Tình trạng tổn thương',
      severityText: 'Tụ máu dưới da do va đập',
      safetyNoteText: 'Áp dụng nguyên tắc R.I.C.E để giảm sưng đau',
      stepsSectionTitle: 'Các bước sơ cứu chuẩn y tế',
      steps: const [
        FirstAidStepModel(
          stepNumber: 1,
          id: 'clean_wound',
          title: 'Chườm lạnh sớm (Ice)',
          description:
              'Bọc đá viên trong khăn sạch và chườm lên vùng bầm 15 phút, lặp lại sau mỗi 2 - 3 giờ.',
          fallbackIcon: Icons.water_drop_outlined,
        ),
        FirstAidStepModel(
          stepNumber: 2,
          id: 'wash_hands',
          title: 'Nghỉ ngơi vùng chi tổn thương (Rest)',
          description:
              'Hạn chế cử động mạnh hoặc tiếp tục vận động thể thao để tránh xuất huyết thêm.',
          fallbackIcon: Icons.clean_hands_outlined,
        ),
        FirstAidStepModel(
          stepNumber: 3,
          id: 'antiseptic',
          title: 'Kê cao vùng bị thương (Elevation)',
          description:
              'Nếu bầm ở chân hoặc tay, kê cao hơn tim để máu và dịch hồi lưu tốt hơn, giảm phù nề.',
          fallbackIcon: Icons.medication_liquid_outlined,
        ),
        FirstAidStepModel(
          stepNumber: 4,
          id: 'bandage_wound',
          title: 'Chườm ấm sau 48 giờ',
          description:
              'Sau 48 giờ khi máu đã ngừng chảy ngầm, có thể chườm ấm nhẹ để tan nhanh vết bầm.',
          fallbackIcon: Icons.healing_outlined,
        ),
      ],
      redWarningTitle: 'Khi nào cần đi khám ngay?',
      redWarningBullets: const [
        'Đau nhói dữ dội, khớp bị biến dạng hoặc không thể cử động (nghi ngờ gãy xương/trật khớp).',
        'Vết bầm ở vùng đầu kèm theo đau đầu, nôn ói, chóng mặt hoặc lơ mơ.',
        'Vết bầm sưng to nhanh và cảm giác căng tức, mạch đập mạnh.',
      ],
      backButtonLabel: 'Quay lại phân tích ảnh',
      contraindications: const [
        'Không xoa bóp dầu nóng, cao dán hoặc rượu thuốc trong 48 giờ đầu tiên.',
        'Không chườm nóng ngay sau khi va đập.',
      ],
      sourceLinks: RuleEngineService.standardMedicalSources,
    ),
    'other_wounds': FirstAidGuideModel(
      topicId: 'other_wounds',
      screenTitle: 'Hướng dẫn sơ cứu – Vết thương khác & Dị vật',
      statusBoxTitle: 'Tình trạng tổn thương',
      severityText: 'Vết thương hở / Có dị vật cắm sâu',
      safetyNoteText: 'Cần tuân thủ quy tắc vô khuẩn và bất động dị vật',
      stepsSectionTitle: 'Quy trình xử trí chuẩn y tế',
      steps: const [
        FirstAidStepModel(
          stepNumber: 1,
          id: 'wash_hands',
          title: 'Vệ sinh tay và giữ bình tĩnh',
          description:
              'Rửa tay sạch bằng xà phòng hoặc dung dịch sát khuẩn trước khi tiếp xúc với vết thương.',
          fallbackIcon: Icons.clean_hands_outlined,
        ),
        FirstAidStepModel(
          stepNumber: 2,
          id: 'foreign_body',
          title: 'Bất động dị vật (Nếu có)',
          description:
              'Tuyệt đối KHÔNG rút dị vật cắm sâu (mảnh kính, kim loại, que nhọn). Dùng gạc hoặc khăn cuộn chèn hai bên để cố định.',
          fallbackIcon: Icons.warning_amber_rounded,
        ),
        FirstAidStepModel(
          stepNumber: 3,
          id: 'bandage_wound',
          title: 'Băng che phủ vô trùng',
          description:
              'Đặt gạc vô trùng che phủ nhẹ nhàng vùng tổn thương, băng nhẹ giữ gạc không chèn ép trực tiếp lên dị vật.',
          fallbackIcon: Icons.healing_outlined,
        ),
        FirstAidStepModel(
          stepNumber: 4,
          id: 'medical_transfer',
          title: 'Chuyển đến cơ sở y tế',
          description:
              'Nhanh chóng đưa nạn nhân đến bệnh viện để được bác sĩ xử trí chuyên khoa và tiêm phòng uốn ván (SAT).',
          fallbackIcon: Icons.local_hospital_outlined,
        ),
      ],
      redWarningTitle: 'Dấu hiệu báo động đỏ (Cần đến viện cấp cứu ngay):',
      redWarningBullets: const [
        'Dị vật cắm vào vùng mắt, cổ, ngực, bụng hoặc mạch máu lớn.',
        'Chảy máu ồ ạt, phun thành tia hoặc không cầm sau 10 - 15 phút băng ép.',
        'Nạn nhân lơ mơ, tụt huyết áp, vã mồ hôi lạnh hoặc khó thở.',
      ],
      backButtonLabel: 'Quay lại',
      contraindications: const [
        'TUYỆT ĐỐI KHÔNG tự ý rút dị vật cắm sâu ra khỏi cơ thể tại nhà.',
        'Không đắp lá cây, thuốc bột hay hóa chất chưa được chỉ định lên vết thương.',
      ],
      sourceLinks: RuleEngineService.standardMedicalSources,
    ),
  };

  /// Lấy dữ liệu Hướng dẫn sơ cứu hiện tại kết hợp kết quả từ Rule Engine
  FirstAidGuideModel get firstAidGuide {
    final baseGuide = firstAidGuidesByTopic[selectedGuideTopicId] ??
        firstAidGuidesByTopic['abrasion']!;

    _currentRuleResult ??= _ruleEngine.evaluate(_injuryContext);

    return baseGuide.copyWith(
      ruleResult: _currentRuleResult,
      sourceLinks: _ruleEngine.getSourceLinksForTopic(selectedGuideTopicId),
      contraindications: _currentRuleResult?.contraindications ??
          baseGuide.contraindications,
    );
  }

  void onViewFirstAidGuidePressed() {
    navigateToFirstAidGuide(topicId: 'abrasion');
  }

  void onBackToImageAnalysisPressed() {
    navigateBack();
  }
}
