import '../../../core/feedback/ai_feedback_model.dart';
import '../../../core/feedback/ai_feedback_service.dart';
import '../../../core/gemini/gemini_config_model.dart';
import '../../../core/gemini/gemini_service.dart';
import '../../../core/rule_engine/rule_engine_service.dart';
import '../../../core/rule_engine/rule_models.dart';
import '../models/admin_management_models.dart';
import 'admin_navigation_viewmodel.dart';

mixin AdminManagementViewModel on DieuHuongQuanTriViewModel {
  final RuleEngineService _ruleEngineService = RuleEngineService();

  // ===========================================================================
  // 1. QUẢN LÝ KNOWLEDGE BASE (Kiến thức sơ cứu)
  // ===========================================================================
  final List<KnowledgeArticleModel> _knowledgeArticles = [
    const KnowledgeArticleModel(
      id: 'kb_1',
      title: 'Quy trình sơ cứu vết trầy xước ngoài da',
      categoryId: 'wound',
      categoryName: 'Vết thương',
      summary:
          'Quy trình 4 bước làm sạch, sát trùng và băng bó vết trầy xước nông, phòng tránh sẹo thâm và nhiễm trùng uốn ván.',
      targetInjuryTypeId: 'abrasion',
      targetInjuryTypeName: 'Trầy xước ngoài da',
      defaultSeverity: RuleSeverityLevel.normal,
      steps: [
        'Rửa sạch tay bằng xà phòng sát khuẩn',
        'Rửa trôi bụi đất bằng nước muối sinh lý 0.9%',
        'Sát khuẩn mép vết thương bằng Povidone-Iodine 10%',
        'Băng gạc thoáng hoặc dán băng cá nhân',
      ],
      warnings: [
        'Không dùng cồn 90 độ đổ trực tiếp vào miệng vết thương',
        'Đến cơ sở y tế nếu có dấu hiệu sưng mủ, sốt cao',
      ],
      contraindications: [
        'Không đắp lá cây, tro than hay thuốc lá lên vết rách',
      ],
      lastUpdated: '25/10/2025',
      isPublished: true,
      sourceOrganization: 'Hội Chữ Thập Đỏ Việt Nam',
      sourceUrl: 'https://redcross.org.vn/so-cap-cuu',
    ),
    const KnowledgeArticleModel(
      id: 'kb_2',
      title: 'Kỹ thuật cầm máu và băng ép vết cắt / vết rách',
      categoryId: 'wound',
      categoryName: 'Vết thương',
      summary:
          'Hướng dẫn cầm máu khẩn cấp bằng ấn ép trực tiếp, đánh giá độ sâu của vết rách và nhận diện tổn thương mạch máu gân cơ.',
      targetInjuryTypeId: 'cut_laceration',
      targetInjuryTypeName: 'Vết cắt / rách da',
      defaultSeverity: RuleSeverityLevel.warning,
      steps: [
        'Ấn ép trực tiếp bằng gạc vô trùng lên miệng vết cắt',
        'Nâng cao vùng chi tổn thương cao hơn vị trí tim',
        'Sát khuẩn xung quanh sau khi máu đã ngừng chảy',
        'Băng ép cố định khép sát hai mép vết rách',
      ],
      warnings: [
        'Chảy máu phun tia hoặc không cầm sau 15 phút cần đến viện ngay',
        'Vết cắt sâu quá 0.5cm cần đến bệnh viện khâu trong 6 giờ đầu',
      ],
      contraindications: [
        'Không tùy tiện thắt garo nếu chưa có chuyên môn y tế',
      ],
      lastUpdated: '24/10/2025',
      isPublished: true,
      sourceOrganization: 'Cục Quản lý Khám chữa bệnh - Bộ Y Tế',
      sourceUrl: 'https://kcb.vn/huong-dan-so-cuu',
    ),
    const KnowledgeArticleModel(
      id: 'kb_3',
      title: 'Xử trí bỏng nhiệt và làm mát tức thời',
      categoryId: 'burn',
      categoryName: 'Bỏng',
      summary:
          'Biện pháp xả nước mát hạ nhiệt trong 20 phút đầu, bảo vệ bọng nước và phân biệt các mức độ bỏng nhiệt.',
      targetInjuryTypeId: 'burn',
      targetInjuryTypeName: 'Bỏng nhiệt / hóa chất',
      defaultSeverity: RuleSeverityLevel.warning,
      steps: [
        'Xả nước sạch mát (15 - 25°C) liên tục trong 15 - 20 phút',
        'Tháo bỏ đồ trang sức, đồng hồ chèn ép',
        'Che phủ nhẹ nhàng bằng gạc vô trùng ẩm',
        'Chuyển viện nếu bỏng diện rộng hoặc bỏng ở vùng mặt/tay',
      ],
      warnings: [
        'Bỏng do hóa chất phải rửa trôi liên tục ít nhất 30 phút',
        'Bỏng điện giật luôn cần kiểm tra nhịp tim tại phòng cấp cứu',
      ],
      contraindications: [
        'TUYỆT ĐỐI KHÔNG chườm đá lạnh buốt trực tiếp lên vết bỏng',
        'KHÔNG bôi kem đánh răng, mỡ trăn, nước mắm hay lòng đỏ trứng',
        'KHÔNG chọc vỡ các bọng nước phồng rộp',
      ],
      lastUpdated: '20/10/2025',
      isPublished: true,
      sourceOrganization: 'Tổ chức Y tế Thế giới (WHO)',
      sourceUrl: 'https://www.who.int/emergencies/first-aid',
    ),
    const KnowledgeArticleModel(
      id: 'kb_4',
      title: 'Chăm sóc tổn thương bầm tím phần mềm (Quy trình 4 bước R.I.C.E)',
      categoryId: 'musculoskeletal',
      categoryName: 'Xương khớp',
      summary:
          'Ứng dụng 4 nguyên tắc Nghỉ ngơi - Chườm lạnh - Băng ép - Kê cao để giảm sưng đau xuất huyết ngầm dưới da.',
      targetInjuryTypeId: 'bruise',
      targetInjuryTypeName: 'Bầm tím phần mềm',
      defaultSeverity: RuleSeverityLevel.normal,
      steps: [
        'Nghỉ ngơi, hạn chế vận động chi bị tổn thương',
        'Chườm lạnh bằng túi đá bọc khăn trong 48 giờ đầu',
        'Băng ép nhẹ bằng băng thun để hạn chế sưng nề',
        'Kê cao chi bị bầm hơn mức tim',
      ],
      warnings: [
        'Nghi ngờ gãy xương khi có biến dạng chi hoặc đau chói dữ dội',
        'Chấn thương vùng đầu kèm nôn mửa cần đi chụp CT khẩn cấp',
      ],
      contraindications: [
        'Không xoa bóp dầu nóng hoặc uống rượu thuốc trong 2 ngày đầu',
      ],
      lastUpdated: '18/10/2025',
      isPublished: true,
      sourceOrganization: 'Mayo Clinic Health System',
      sourceUrl: 'https://www.mayoclinic.org/first-aid',
    ),
    const KnowledgeArticleModel(
      id: 'kb_5',
      title: 'Xử trí vết thương có dị vật cắm sâu & chấn thương hở',
      categoryId: 'other',
      categoryName: 'Vết thương khác',
      summary:
          'Nguyên tắc vàng bất động dị vật, tuyệt đối không tự ý rút ra tại chỗ và kiểm soát nhiễm trùng uốn ván.',
      targetInjuryTypeId: 'other_wounds',
      targetInjuryTypeName: 'Vết thương khác',
      defaultSeverity: RuleSeverityLevel.emergency,
      steps: [
        'Giữ bình tĩnh, không lay chuyển hoặc cố rút dị vật cắm sâu',
        'Dùng gạc hoặc cuộn băng dày chèn hai bên để cố định dị vật',
        'Băng vòng xung quanh để giữ gạc cố định, không ép lên đầu dị vật',
        'Nhanh chóng chuyển nạn nhân đến bệnh viện cấp cứu',
      ],
      warnings: [
        'Dị vật cắm ở mắt, cổ, ngực, bụng có nguy cơ tổn thương mạch máu lớn',
        'Chảy máu nhiều xung quanh dị vật cần ép chặt hai bên cạnh',
      ],
      contraindications: [
        'TUYỆT ĐỐI KHÔNG cố gắng dùng kìm hay nhíp rút dị vật cắm sâu',
        'Không rửa nước xối mạnh trực tiếp vào vết thương có dị vật lớn',
      ],
      lastUpdated: '28/10/2025',
      isPublished: true,
      sourceOrganization: 'Hội Chữ Thập Đỏ Việt Nam',
      sourceUrl: 'https://redcross.org.vn/so-cap-cuu',
    ),
    const KnowledgeArticleModel(
      id: 'kb_6',
      title: 'Quy trình rửa sạch và thay băng vết thương hở hàng ngày',
      categoryId: 'other',
      categoryName: 'Vết thương khác',
      summary:
          'Kỹ thuật vô khuẩn khi thay băng tại nhà, nhận diện sớm dấu hiệu nhiễm trùng da để can thiệp kịp thời.',
      targetInjuryTypeId: 'other_wounds',
      targetInjuryTypeName: 'Vết thương khác',
      defaultSeverity: RuleSeverityLevel.normal,
      steps: [
        'Rửa tay kỹ với xà phòng dưới vòi nước chảy ít nhất 30 giây',
        'Tháo bỏ băng cũ nhẹ nhàng, thấm ướt nước muối nếu băng dính vào vết thương',
        'Dùng gạc tẩm nước muối sinh lý lau nhẹ từ trung tâm vết thương ra ngoài',
        'Thoa thuốc mỡ kháng sinh hoặc kem dưỡng ẩm theo chỉ dẫn y tế',
        'Đặt lớp gạc vô trùng mới và cố định bằng băng keo y tế',
      ],
      warnings: [
        'Vết thương xuất hiện dịch mủ vàng/xanh hoặc có mùi hôi',
        'Vùng da xung quanh sưng đỏ lan rộng quá 2cm, sờ nóng rát',
        'Nạn nhân sốt trên 38°C kèm ớn lạnh',
      ],
      contraindications: [
        'Không dùng oxy già để rửa các vết thương đang lên mô hạt hồi phục',
        'Không rắc bột thuốc kháng sinh trực tiếp lên miệng vết thương',
      ],
      lastUpdated: '26/10/2025',
      isPublished: true,
      sourceOrganization: 'Bộ Y Tế',
      sourceUrl: 'https://kcb.vn/huong-dan-so-cuu',
    ),
  ];

  List<KnowledgeArticleModel> get knowledgeArticles =>
      List.unmodifiable(_knowledgeArticles);

  String _kbSearchQuery = '';
  String get kbSearchQuery => _kbSearchQuery;

  void setKbSearchQuery(String query) {
    _kbSearchQuery = query;
    _currentKbPage = 1;
    notifyListeners();
  }

  // Bộ lọc theo phạm trù vết thương (all, abrasion, cut_laceration, burn, bruise, other_wounds)
  String _selectedInjuryTopicFilter = 'all';
  String get selectedInjuryTopicFilter => _selectedInjuryTopicFilter;

  void setSelectedInjuryTopicFilter(String topicId) {
    _selectedInjuryTopicFilter = topicId;
    _currentKbPage = 1;
    notifyListeners();
  }

  List<KnowledgeArticleModel> get filteredKnowledgeArticles {
    final q = _kbSearchQuery.trim().toLowerCase();
    final topic = _selectedInjuryTopicFilter;

    return _knowledgeArticles.where((a) {
      final matchesTopic = topic == 'all' || a.targetInjuryTypeId == topic;
      final matchesQuery = q.isEmpty ||
          a.title.toLowerCase().contains(q) ||
          a.summary.toLowerCase().contains(q) ||
          a.categoryName.toLowerCase().contains(q) ||
          a.effectiveInjuryTypeName.toLowerCase().contains(q);
      return matchesTopic && matchesQuery;
    }).toList();
  }

  // Phân trang Knowledge Base (Khớp giao diện phân trang Kho tài liệu)
  int _currentKbPage = 1;
  int get currentKbPage => _currentKbPage;
  static const int kbPageSize = 5;

  int get totalKbPages {
    final total = (filteredKnowledgeArticles.length / kbPageSize).ceil();
    return total < 1 ? 1 : total;
  }

  List<KnowledgeArticleModel> get paginatedKnowledgeArticles {
    final all = filteredKnowledgeArticles;
    final startIndex = (_currentKbPage - 1) * kbPageSize;
    if (startIndex >= all.length) return [];
    final endIndex = (startIndex + kbPageSize > all.length)
        ? all.length
        : startIndex + kbPageSize;
    return all.sublist(startIndex, endIndex);
  }

  void selectKbPage(int page) {
    if (page < 1 || page > totalKbPages) return;
    if (_currentKbPage == page) return;
    _currentKbPage = page;
    notifyListeners();
  }

  void goToPreviousKbPage() {
    if (_currentKbPage > 1) {
      _currentKbPage--;
      notifyListeners();
    }
  }

  void goToNextKbPage() {
    if (_currentKbPage < totalKbPages) {
      _currentKbPage++;
      notifyListeners();
    }
  }

  void addKnowledgeArticle(KnowledgeArticleModel article) {
    _knowledgeArticles.insert(0, article);
    _currentKbPage = 1;
    notifyListeners();
  }

  void updateKnowledgeArticle(KnowledgeArticleModel article) {
    final index = _knowledgeArticles.indexWhere((a) => a.id == article.id);
    if (index != -1) {
      _knowledgeArticles[index] = article;
      notifyListeners();
    }
  }

  void deleteKnowledgeArticle(String id) {
    _knowledgeArticles.removeWhere((a) => a.id == id);
    if (_currentKbPage > totalKbPages) {
      _currentKbPage = totalKbPages;
    }
    notifyListeners();
  }

  void toggleArticlePublished(String id) {
    final index = _knowledgeArticles.indexWhere((a) => a.id == id);
    if (index != -1) {
      final old = _knowledgeArticles[index];
      _knowledgeArticles[index] = old.copyWith(isPublished: !old.isPublished);
      notifyListeners();
    }
  }

  // ===========================================================================
  // 1.1. QUẢN LÝ NGUỒN TRÍCH XUẤT Y KHOA CHI TIẾT (Medical Source Links)
  // ===========================================================================
  List<MedicalSourceLink> get adminMedicalSources =>
      _ruleEngineService.medicalSources;

  void addAdminMedicalSource(MedicalSourceLink source) {
    _ruleEngineService.addMedicalSource(source);
    notifyListeners();
  }

  void updateAdminMedicalSource(String id, MedicalSourceLink updated) {
    _ruleEngineService.updateMedicalSource(id, updated);
    notifyListeners();
  }

  void deleteAdminMedicalSource(String id) {
    _ruleEngineService.deleteMedicalSource(id);
    notifyListeners();
  }

  void toggleAdminMedicalSource(String id) {
    _ruleEngineService.toggleMedicalSourceEnabled(id);
    notifyListeners();
  }

  void resetMedicalSourcesToDefault() {
    _ruleEngineService.resetMedicalSourcesToDefault();
    notifyListeners();
  }

  // ===========================================================================
  // 2. QUẢN LÝ LOẠI TỔN THƯƠNG (Injury Types Supported)
  // ===========================================================================
  final List<SupportedInjuryTypeModel> _supportedInjuryTypes = [
    const SupportedInjuryTypeModel(
      id: 'tray_xuoc',
      name: 'Trầy xước',
      topicId: 'abrasion',
      defaultSeverity: RuleSeverityLevel.normal,
      sensitivityMode: AiSensitivityMode.balanced,
      isAiDetectionEnabled: true,
      description:
          'Tổn thương tróc biểu bì nông ngoài da, rỉ máu hoặc dịch nhẹ.',
      totalScansRecorded: 420,
    ),
    const SupportedInjuryTypeModel(
      id: 'vet_cat_rach',
      name: 'Vết cắt / rách da',
      topicId: 'cut_laceration',
      defaultSeverity: RuleSeverityLevel.warning,
      sensitivityMode: AiSensitivityMode.balanced,
      isAiDetectionEnabled: true,
      description:
          'Vết thương hở miệng do vật sắc nhọn cứa hoặc xé rách mô mềm.',
      totalScansRecorded: 295,
    ),
    const SupportedInjuryTypeModel(
      id: 'bong',
      name: 'Bỏng nhiệt / hóa chất',
      topicId: 'burn',
      defaultSeverity: RuleSeverityLevel.warning,
      sensitivityMode: AiSensitivityMode.balanced,
      isAiDetectionEnabled: true,
      description:
          'Vết thương do nhiệt độ cao, nước sôi, lửa, hóa chất hoặc điện giật.',
      totalScansRecorded: 245,
    ),
    const SupportedInjuryTypeModel(
      id: 'bam_tim',
      name: 'Bầm tím phần mềm',
      topicId: 'bruise',
      defaultSeverity: RuleSeverityLevel.normal,
      sensitivityMode: AiSensitivityMode.lenient,
      isAiDetectionEnabled: true,
      description:
          'Tụ máu dưới da do va đập, mô mềm bị dập nát không rách da hở.',
      totalScansRecorded: 210,
    ),
    const SupportedInjuryTypeModel(
      id: 'normal',
      name: 'Da lành / Bình thường',
      topicId: 'abrasion',
      defaultSeverity: RuleSeverityLevel.normal,
      sensitivityMode: AiSensitivityMode.lenient,
      isAiDetectionEnabled: true,
      description:
          'Ảnh da bình thường hoặc ảnh không liên quan, không phát hiện tổn thương da.',
      totalScansRecorded: 85,
    ),
  ];

  List<SupportedInjuryTypeModel> get supportedInjuryTypes =>
      List.unmodifiable(_supportedInjuryTypes);

  // Phân trang nhóm loại tổn thương (5 mục / trang)
  int _currentInjuryTypePage = 1;
  int get currentInjuryTypePage => _currentInjuryTypePage;
  static const int injuryTypePageSize = 5;

  int get totalInjuryTypePages {
    final total = (_supportedInjuryTypes.length / injuryTypePageSize).ceil();
    return total < 1 ? 1 : total;
  }

  List<SupportedInjuryTypeModel> get paginatedInjuryTypes {
    final all = _supportedInjuryTypes;
    final startIndex = (_currentInjuryTypePage - 1) * injuryTypePageSize;
    if (startIndex >= all.length) return [];
    final endIndex = (startIndex + injuryTypePageSize > all.length)
        ? all.length
        : startIndex + injuryTypePageSize;
    return all.sublist(startIndex, endIndex);
  }

  void selectInjuryTypePage(int page) {
    if (page < 1 || page > totalInjuryTypePages) return;
    if (_currentInjuryTypePage == page) return;
    _currentInjuryTypePage = page;
    notifyListeners();
  }

  void goToPreviousInjuryTypePage() {
    if (_currentInjuryTypePage > 1) {
      _currentInjuryTypePage--;
      notifyListeners();
    }
  }

  void goToNextInjuryTypePage() {
    if (_currentInjuryTypePage < totalInjuryTypePages) {
      _currentInjuryTypePage++;
      notifyListeners();
    }
  }

  void toggleInjuryTypeAiDetection(String id) {
    final index = _supportedInjuryTypes.indexWhere((t) => t.id == id);
    if (index != -1) {
      final old = _supportedInjuryTypes[index];
      _supportedInjuryTypes[index] = old.copyWith(
        isAiDetectionEnabled: !old.isAiDetectionEnabled,
      );
      notifyListeners();
    }
  }

  void updateInjuryTypeSensitivity(String id, AiSensitivityMode mode) {
    final index = _supportedInjuryTypes.indexWhere((t) => t.id == id);
    if (index != -1) {
      final old = _supportedInjuryTypes[index];
      _supportedInjuryTypes[index] = old.copyWith(
        sensitivityMode: mode,
      );
      notifyListeners();
    }
  }

  void updateInjuryTypeSeverity(String id, RuleSeverityLevel severity) {
    final index = _supportedInjuryTypes.indexWhere((t) => t.id == id);
    if (index != -1) {
      final old = _supportedInjuryTypes[index];
      _supportedInjuryTypes[index] = old.copyWith(
        defaultSeverity: severity,
      );
      notifyListeners();
    }
  }

  void updateInjuryTypeThreshold(String id, double threshold) {
    final index = _supportedInjuryTypes.indexWhere((t) => t.id == id);
    if (index != -1) {
      final old = _supportedInjuryTypes[index];
      _supportedInjuryTypes[index] = old.copyWith(
        minConfidenceThreshold: threshold,
      );
      notifyListeners();
    }
  }

  // ===========================================================================
  // 3. QUẢN LÝ RULE ENGINE (Các quy tắc sơ cứu & Tùy biến sâu)
  // ===========================================================================
  String _selectedRuleCategoryFilter = 'all';
  String get selectedRuleCategoryFilter => _selectedRuleCategoryFilter;

  void selectRuleCategoryFilter(String categoryId) {
    _selectedRuleCategoryFilter = categoryId;
    _currentRulePage = 1;
    notifyListeners();
  }

  List<FirstAidRule> get adminRuleList => _ruleEngineService.allRules;

  List<FirstAidRule> get filteredAdminRules {
    if (_selectedRuleCategoryFilter == 'all') {
      return adminRuleList;
    }
    return adminRuleList
        .where((r) => r.targetInjuryTypeId == _selectedRuleCategoryFilter)
        .toList();
  }

  // Phân trang Rule Engine (Khớp giao diện phân trang Kho tài liệu)
  int _currentRulePage = 1;
  int get currentRulePage => _currentRulePage;
  static const int rulePageSize = 5;

  int get totalRulePages {
    final total = (filteredAdminRules.length / rulePageSize).ceil();
    return total < 1 ? 1 : total;
  }

  List<FirstAidRule> get paginatedAdminRules {
    final all = filteredAdminRules;
    final startIndex = (_currentRulePage - 1) * rulePageSize;
    if (startIndex >= all.length) return [];
    final endIndex = (startIndex + rulePageSize > all.length)
        ? all.length
        : startIndex + rulePageSize;
    return all.sublist(startIndex, endIndex);
  }

  void selectRulePage(int page) {
    if (page < 1 || page > totalRulePages) return;
    if (_currentRulePage == page) return;
    _currentRulePage = page;
    notifyListeners();
  }

  void goToPreviousRulePage() {
    if (_currentRulePage > 1) {
      _currentRulePage--;
      notifyListeners();
    }
  }

  void goToNextRulePage() {
    if (_currentRulePage < totalRulePages) {
      _currentRulePage++;
      notifyListeners();
    }
  }

  void toggleAdminRule(String ruleId) {
    _ruleEngineService.toggleRuleStatus(ruleId);
    notifyListeners();
  }

  void addAdminRule(FirstAidRule rule) {
    _ruleEngineService.addRule(rule);
    _currentRulePage = 1;
    notifyListeners();
  }

  void updateAdminRule(FirstAidRule rule) {
    _ruleEngineService.updateRule(rule);
    notifyListeners();
  }

  void deleteAdminRule(String ruleId) {
    _ruleEngineService.removeRule(ruleId);
    if (_currentRulePage > totalRulePages) {
      _currentRulePage = totalRulePages;
    }
    notifyListeners();
  }

  void resetRulesToDefault() {
    _ruleEngineService.resetToDefaults();
    _currentRulePage = 1;
    notifyListeners();
  }

  // ===========================================================================
  // 4. QUẢN LÝ CẤU HÌNH HỆ THỐNG (Settings)
  // ===========================================================================
  AdminSystemConfigModel _systemConfig = const AdminSystemConfigModel();
  AdminSystemConfigModel get systemConfig => _systemConfig;

  void updateSystemConfig(AdminSystemConfigModel newConfig) {
    _systemConfig = newConfig;
    notifyListeners();
  }

  void setGlobalSensitivityMode(AiSensitivityMode mode) {
    _systemConfig = _systemConfig.copyWith(
      globalSensitivityMode: mode,
    );
    notifyListeners();
  }

  void setGlobalConfidenceThreshold(double threshold) {
    _systemConfig = _systemConfig.copyWith(
      globalConfidenceThreshold: threshold,
    );
    notifyListeners();
  }

  void toggleEmergencyAlert(bool enabled) {
    _systemConfig = _systemConfig.copyWith(
      isEmergency115AlertEnabled: enabled,
    );
    notifyListeners();
  }

  // ===========================================================================
  // 5. CẤU HÌNH GOOGLE GEMINI AI (ChatBox & Prompt Tư Vấn Y Tế)
  // ===========================================================================
  GeminiConfigModel get geminiConfig => GeminiService.instance.config;

  void updateGeminiConfig(GeminiConfigModel config) {
    GeminiService.instance.updateConfig(config);
    notifyListeners();
  }

  Future<GeminiTestResult> testGeminiConnection({
    required String apiKey,
    required String model,
  }) async {
    return await GeminiService.instance.testApiKey(apiKey: apiKey, model: model);
  }

  // ===========================================================================
  // 6. PHẢN HỒI & ĐÁNH GIÁ AI TỪ NGƯỜI DÙNG (User Feedback Loop)
  // ===========================================================================
  List<AiFeedbackModel> get aiFeedbacks => AiFeedbackService.instance.feedbacks;

  int get totalAiFeedbackCount => AiFeedbackService.instance.totalCount;
  int get inaccurateAiReportCount => AiFeedbackService.instance.inaccurateCount;
  int get helpfulAiReportCount => AiFeedbackService.instance.helpfulCount;
  double get aiAccuracyRate => AiFeedbackService.instance.accuracyRate;

  void deleteAiFeedback(String id) {
    AiFeedbackService.instance.deleteFeedback(id);
    notifyListeners();
  }

  String exportAiFeedbackDatasetJson() {
    return AiFeedbackService.instance.exportFeedbackDatasetJson();
  }
}
