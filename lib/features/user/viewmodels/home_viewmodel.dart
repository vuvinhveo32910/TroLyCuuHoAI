import 'package:flutter/material.dart';

import '../models/home_models.dart';
import 'user_navigation_viewmodel.dart';
import 'first_aid_viewmodel.dart';

mixin TrangChuViewModel on DieuHuongCoSoViewModel, HuongDanSoCuuViewModel {
  // Danh sách dữ liệu cho 4 Thẻ Tính năng (Feature Cards) trên Trang chủ (Đã loại bỏ Hướng dẫn sơ cứu trùng lặp)
  final List<FeatureCardModel> featureCards = const [
    FeatureCardModel(
      id: 'ai_image_analysis',
      title: 'Phân tích ảnh AI',
      description: 'Nhận diện tổn thương và phân loại vết thương',
      icon: Icons.camera_enhance_outlined,
      iconColor: Color(0xFF0D9488), // Xanh ngọc (Teal)
      iconBackgroundColor: Color(0xFFE6F4F1),
    ),
    FeatureCardModel(
      id: 'knowledge_lookup',
      title: 'Kiến thức sơ cứu',
      description: 'Quy trình và cẩm nang sơ cứu chuẩn y tế',
      icon: Icons.menu_book_outlined,
      iconColor: Color(0xFF2563EB), // Xanh dương (Blue)
      iconBackgroundColor: Color(0xFFEBF2FE),
    ),
    FeatureCardModel(
      id: 'medical_documents',
      title: 'Kho tài liệu y tế',
      description: 'Sổ tay & cẩm nang lưu trữ trên máy',
      icon: Icons.description_outlined,
      iconColor: Color(0xFF16A34A), // Xanh lá (Green)
      iconBackgroundColor: Color(0xFFE8F7EE),
    ),
    FeatureCardModel(
      id: 'ai_chatbox',
      title: 'ChatBox AI',
      description: 'Hỏi đáp nhanh với trợ lý sơ cứu 24/7',
      icon: Icons.smart_toy_outlined,
      iconColor: Color(0xFF7C3AED), // Tím (Purple)
      iconBackgroundColor: Color(0xFFF2EBFE),
    ),
  ];

  // Danh sách dữ liệu cho 5 thẻ "Tình huống thường gặp" trên Trang chủ
  final List<CommonSituationModel> commonSituations = const [
    CommonSituationModel(
      id: 'abrasion',
      title: 'Trầy xước',
      baseSkinColor: Color(0xFFE8C5B0),
      woundAccentColor: Color(0xFFC85A48),
      medicalIcon: Icons.grain,
    ),
    CommonSituationModel(
      id: 'cut_laceration',
      title: 'Vết cắt / Vết rách',
      baseSkinColor: Color(0xFFF2D2BD),
      woundAccentColor: Color(0xFFD96B52),
      medicalIcon: Icons.content_cut,
    ),
    CommonSituationModel(
      id: 'burn',
      title: 'Bỏng',
      baseSkinColor: Color(0xFFE5B89B),
      woundAccentColor: Color(0xFFE04F3E),
      medicalIcon: Icons.local_fire_department_outlined,
    ),
    CommonSituationModel(
      id: 'bruise',
      title: 'Bầm',
      baseSkinColor: Color(0xFFEACBB8),
      woundAccentColor: Color(0xFF8E5B72),
      medicalIcon: Icons.blur_circular,
    ),
    CommonSituationModel(
      id: 'other_wounds',
      title: 'Vết thương khác',
      baseSkinColor: Color(0xFFD6C2B4),
      woundAccentColor: Color(0xFF2563EB),
      medicalIcon: Icons.menu_book_rounded,
    ),
  ];

  void onAnalyzeImageNowPressed() {
    navigateToAiAnalysis();
  }

  void onLookupKnowledgePressed() {
    navigateToKnowledgeLookup();
  }

  void onSearchPressed() {
    navigateToKnowledgeLookup();
  }

  void onFeatureCardTapped(FeatureCardModel card) {
    if (card.id == 'ai_image_analysis') {
      navigateToAiAnalysis();
    } else if (card.id == 'knowledge_lookup' || card.id == 'first_aid_guide') {
      navigateToKnowledgeLookup();
    } else if (card.id == 'medical_documents') {
      navigateToMedicalDocuments();
    } else if (card.id == 'ai_chatbox') {
      navigateToChatBoxAi();
    }
  }

  void onSituationCardTapped(CommonSituationModel situation) {
    if (situation.id == 'other_wounds' || situation.id == 'no_clear_injury') {
      // Khi nhấn vào "Vết thương khác" -> chuyển ngay sang màn hình Tra cứu kiến thức sơ cứu
      navigateToKnowledgeLookup();
      return;
    }
    if (firstAidGuidesByTopic.containsKey(situation.id)) {
      navigateToFirstAidGuide(topicId: situation.id);
    } else {
      navigateToKnowledgeLookup();
    }
  }
}
