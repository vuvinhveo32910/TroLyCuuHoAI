import 'rule_models.dart';

/// Dịch vụ Rule Engine xử lý đánh giá sơ cứu y tế thông minh
/// Kết nối kết quả phân tích AI + thông tin người dùng cung cấp + dấu hiệu cảnh báo
class RuleEngineService {
  // Singleton pattern để dùng chung trong toàn bộ ứng dụng
  static final RuleEngineService _instance = RuleEngineService._internal();
  factory RuleEngineService() => _instance;
  RuleEngineService._internal() {
    _initDefaultRules();
    resetMedicalSourcesToDefault();
  }

  // Danh sách các quy tắc lưu trên Supabase Cloud (có thể thêm, sửa, bật/tắt từ Dashboard Admin)
  final List<FirstAidRule> _rules = [];

  List<FirstAidRule> get allRules => List.unmodifiable(_rules);
  List<FirstAidRule> get activeRules =>
      _rules.where((r) => r.isEnabled).toList();

  /// Danh sách nguồn tài liệu y tế chuẩn trích xuất cho hướng dẫn sơ cứu (mặc định)
  static const List<MedicalSourceLink> standardMedicalSources = [
    MedicalSourceLink(
      id: 'src_redcross',
      title: 'Tài liệu hướng dẫn sơ cấp cứu ban đầu',
      organization: 'Hội Chữ Thập Đỏ Việt Nam',
      url: 'https://redcross.org.vn/so-cap-cuu',
      publishYear: '2024',
      targetTopicId: 'all',
      isEnabled: true,
    ),
    MedicalSourceLink(
      id: 'src_kcb',
      title: 'Hướng dẫn xử trí vết thương ngoài da và bỏng',
      organization: 'Cục Quản lý Khám chữa bệnh - Bộ Y Tế',
      url: 'https://kcb.vn/huong-dan-so-cuu',
      publishYear: '2023',
      targetTopicId: 'all',
      isEnabled: true,
    ),
    MedicalSourceLink(
      id: 'src_who',
      title: 'First Aid Protocols and Wound Care Guidelines',
      organization: 'Tổ chức Y tế Thế giới (WHO)',
      url: 'https://www.who.int/emergencies/first-aid',
      publishYear: '2024',
      targetTopicId: 'all',
      isEnabled: true,
    ),
    MedicalSourceLink(
      id: 'src_mayo',
      title: 'Cuts, scrapes and burns first aid care',
      organization: 'Mayo Clinic Health System',
      url: 'https://www.mayoclinic.org/first-aid',
      publishYear: '2025',
      targetTopicId: 'all',
      isEnabled: true,
    ),
  ];

  // Danh sách các nguồn trích xuất y khoa động (Admin có thể tùy chỉnh)
  final List<MedicalSourceLink> _medicalSources = [];
  List<MedicalSourceLink> get medicalSources => List.unmodifiable(_medicalSources);

  List<MedicalSourceLink> getSourceLinksForTopic(String? topicId) {
    return _medicalSources.where((s) {
      if (!s.isEnabled) return false;
      if (topicId == null || topicId.isEmpty || topicId == 'all') return true;
      return s.targetTopicId == 'all' || s.targetTopicId == topicId;
    }).toList();
  }

  void addMedicalSource(MedicalSourceLink source) {
    _medicalSources.add(source);
  }

  void updateMedicalSource(String id, MedicalSourceLink updated) {
    final index = _medicalSources.indexWhere((s) => s.id == id);
    if (index != -1) {
      _medicalSources[index] = updated;
    }
  }

  void deleteMedicalSource(String id) {
    _medicalSources.removeWhere((s) => s.id == id);
  }

  void toggleMedicalSourceEnabled(String id) {
    final index = _medicalSources.indexWhere((s) => s.id == id);
    if (index != -1) {
      final old = _medicalSources[index];
      _medicalSources[index] = old.copyWith(isEnabled: !old.isEnabled);
    }
  }

  void resetMedicalSourcesToDefault() {
    _medicalSources.clear();
    _medicalSources.addAll(standardMedicalSources);
  }

  void loadMedicalSources(List<MedicalSourceLink> items) {
    _medicalSources.clear();
    _medicalSources.addAll(items);
  }

  /// Khởi tạo các luật sơ cứu nền tảng
  void _initDefaultRules() {
    _rules.clear();
    _rules.addAll([
      // LUẬT 1: Chảy máu ồ ạt / Khó cầm -> KHẨN CẤP
      FirstAidRule(
        id: 'rule_bleed_critical',
        code: 'RULE-BLEED-01',
        name: 'Chảy máu nghiêm trọng / Phun tia',
        description:
            'Áp dụng khi vết cắt/rách chảy máu nhiều, phun thành tia hoặc không cầm máu sau 10-15 phút ấn ép trực tiếp.',
        severity: RuleSeverityLevel.emergency,
        targetInjuryTypeId: 'cut_laceration',
        requireBleedingHeavy: true,
        linkedKnowledgeTopicId: 'cut_laceration',
        condition: (ctx) => ctx.isBleedingHeavy,
        primaryActions: [
          'Dùng gạc vô trùng hoặc khăn sạch ấn ép trực tiếp thật mạnh lên miệng vết thương.',
          'Nâng cao vùng chi bị thương cao hơn tim nếu không nghi ngờ gãy xương.',
          'Nếu máu thấm qua lớp gạc đầu, KHÔNG gỡ ra mà đè thêm lớp gạc mới lên trên và băng chặt.',
          'Di chuyển khẩn cấp hoặc đưa nạn nhân đến phòng cấp cứu / bệnh viện gần nhất.',
        ],
        contraindications: [
          'Tuyệt đối không đắp thuốc lá, bột cà phê, tro than lên vết thương hở.',
          'Không tùy tiện thắt garo nếu chưa được đào tạo y tế (trừ trường hợp đứt lìa chi).',
        ],
        emergencyRecommendation:
            'CẦN CẤP CỨU NGAY: Mất máu nhiều có thể dẫn đến tụt huyết áp và sốc mất máu nguy hiểm tính mạng!',
      ),

      // LUẬT 2: Vết thương có dị vật cắm sâu -> CẦN CHÚ Ý / KHẨN CẤP
      FirstAidRule(
        id: 'rule_foreign_deep',
        code: 'RULE-DEEP-02',
        name: 'Vết thương sâu hoặc có dị vật đâm vào',
        description:
            'Áp dụng khi vết rách hở sâu, nhìn thấy mô mỡ/gân cơ hoặc có mảnh kim loại, thủy tinh, que đâm sâu.',
        severity: RuleSeverityLevel.emergency,
        targetInjuryTypeId: 'all',
        requireForeignBody: true,
        linkedKnowledgeTopicId: 'other_wounds',
        condition: (ctx) =>
            ctx.hasDeepWoundOrForeignBody || ctx.injuryTypeId == 'foreign_body',
        primaryActions: [
          'GIỮ NGUYÊN DỊ VẬT: Dùng cuộn băng/gạc chèn hai bên xung quanh dị vật để cố định.',
          'Băng vòng xung quanh để giữ dị vật không bị xê dịch trong quá trình vận chuyển.',
          'Đưa bệnh nhân đến cơ sở y tế để bác sĩ xử lý trong điều kiện vô trùng.',
        ],
        contraindications: [
          'TUYỆT ĐỐI KHÔNG TỰ Ý RÚT DỊ VẬT ĐÂM SÂU: Rút ra có thể gây đứt mạch máu ngầm và xuất huyết dữ dội!',
          'Không cố rửa hoặc ngoáy sâu vào bên trong vết thương.',
        ],
        emergencyRecommendation:
            'Cần đến bệnh viện khâu miệng vết thương và tiêm phòng uốn ván (SAT) trong vòng 24 giờ đầu.',
      ),

      // LUẬT 3: Bỏng diện rộng, bỏng phồng rộp lớn hoặc do hóa chất/điện -> KHẨN CẤP
      FirstAidRule(
        id: 'rule_burn_severe',
        code: 'RULE-BURN-03',
        name: 'Bỏng nặng / Hóa chất / Điện giật',
        description:
            'Áp dụng khi vết bỏng lớn hơn lòng bàn tay, bỏng ở mặt/bàn tay/vùng kín hoặc do hóa chất, điện giật.',
        severity: RuleSeverityLevel.emergency,
        targetInjuryTypeId: 'burn',
        requireLargeBurnOrChemical: true,
        linkedKnowledgeTopicId: 'burn',
        condition: (ctx) =>
            ctx.injuryTypeId == 'burn' && ctx.isLargeAreaBurnOrChemical,
        primaryActions: [
          'Xả nước sạch mát (15 - 25°C) liên tục lên vùng bỏng ít nhất 15 - 20 phút.',
          'Nếu bỏng hóa chất: Rửa trôi thật nhiều nước và cởi bỏ quần áo dính hóa chất.',
          'Nhẹ nhàng tháo nhẫn, đồng hồ trước khi vùng mô bị sưng phù nề.',
          'Che phủ vết bỏng bằng màng bọc thực phẩm sạch hoặc gạc vô trùng ẩm.',
          'Chuyển nạn nhân đến khoa bỏng bệnh viện ngay lập tức.',
        ],
        contraindications: [
          'TUYỆT ĐỐI KHÔNG chườm đá lạnh trực tiếp lên vết bỏng (gây bỏng lạnh hoại tử mô).',
          'TUYỆT ĐỐI KHÔNG bôi kem đánh răng, mỡ trăn, nước mắm hay lòng đỏ trứng.',
          'TUYỆT ĐỐI KHÔNG chọc vỡ các bọng nước phồng rộp.',
        ],
        emergencyRecommendation:
            'Cần đến viện cấp cứu ngay để chống sốc bỏng và bù dịch điện giải kịp thời.',
      ),

      // LUẬT 4: Chấn thương kèm nghi ngờ gãy xương / sai khớp -> CẢNH BÁO
      FirstAidRule(
        id: 'rule_fracture_pain',
        code: 'RULE-BONE-04',
        name: 'Bầm dập dữ dội / Nghi ngờ gãy xương',
        description:
            'Áp dụng khi vùng bầm tím sưng phù nề nhanh, đau chói, biến dạng hoặc không thể cử động chi.',
        severity: RuleSeverityLevel.warning,
        targetInjuryTypeId: 'bruise',
        requireSeverePainOrFracture: true,
        requiredPainLevel: PainLevel.severe,
        linkedKnowledgeTopicId: 'bruise',
        condition: (ctx) =>
            ctx.injuryTypeId == 'bruise' && (ctx.isSeverePainOrFractureSuspected || ctx.painLevel == PainLevel.severe),
        primaryActions: [
          'Áp dụng phác đồ R.I.C.E: Nghỉ ngơi (Rest) - Chườm lạnh (Ice) - Băng ép nhẹ (Compression) - Kê cao (Elevation).',
          'Cố định tạm thời chi bị thương bằng nẹp hoặc khăn để tránh xê dịch.',
          'Đi chụp X-Quang tại cơ sở y tế để kiểm tra rạn/gãy xương.',
        ],
        contraindications: [
          'Không xoa bóp dầu nóng, cao dán hoặc rượu thuốc lên vùng chấn thương trong 48 giờ đầu.',
          'Không cố bẻ hoặc nắn khớp khi chưa có kết quả chẩn đoán hình ảnh.',
        ],
        emergencyRecommendation:
            'Nên đến bệnh viện chụp X-quang nếu sau 24 giờ cơn đau không giảm hoặc vùng chi bầm tím lan rộng.',
      ),

      // LUẬT 5: Nhiễm trùng vết thương -> CẢNH BÁO
      FirstAidRule(
        id: 'rule_infection',
        code: 'RULE-INFECT-05',
        name: 'Dấu hiệu nhiễm trùng vết thương',
        description:
            'Áp dụng khi vết thương có dấu hiệu sưng đỏ lan rộng, chảy dịch mủ hôi, nóng rát hoặc sốt.',
        severity: RuleSeverityLevel.warning,
        targetInjuryTypeId: 'all',
        requireInfection: true,
        linkedKnowledgeTopicId: 'other_wounds',
        condition: (ctx) => ctx.hasSignsOfInfection,
        primaryActions: [
          'Vệ sinh nhẹ nhàng bằng nước muối sinh lý 0.9%.',
          'Sát trùng mép vết thương bằng dung dịch Povidone-Iodine 10%.',
          'Băng gạc thoáng, theo dõi nhiệt độ cơ thể và đến phòng khám chuyên khoa.',
        ],
        contraindications: [
          'Không tự ý mua kháng sinh uống hoặc rắc bột kháng sinh trực tiếp lên vết thương.',
          'Không cào gãi lớp vảy đang hình thành.',
        ],
        emergencyRecommendation:
            'Cần gặp bác sĩ để được kê đơn kháng sinh phù hợp, tránh biến chứng nhiễm trùng huyết hoặc uốn ván.',
      ),

      // LUẬT 6: Trầy xước ngoài da tiêu chuẩn -> BÌNH THƯỜNG
      FirstAidRule(
        id: 'rule_abrasion_standard',
        code: 'RULE-ABRASION-06',
        name: 'Trầy xước ngoài da nông',
        description:
            'Áp dụng cho các vết trầy xước biểu bì thông thường không có biến chứng.',
        severity: RuleSeverityLevel.normal,
        targetInjuryTypeId: 'abrasion',
        linkedKnowledgeTopicId: 'abrasion',
        condition: (ctx) =>
            ctx.injuryTypeId == 'abrasion' &&
            !ctx.isBleedingHeavy &&
            !ctx.hasSignsOfInfection,
        primaryActions: [
          'Rửa sạch tay bằng xà phòng trước khi chạm vào vết thương.',
          'Rửa vết trầy xước dưới vòi nước sạch hoặc nước muối sinh lý để loại bỏ bụi đất cát.',
          'Sát khuẩn nhẹ nhàng bằng dung dịch Povidone-Iodine hoặc Chlorhexidine.',
          'Băng một lớp băng cá nhân thoáng khí hoặc để hở nếu vết trầy đã khô mặt.',
        ],
        contraindications: [
          'Không dùng cồn đỏ hoặc cồn 90 độ đậm đặc đổ trực tiếp vào miệng vết thương hở vì gây xót rát và chết mô hạt.',
          'Không dùng oxy già đậm đặc lên vết thương đang lên da non.',
        ],
        emergencyRecommendation:
            'Chăm sóc tại nhà. Nếu có dấu hiệu sốt, sưng đỏ đau nhức sau 2-3 ngày, hãy đến khám tại trạm y tế.',
      ),

      // LUẬT 7: Vết cắt nhỏ ngoài da tiêu chuẩn -> BÌNH THƯỜNG
      FirstAidRule(
        id: 'rule_cut_standard',
        code: 'RULE-CUT-07',
        name: 'Vết cắt nông nhỏ',
        description:
            'Áp dụng cho vết đứt tay do dao, giấy hoặc vật sắc nhọn đã cầm máu được.',
        severity: RuleSeverityLevel.normal,
        targetInjuryTypeId: 'cut_laceration',
        linkedKnowledgeTopicId: 'cut_laceration',
        condition: (ctx) =>
            ctx.injuryTypeId == 'cut_laceration' &&
            !ctx.isBleedingHeavy &&
            !ctx.hasDeepWoundOrForeignBody,
        primaryActions: [
          'Ấn nhẹ gạc sạch lên vết cắt 1 - 3 phút để máu ngừng chảy hoàn toàn.',
          'Rửa sạch vết cắt bằng nước muối sinh lý.',
          'Thoa thuốc mỡ kháng sinh hoặc thuốc sát trùng Povidone-iodine.',
          'Dán băng dán cá nhân giữ khép 2 mép vết cắt.',
        ],
        contraindications: [
          'Tránh làm ướt băng khi tắm rửa trong 24 giờ đầu.',
          'Không bôi các loại lá cây chưa khử trùng.',
        ],
        emergencyRecommendation:
            'Nếu vết cắt do kim loại rỉ sét hoặc vật bẩn gây ra, cần tiêm phòng uốn ván trong vòng 24 - 48 giờ.',
      ),

      // LUẬT 8: Bỏng nhẹ độ 1 tiêu chuẩn -> BÌNH THƯỜNG
      FirstAidRule(
        id: 'rule_burn_mild',
        code: 'RULE-BURN-08',
        name: 'Bỏng nhẹ bề mặt (Độ 1)',
        description:
            'Áp dụng cho bỏng bô xe, nước sôi nhẹ diện tích nhỏ, da chỉ đỏ rát và chưa phồng rộp.',
        severity: RuleSeverityLevel.normal,
        targetInjuryTypeId: 'burn',
        linkedKnowledgeTopicId: 'burn',
        condition: (ctx) =>
            ctx.injuryTypeId == 'burn' && !ctx.isLargeAreaBurnOrChemical,
        primaryActions: [
          'Xả nước mát sạch liên tục lên vùng bỏng 15 - 20 phút để hạ nhiệt.',
          'Bôi gel lô hội (aloe vera) hoặc kem dưỡng ẩm trị bỏng chuyên dụng (như Biafine, Panthenol).',
          'Che nhẹ bằng gạc mỏng sạch để tránh cọ xát với quần áo.',
        ],
        contraindications: [
          'Không bôi kem đánh răng, mỡ lợn hoặc cồn lên vết bỏng.',
          'Không chườm đá lạnh buốt.',
        ],
        emergencyRecommendation:
            'Theo dõi tại nhà. Nếu xuất hiện bọng nước lớn hoặc đau rát kéo dài trên 3 ngày, hãy đi khám chuyên khoa.',
      ),

      // LUẬT 9: Bầm tím nhẹ tiêu chuẩn -> BÌNH THƯỜNG
      FirstAidRule(
        id: 'rule_bruise_standard',
        code: 'RULE-BRUISE-09',
        name: 'Bầm tím phần mềm thông thường',
        description:
            'Áp dụng cho các vết va đập nhẹ, bầm tím dưới da không gãy xương.',
        severity: RuleSeverityLevel.normal,
        targetInjuryTypeId: 'bruise',
        linkedKnowledgeTopicId: 'bruise',
        condition: (ctx) =>
            ctx.injuryTypeId == 'bruise' &&
            !ctx.isSeverePainOrFractureSuspected,
        primaryActions: [
          'Chườm lạnh: Dùng túi đá bọc trong khăn sạch chườm lên vùng bầm 15 phút/lần trong ngày đầu.',
          'Kê cao chi bị bầm nếu có thể.',
          'Sau 48 giờ có thể chuyển sang chườm ấm nhẹ để tăng tuần hoàn tan máu bầm.',
        ],
        contraindications: [
          'Không xoa bóp dầu nóng ngay sau khi va đập (làm vỡ thêm mao mạch và máu tụ to hơn).',
        ],
        emergencyRecommendation:
            'Vết bầm thông thường sẽ tự khỏi sau 1 - 2 tuần chuyển màu từ tím sang xanh vàng.',
      ),

      // LUẬT 10: Cảm giác đau dữ dội (Đau nặng) -> CẢNH BÁO / KHÁM CHUYÊN SÂU
      FirstAidRule(
        id: 'rule_pain_severe',
        code: 'RULE-PAIN-SEVERE-10',
        name: 'Cảm giác đau dữ dội (Đau nặng)',
        description:
            'Áp dụng khi người dùng đánh giá mức độ đau nặng (7-10/10), cảnh báo chấn thương mô sâu, chèn ép thần kinh hoặc gãy xương ngầm.',
        severity: RuleSeverityLevel.warning,
        targetInjuryTypeId: 'all',
        requireSeverePainOrFracture: true,
        requiredPainLevel: PainLevel.severe,
        linkedKnowledgeTopicId: 'other_wounds',
        condition: (ctx) => ctx.painLevel == PainLevel.severe,
        primaryActions: [
          'Bất động vùng chi bị đau, đặt ở tư thế thoải mái nhất và hạn chế tối đa cử động.',
          'Kê cao chi hơn mức tim để giảm ứ trệ tuần hoàn và giảm áp lực sưng nhức.',
          'Nếu không có vết thương hở rách da: Chườm lạnh ngắt quãng 15 phút bằng khăn bọc đá để tê liệt tạm thời thụ thể đau.',
          'Có thể dùng thuốc giảm đau thông thường (như Paracetamol) theo đúng liều lượng chỉ dẫn nếu không có tiền sử dị ứng hoặc bệnh gan.',
        ],
        contraindications: [
          'TUYỆT ĐỐI KHÔNG xoa dầu nóng, cạo gió hoặc nắn bóp mạnh khi đang đau dữ dội.',
          'Không dùng Aspirin hoặc Ibuprofen nếu vết thương đang chảy máu chưa cầm (gây tăng nguy cơ xuất huyết).',
        ],
        emergencyRecommendation:
            'Đau dữ dội kèm sưng to hoặc khó cử động là dấu hiệu cần đến bệnh viện chụp X-quang hoặc siêu âm kiểm tra gãy xương/đứt dây chằng.',
      ),

      // LUẬT 11: Bỏng không đau / Mất cảm giác đau (Nghi ngờ bỏng sâu độ 3) -> KHẨN CẤP
      FirstAidRule(
        id: 'rule_burn_deep_numb',
        code: 'RULE-BURN-NUMB-11',
        name: 'Bỏng không đau / Mất cảm giác (Nghi ngờ bỏng sâu độ 3)',
        description:
            'Cảnh báo đặc biệt: Vết bỏng sâu độ 3 làm tổn thương hết lớp hạ bì và đầu mút dây thần kinh khiến nạn nhân không thấy đau rát.',
        severity: RuleSeverityLevel.emergency,
        targetInjuryTypeId: 'burn',
        linkedKnowledgeTopicId: 'burn',
        condition: (ctx) =>
            ctx.injuryTypeId == 'burn' && ctx.painLevel == PainLevel.none,
        primaryActions: [
          'Che phủ nhẹ nhàng vết bỏng bằng gạc vô trùng ẩm hoặc màng bọc thực phẩm sạch.',
          'Giữ ấm cho cơ thể nạn nhân, bù nước điện giải bằng oresol hoặc nước ấm.',
          'Đưa nạn nhân đến chuyên khoa bỏng hoặc phòng cấp cứu bệnh viện ngay lập tức.',
        ],
        contraindications: [
          'Không chủ quan vì thấy không đau - đây là dấu hiệu tổn thương sâu phá hủy thụ thể thần kinh.',
          'Tuyệt đối không chườm đá lạnh buốt, không bôi thuốc mỡ hoặc chất lạ lên vết bỏng sâu.',
        ],
        emergencyRecommendation:
            'CẦN ĐẾN BỆNH VIỆN NGAY: Bỏng không đau thường là bỏng toàn phần (Độ 3) phá hủy thần kinh bì, cần can thiệp ngoại khoa.',
      ),

      // LUẬT 12: Đa tổn thương kết hợp trên 1 ảnh (2-3 vết thương) -> CẦN CHÚ Ý
      FirstAidRule(
        id: 'rule_multi_wound_combined',
        code: 'RULE-MULTI-WOUND-12',
        name: 'Tổn thương kết hợp nhiều dạng vết thương',
        description:
            'Áp dụng khi trên ảnh nhận diện đồng thời từ 2-3 dạng tổn thương (ví dụ vừa vết cắt vừa trầy xước, hoặc vừa bỏng vừa vết rách).',
        severity: RuleSeverityLevel.warning,
        targetInjuryTypeId: 'all',
        requireMultipleInjuries: true,
        linkedKnowledgeTopicId: 'other_wounds',
        condition: (ctx) => ctx.hasMultipleInjuries,
        primaryActions: [
          'Thực hiện theo nguyên tắc phân loại ưu tiên Triage: 1. CẦM MÁU vết cắt/rách trước bằng ấn ép gạc vô trùng 10-15 phút.',
          'Sau khi đã kiểm soát chảy máu: Rửa sạch và sát trùng vùng trầy xước lân cận bằng nước muối sinh lý 0.9% và Povidone-Iodine.',
          'Nếu có bầm tím sưng nề kèm theo: Chườm lạnh xung quanh, nhưng tránh để hơi lạnh hoặc túi nước đè trực tiếp lên miệng vết thương hở.',
          'Băng bảo vệ riêng biệt: Dán băng khép miệng vết cắt và che gạc thoáng cho vùng trầy xước.',
        ],
        contraindications: [
          'Không dùng chung miếng gạc bẩn đã lau vết thương này để chà xát sang vết thương khác (gây lây nhiễm chéo).',
        ],
        emergencyRecommendation:
            'Đa tổn thương kết hợp có nguy cơ nhiễm trùng và biến chứng cao hơn, nên đến cơ sở y tế gần nhất để nhân viên y tế sát trùng và băng bó chuyên nghiệp.',
      ),
    ]);
  }

  /// Hàm cốt lõi: Đánh giá ngữ cảnh tổn thương thông qua Rule Engine
  RuleEvaluationResult evaluate(InjuryContext context) {
    // 1. Lọc các luật đang kích hoạt
    final List<FirstAidRule> triggered = [];
    for (final rule in activeRules) {
      if (rule.matches(context)) {
        triggered.add(rule);
      }
    }

    // 2. Xác định mức độ nghiêm trọng cao nhất
    RuleSeverityLevel highestSeverity = RuleSeverityLevel.normal;
    for (final rule in triggered) {
      if (rule.severity == RuleSeverityLevel.emergency) {
        highestSeverity = RuleSeverityLevel.emergency;
        break;
      } else if (rule.severity == RuleSeverityLevel.warning) {
        highestSeverity = RuleSeverityLevel.warning;
      }
    }

    // Nếu không có luật nào kích hoạt trực tiếp, dựa vào loại tổn thương
    if (triggered.isEmpty) {
      if (context.injuryTypeId == 'cut_laceration' ||
          context.injuryTypeId == 'burn') {
        highestSeverity = RuleSeverityLevel.warning;
      }
    }

    // 3. Tổng hợp danh sách các bước sơ cứu ưu tiên
    final List<String> actions = [];
    final List<String> contraindications = [];
    final List<String> warnings = [];

    // Ưu tiên các luật emergency lên trước
    final sortedRules = List<FirstAidRule>.from(triggered)
      ..sort((a, b) => b.severity.index.compareTo(a.severity.index));

    for (final rule in sortedRules) {
      for (final act in rule.primaryActions) {
        if (!actions.contains(act)) actions.add(act);
      }
      for (final con in rule.contraindications) {
        if (!contraindications.contains(con)) contraindications.add(con);
      }
      if (rule.emergencyRecommendation.isNotEmpty &&
          !warnings.contains(rule.emergencyRecommendation)) {
        warnings.add(rule.emergencyRecommendation);
      }
    }

    // Thêm các khuyến nghị theo đối tượng nếu là trẻ nhỏ/người già
    if (context.isChildOrElderly &&
        highestSeverity != RuleSeverityLevel.normal) {
      warnings.add(
        'Nạn nhân là trẻ nhỏ/người cao tuổi có sức đề kháng và ngưỡng chịu đựng thấp hơn, cần ưu tiên đưa đến cơ sở y tế sớm.',
      );
    }

    // Bổ sung khuyến nghị theo mức độ cảm giác đau 3 nấc
    if (context.painLevel == PainLevel.severe) {
      if (highestSeverity == RuleSeverityLevel.normal) {
        highestSeverity = RuleSeverityLevel.warning;
      }
      if (!warnings.any((w) => w.contains('đau nặng') || w.contains('đau dữ dội'))) {
        warnings.insert(
          0,
          'Mức độ đau nặng (7-10/10): Nạn nhân đang đau dữ dội. Hãy cố định bất động chi và đưa đến cơ sở y tế để chụp X-quang/siêu âm loại trừ tổn thương mô sâu, đứt gân hoặc gãy xương.',
        );
      }
    } else if (context.painLevel == PainLevel.none && context.injuryTypeId == 'burn') {
      highestSeverity = RuleSeverityLevel.emergency;
      if (!warnings.any((w) => w.contains('bỏng sâu'))) {
        warnings.insert(
          0,
          'CẢNH BÁO BỎNG SÂU: Vết bỏng không đau là dấu hiệu tổn thương sâu phá hủy đầu mút thần kinh cảm giác (Bỏng độ 3). Cần đi khám viện ngay!',
        );
      }
    }

    // Bổ sung ghi chú nếu phát hiện 2-3 vết thương kết hợp trên ảnh
    if (context.hasMultipleInjuries) {
      if (highestSeverity == RuleSeverityLevel.normal) {
        highestSeverity = RuleSeverityLevel.warning;
      }
      final multiList = [context.injuryTypeName, ...context.secondaryInjuryTypeNames].join(', ');
      warnings.add('Ảnh có đa tổn thương kết hợp ($multiList): Luôn ưu tiên cầm máu vết thương hở trước, sau đó mới vệ sinh sát khuẩn vùng trầy xước.');
    }

    // =========================================================================
    // CÁ NHÂN HÓA THEO HỒ SƠ Y TẾ & BỆNH LÝ NỀN CỦA NGƯỜI DÙNG (RULE ENGINE)
    // =========================================================================
    final isOpenWound = context.injuryTypeId == 'cut_laceration' ||
        context.injuryTypeId == 'abrasion' ||
        context.injuryTypeId == 'other_wounds' ||
        context.isBleedingHeavy ||
        context.hasDeepWoundOrForeignBody;

    // A. BỆNH MÁU KHÓ ĐÔNG (HEMOPHILIA):
    if (context.hasHemophilia && (isOpenWound || context.injuryTypeId == 'bruise')) {
      highestSeverity = RuleSeverityLevel.emergency;
      warnings.insert(
        0,
        '🩸 CẢNH BÁO NGUY CẤP (BỆNH MÁU KHÓ ĐÔNG - HEMOPHILIA): Nạn nhân có tiền sử rối loạn đông máu. Vết thương rách da dù nhỏ cũng có nguy cơ mất máu không tự cầm và tụ máu mô sâu nguy hiểm tính mạng! Bắt buộc: Băng ép chèn trực tiếp liên tục, gọi 115 hoặc di chuyển khẩn cấp tới bệnh viện có sẵn yếu tố đông máu.',
      );
      if (!actions.any((a) => a.contains('Hemophilia') || a.contains('ép trực tiếp'))) {
        actions.insert(0, 'Áp gạc vô trùng ép thật mạnh và liên tục lên miệng vết thương, tuyệt đối không mở ra xem máu ngừng chảy chưa.');
        actions.insert(1, 'Thông báo ngay cho bác sĩ hoặc kíp cấp cứu 115 rằng nạn nhân mắc bệnh Máu khó đông (Hemophilia).');
      }
      if (!contraindications.any((c) => c.contains('Aspirin') || c.contains('NSAID'))) {
        contraindications.insert(
          0,
          'TUYỆT ĐỐI KHÔNG DÙNG Aspirin hoặc thuốc kháng viêm giảm đau NSAID (như Ibuprofen) vì ức chế ngưng tập tiểu cầu, làm máu chảy dữ dội hơn.',
        );
      }
    }

    // B. ĐÁI THÁO ĐƯỜNG (TIỂU ĐƯỜNG - DIABETES):
    if (context.hasDiabetes && (isOpenWound || context.injuryTypeId == 'burn')) {
      if (highestSeverity == RuleSeverityLevel.normal) {
        highestSeverity = RuleSeverityLevel.warning;
      }
      warnings.insert(
        0,
        '🩺 LƯU Ý ĐẶC BIỆT CHO NGƯỜI BỆNH TIỂU ĐƯỜNG: Vết thương ở người đái tháo đường có nguy cơ nhiễm trùng và hoại tử cao gấp nhiều lần do giảm tưới máu vi mạch. Cần: Sát trùng bằng nước muối sinh lý NaCl 0.9%, băng vô trùng, kiểm tra đường huyết thường xuyên và đi khám chuyên khoa ngay nếu xuất hiện sưng, nóng, đỏ, đau hoặc chảy dịch sau 24-48 giờ.',
      );
      if (!contraindications.any((c) => c.contains('ngâm nước ấm') || c.contains('tiểu đường'))) {
        contraindications.add('Không ngâm vết thương/bàn chân lâu trong nước ấm hoặc các loại dung dịch sát khuẩn nồng độ cao vì dễ gây trợt loét vi mô.');
      }
    }

    // C. BỆNH TIM MẠCH (CARDIOVASCULAR):
    if (context.hasCardiovascular) {
      warnings.add(
        '❤️ CẢNH BÁO BỆNH TIM MẠCH: Chấn thương kèm mất máu hoặc đau đớn có thể gây rối loạn nhịp tim hoặc tụt huyết áp đột ngột. Hãy đặt nạn nhân nằm nghỉ ngơi nơi thoáng khí, giữ ấm cơ thể, nới lỏng cổ áo và theo dõi sát mạch đập.',
      );
    }

    // D. TIỀN SỬ DỊ ỨNG THUỐC & HÓA CHẤT:
    if (context.allergies.isNotEmpty) {
      if (context.hasAlcoholAllergy) {
        contraindications.insert(
          0,
          '⚠️ CHỐNG CHỈ ĐỊNH DỊ ỨNG CỒN: Nạn nhân có tiền sử dị ứng CỒN Y TẾ. TUYỆT ĐỐI KHÔNG DÙNG CỒN (Ethanol/Isopropanol) để sát trùng vết thương! Hãy dùng nước muối sinh lý NaCl 0.9% hoặc Povidone Iodine pha loãng.',
        );
      }
      if (context.hasPenicillinAllergy) {
        contraindications.insert(
          0,
          '⚠️ CHỐNG CHỈ ĐỊNH DỊ ỨNG KHÁNG SINH: Nạn nhân dị ứng kháng sinh nhóm Penicillin. Không tự ý rắc bột kháng sinh hoặc bôi kem mỡ chứa Penicillin lên vết thương.',
        );
      }
      if (context.hasIodineAllergy) {
        contraindications.insert(
          0,
          '⚠️ CHỐNG CHỈ ĐỊNH DỊ ỨNG I-ỐT: Nạn nhân dị ứng Povidone Iodine (Betadine). Thay thế hoàn toàn bằng nước muối sinh lý NaCl 0.9%.',
        );
      }
    }

    // 4. Tạo tóm tắt & tiêu đề kết quả
    String summaryTitle;
    String statusDescription;
    bool shouldCall115 = false;

    switch (highestSeverity) {
      case RuleSeverityLevel.emergency:
        summaryTitle = 'CẢNH BÁO NGUY HIỂM: CẦN CAN THIỆP Y TẾ KHẨN CẤP';
        statusDescription =
            'Ứng dụng phát hiện các dấu hiệu nguy kịch (chảy máu nhiều, tổn thương sâu hoặc bỏng nặng). Hãy đưa ngay nạn nhân đến cơ sở y tế cấp cứu gần nhất!';
        shouldCall115 = true;
        break;
      case RuleSeverityLevel.warning:
        summaryTitle = 'TÌNH TRẠNG CẦN CHÚ Ý THEO DÕI SÁT';
        statusDescription =
            'Tổn thương có nguy cơ biến chứng hoặc nhiễm trùng. Cần thực hiện các bước sơ cứu cẩn thận và theo dõi sát diễn biến.';
        break;
      case RuleSeverityLevel.normal:
        summaryTitle = 'TÌNH TRẠNG ỔN ĐỊNH - SƠ CỨU TẠI NHÀ';
        statusDescription =
            'Tổn thương mức độ nhẹ bề mặt, không có dấu hiệu đe dọa nguy hiểm. Bạn có thể tự thực hiện sơ cứu theo các bước chuẩn bên dưới.';
        break;
    }

    return RuleEvaluationResult(
      finalSeverity: highestSeverity,
      summaryTitle: summaryTitle,
      statusDescription: statusDescription,
      triggeredRules: triggered,
      priorityActions: actions.isNotEmpty
          ? actions
          : [
              'Làm sạch vùng tổn thương bằng nước sạch hoặc nước muối sinh lý.',
              'Sát khuẩn nhẹ nhàng bằng dung dịch sát trùng chuyên dụng.',
              'Bảo vệ vết thương bằng gạc hoặc băng dán sạch.',
            ],
      contraindications: contraindications.isNotEmpty
          ? contraindications
          : [
              'Không tự ý bôi các chất lạ hoặc thuốc chưa rõ nguồn gốc.',
              'Không chà xát mạnh gây tổn thương thêm mô mềm.',
            ],
      warningSymptoms: warnings.isNotEmpty
          ? warnings
          : [
              'Vết thương sưng to, đau nhức dữ dội hoặc chảy dịch mủ sau vài ngày.',
              'Không cầm được máu sau 15 phút băng ép.',
            ],
      emergencyHospitalAdvice: shouldCall115
          ? 'ĐƯA NẠN NHÂN ĐẾN CƠ SỞ Y TẾ HOẶC PHÒNG CẤP CỨU GẦN NHẤT NGAY!'
          : 'Đến cơ sở y tế nếu có bất kỳ dấu hiệu nhiễm trùng hoặc diễn biến bất thường.',
      sourceLinks: getSourceLinksForTopic(context.injuryTypeId),
      shouldCallEmergency115: shouldCall115,
    );
  }

  /// Thêm luật mới từ Admin Dashboard
  void addRule(FirstAidRule newRule) {
    _rules.add(newRule);
  }

  /// Bật/Tắt trạng thái hoạt động của luật
  void toggleRuleStatus(String ruleId) {
    final index = _rules.indexWhere((r) => r.id == ruleId);
    if (index != -1) {
      final old = _rules[index];
      _rules[index] = old.copyWith(isEnabled: !old.isEnabled);
    }
  }

  /// Cập nhật thông tin luật
  void updateRule(FirstAidRule updatedRule) {
    final index = _rules.indexWhere((r) => r.id == updatedRule.id);
    if (index != -1) {
      _rules[index] = updatedRule;
    }
  }

  /// Xóa luật
  void removeRule(String ruleId) {
    _rules.removeWhere((r) => r.id == ruleId);
  }

  /// Khôi phục toàn bộ danh sách luật về mặc định chuẩn y tế
  void resetToDefaults() {
    _initDefaultRules();
  }
}
