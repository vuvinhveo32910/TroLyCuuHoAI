import 'package:flutter/material.dart';

import 'analysis_result_viewmodel.dart';
import 'chat_viewmodel.dart';
import 'document_viewmodel.dart';
import 'first_aid_viewmodel.dart';
import 'history_viewmodel.dart';
import 'home_viewmodel.dart';
import 'image_analysis_viewmodel.dart';
import 'knowledge_viewmodel.dart';
import 'user_navigation_viewmodel.dart';

class UserViewModel extends ChangeNotifier
    with
        DieuHuongCoSoViewModel,
        HuongDanSoCuuViewModel,
        KetQuaPhanTichViewModel,
        PhanTichAnhViewModel,
        TrangChuViewModel,
        TraCuuKienThucViewModel,
        ChatBoxAiViewModel,
        KhoTaiLieuViewModel,
        LichSuPhanTichViewModel {
  @override
  void onViewFirstAidGuidePressed() {
    // Tự động đồng bộ các dấu hiệu quan sát kèm theo (checkbox), mức độ đau và đa tổn thương sang Rule Engine
    final targetTopic = analysisResult.detectedTopicId.isNotEmpty
        ? analysisResult.detectedTopicId
        : 'abrasion';
    final secondaryTopics = analysisResult.hasMultipleInjuries
        ? analysisResult.allDetections
              .where((d) => d.topicId != targetTopic)
              .map((d) => d.topicId)
              .toList()
        : <String>[];
    final secondaryNames = analysisResult.hasMultipleInjuries
        ? analysisResult.allDetections
              .where((d) => d.topicId != targetTopic)
              .map((d) => d.label)
              .toList()
        : <String>[];

    toggleWarningSymptom(
      injuryTypeId: targetTopic,
      injuryTypeName: getTopicDisplayName(targetTopic),
      isBleedingHeavy: isBleeding,
      hasDeepWoundOrForeignBody: hasForeignBody,
      hasSignsOfInfection: hasPusOrInfection,
      painLevel: painLevel,
      secondaryInjuryTypeIds: secondaryTopics,
      secondaryInjuryTypeNames: secondaryNames,
    );
    super.onViewFirstAidGuidePressed();
  }

  @override
  void dispose() {
    disposeChat();
    disposeImageAnalysis();
    chatInputController.dispose();
    chatScrollController.dispose();
    documentSearchController.dispose();
    super.dispose();
  }
}
