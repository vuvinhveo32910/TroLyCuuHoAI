import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/gemini/gemini_service.dart';
import '../../../core/medgemma_chat_api.dart';
import '../../../core/rule_engine/rule_models.dart';
import '../models/chat_models.dart';
import 'analysis_result_viewmodel.dart';
import 'first_aid_viewmodel.dart';
import 'image_analysis_viewmodel.dart';
import 'user_navigation_viewmodel.dart';

mixin ChatBoxAiViewModel
    on
        DieuHuongCoSoViewModel,
        HuongDanSoCuuViewModel,
        KetQuaPhanTichViewModel,
        PhanTichAnhViewModel {
  // Bộ điều khiển nhập liệu và cuộn danh sách tin nhắn trên Màn hình 6: ChatBox AI
  final TextEditingController chatInputController = TextEditingController();
  final ScrollController chatScrollController = ScrollController();
  String _currentChatInput = '';
  String get currentChatInput => _currentChatInput;

  // Trạng thái AI đang suy nghĩ / chờ phản hồi từ API
  bool _isAiThinking = false;
  bool get isAiThinking => _isAiThinking;

  MedGemmaChatApi chatApi = MedGemmaChatApi();
  Timer? _statusTimer;
  bool _chatDisposed = false;
  bool _checkingStatus = false;
  String chatModelState = 'unknown';
  int chatReferenceCount = 0;
  String? _activeImageAnalysisId;
  bool _nextImageInitial = false;

  Future<void> refreshChatStatus() async {
    if (_chatDisposed || _checkingStatus) return;
    _checkingStatus = true;
    try {
      final value = await chatApi.status();
      if (_chatDisposed) return;
      chatModelState = value['model_state'] as String? ?? 'unknown';
      chatReferenceCount = (value['reference_entries'] as num?)?.toInt() ?? 0;
    } catch (_) {
      if (!_chatDisposed) chatModelState = 'offline';
    } finally {
      _checkingStatus = false;
      _statusTimer?.cancel();
      if (!_chatDisposed) {
        notifyListeners();
        if (_selectedChatModelId == 'medgemma' &&
            {'loading', 'generating'}.contains(chatModelState)) {
          _statusTimer = Timer(const Duration(seconds: 5), refreshChatStatus);
        }
      }
    }
  }

  Future<void> loadChatModel() async {
    if (_chatDisposed || _isAiThinking) return;
    try {
      await chatApi.warmup();
      await refreshChatStatus();
    } catch (_) {
      if (!_chatDisposed) {
        chatModelState = 'offline';
        notifyListeners();
      }
    }
  }

  void disposeChat() {
    _chatDisposed = true;
    _statusTimer?.cancel();
    chatApi.close();
  }

  // Lựa chọn Mô hình AI hiện tại (mặc định: 'gemini', tùy chọn: 'medgemma')
  String _selectedChatModelId = 'gemini';
  String get selectedChatModelId => _selectedChatModelId;

  List<ChatModelInfo> get availableChatModels => kDefaultChatModels;

  ChatModelInfo get currentChatModel => kDefaultChatModels.firstWhere(
    (m) => m.id == _selectedChatModelId,
    orElse: () => kDefaultChatModels.first,
  );

  /// Chuyển đổi mô hình AI (Google Gemini hoặc MedGemma)
  void switchChatModel(String modelId) {
    if (_chatDisposed ||
        _isAiThinking ||
        !kDefaultChatModels.any((model) => model.id == modelId)) {
      return;
    }
    if (_selectedChatModelId != modelId) {
      _selectedChatModelId = modelId;
      if (modelId == 'medgemma') unawaited(refreshChatStatus());
      notifyListeners();
    }
  }

  // Lịch sử tin nhắn hội thoại trên Màn hình 6
  final List<ChatMessageModel> _chatMessages = [];
  List<ChatMessageModel> get chatMessages => List.unmodifiable(_chatMessages);

  // Danh sách câu hỏi gợi ý nhanh tập trung vào 4 nhóm tổn thương chính & tình huống khẩn cấp
  final List<String> quickSuggestedQuestions = const [
    'Cách làm sạch và băng vết trầy xước té xe?',
    'Vết cắt sâu chảy máu nhiều thì cầm máu thế nào?',
    'Sơ cứu vết bỏng nước sôi / bỏng nhiệt đúng cách?',
    'Bầm tím phần mềm sưng to, nên chườm đá hay bôi dầu?',
    'Có dị vật thủy tinh đâm sâu vào da, xử lý sao?',
    'Dấu hiệu nào cho thấy vết thương bị nhiễm trùng?',
  ];

  // =========================================================================
  // LOGIC TƯƠNG TÁC CHATBOX AI (GEMINI & MEDGEMMA)
  // =========================================================================

  void updateChatInput(String value) {
    _currentChatInput = value;
  }

  /// Xóa toàn bộ lịch sử trò chuyện
  void clearChatHistory() {
    if (_chatDisposed || _isAiThinking) return;
    _activeImageAnalysisId = null;
    _nextImageInitial = false;
    _chatMessages.clear();
    _isAiThinking = false;
    notifyListeners();
  }

  /// Chuyển prompt kết quả phân tích ảnh sang ChatBox AI để AI tự động tư vấn
  void consultAiWithCurrentAnalysis() {
    if (_chatDisposed || _isAiThinking) return;

    // Hồ sơ sức khỏe cá nhân hóa của người dùng (Zero-Knowledge, không chứa PII tên/SĐT/địa chỉ)
    final healthProfileFull = currentUser?.buildAiHealthProfileSummary() ?? '';
    final healthProfileCompact =
        currentUser?.buildAiHealthProfileSummary(compact: true) ?? '';

    if (_selectedChatModelId == 'medgemma') {
      final prediction = lastWoundPrediction;
      final healthNote = healthProfileCompact.isNotEmpty
          ? ' Lưu ý hồ sơ bệnh nhân: $healthProfileCompact'
          : '';

      if (prediction != null &&
          prediction.analysisId == analysisResult.serverAnalysisId &&
          !analysisResult.isManualSelection) {
        _activeImageAnalysisId = prediction.analysisId;
        _nextImageInitial = true;
        navigateToChatBoxAi();
        unawaited(
          sendChatMessage(
            'Hãy giải thích dự đoán từ ảnh và tra tài liệu phù hợp cho bước tiếp theo.$healthNote',
          ),
        );
      } else {
        _activeImageAnalysisId = null;
        navigateToChatBoxAi();
        unawaited(
          sendChatMessage(
            analysisResult.isManualSelection
                ? 'Tôi chọn mô tả tổn thương là ${analysisResult.injuryType}. Tôi nên làm gì?$healthNote'
                : 'Tôi muốn hỏi về vết thương nhưng chưa có kết quả ảnh còn hiệu lực. Tôi cần mô tả thêm điều gì?$healthNote',
          ),
        );
      }
      return;
    }
    final location = selectedLocationLabel;

    // 1. Tóm tắt các tổn thương phát hiện (hỗ trợ trường hợp phát hiện 2-3 vết thương kết hợp trên ảnh)
    final String woundSummary = analysisResult.hasMultipleInjuries
        ? analysisResult.combinedInjurySummary
        : '${analysisResult.injuryType} (${analysisResult.confidencePercent}%)';

    final String multiWoundNotice = analysisResult.hasMultipleInjuries
        ? '\n- Ảnh có ${analysisResult.allDetections.length} tổn thương kết hợp: Hãy phân tích tương quan và hướng dẫn thứ tự ưu tiên xử lý từng vết thương theo chuẩn cấp cứu Triage (cầm máu vết thương hở trước, sau đó sát trùng vết trầy, che phủ vết bỏng).'
        : '';

    // 2. Mức độ cảm giác đau do người dùng gạt chọn (3 nấc)
    final String painLabel = painLevel.label;
    final String painNote = painLevel == PainLevel.severe
        ? ' (Bệnh nhân đang rất đau đớn dữ dội 7-10/10, cần ưu tiên hướng dẫn tư thế giảm đau an toàn và cảnh báo tổn thương mô sâu/gãy xương ngầm)'
        : (painLevel == PainLevel.none
              ? ' (Không đau hoặc mất cảm giác đau - lưu ý nếu là vết bỏng có thể đã tổn thương sâu làm chết ngọn dây thần kinh bì)'
              : ' (Đau nhẹ rát bề mặt thông thường)');

    // 3. Tổng hợp các tình trạng quan sát kèm theo từ checkbox của người dùng
    final List<String> observedSymptoms = [];
    if (isBleeding) {
      observedSymptoms.add(
        'Vết thương đang chảy máu (chảy nhiều hoặc liên tục)',
      );
    }
    if (hasForeignBody) {
      observedSymptoms.add(
        'Có dị vật cắm sâu vào vết thương (kim loại, dằm, thủy tinh...)',
      );
    }
    if (hasPusOrInfection) {
      observedSymptoms.add(
        'Vết thương chảy mủ / Sưng đỏ tấy (dấu hiệu nhiễm trùng)',
      );
    }

    final String symptomsText = observedSymptoms.isNotEmpty
        ? '\n- Dấu hiệu quan sát kèm theo: ${observedSymptoms.join('; ')}.'
        : '';

    // 4. Khối hồ sơ sức khỏe cá nhân hóa và chỉ thị AI chuyên biệt
    final String healthSection = healthProfileFull.isNotEmpty
        ? '\n\n$healthProfileFull\n\n'
          '⚠️ YÊU CẦU ĐẶC BIỆT DÀNH CHO AI:\n'
          '- Cá nhân hóa toàn bộ quy trình sơ cứu theo hồ sơ bệnh nhân ở trên.\n'
          '- Nếu bệnh nhân có Máu khó đông (Hemophilia): Nhấn mạnh băng ép trực tiếp liên tục không buông tay, cấm tuyệt đối Aspirin/NSAID và yêu cầu gọi 115 chuyển viện khẩn cấp.\n'
          '- Nếu bệnh nhân có Đái tháo đường: Nhắc nhở nguy cơ nhiễm trùng vi mạch âm ỉ, vết thương rất lâu lành và cần quy trình vô trùng nghiêm ngặt.\n'
          '- TUYỆT ĐỐI CHỐNG CHỈ ĐỊNH các chất/thuốc mà bệnh nhân dị ứng (ví dụ: không dùng cồn y tế nếu dị ứng cồn, không dùng Betadine nếu dị ứng Iodine, không khuyên bôi Penicillin nếu dị ứng kháng sinh).'
        : '';

    final prompt =
        'Tôi vừa quét ảnh phát hiện tổn thương: $woundSummary ở vị trí $location.$multiWoundNotice\n'
        '- Cảm giác đau hiện tại: $painLabel$painNote.$symptomsText$healthSection\n\n'
        'Hãy phân tích tình trạng vết thương, hướng dẫn quy trình sơ cứu từng bước rõ ràng theo thứ tự ưu tiên, '
        'cách giảm đau an toàn, những điều cấm kỵ tuyệt đối không được làm và dấu hiệu nguy hiểm cần đến bệnh viện ngay?';

    // 1. Chuyển sang màn hình ChatBox AI (Màn hình 5)
    navigateToChatBoxAi();

    // 2. Tự động gửi câu hỏi sang AI để phản hồi tức thì
    sendChatMessage(prompt);
  }

  void _scrollToLatestMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatDisposed && chatScrollController.hasClients) {
        chatScrollController.animateTo(
          chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// Gửi tin nhắn tới Mô hình AI được chọn (Gemini API hoặc MedGemma Server)
  Future<void> sendChatMessage([String? submittedText, int? guideId]) async {
    final rawText = (submittedText ?? chatInputController.text).trim();
    if (_chatDisposed || rawText.isEmpty || _isAiThinking) return;
    final requestModel = _selectedChatModelId;
    final imageInitial = _nextImageInitial;
    _nextImageInitial = false;

    final now = DateTime.now();
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Thêm tin nhắn của người dùng vào giao diện
    _chatMessages.add(
      ChatMessageModel(
        id: 'user_${now.microsecondsSinceEpoch}',
        isUser: true,
        messageText: rawText,
        timestamp: formattedTime,
      ),
    );

    chatInputController.clear();
    _currentChatInput = '';
    _isAiThinking = true;
    notifyListeners();
    _scrollToLatestMessage();

    try {
      if (requestModel == 'medgemma') {
        final reply = await chatApi.ask(
          rawText,
          guideId: guideId,
          imageAnalysisId: _activeImageAnalysisId,
          imageInitial: imageInitial,
        );
        if (!_chatDisposed) _chatMessages.add(reply);
        return;
      }
      // Chuẩn bị ngữ cảnh vết thương (nếu bệnh nhân vừa thực hiện quét ảnh AI trước đó)
      String? woundContext;
      if (analysisResult.isDetected) {
        final List<String> symptoms = [];
        symptoms.add('Cảm giác đau: ${painLevel.label}');
        if (isBleeding) symptoms.add('đang chảy máu nhiều/liên tục');
        if (hasForeignBody) symptoms.add('có dị vật cắm sâu vào vết thương');
        if (hasPusOrInfection) {
          symptoms.add('chảy mủ hoặc sưng đỏ tấy (dấu hiệu nhiễm trùng)');
        }
        final symptomsInfo = ' [${symptoms.join(', ')}]';

        final woundDesc = analysisResult.hasMultipleInjuries
            ? analysisResult.combinedInjurySummary
            : '${analysisResult.injuryType} (${analysisResult.confidencePercent}%)';

        woundContext =
            'Bệnh nhân vừa quét ảnh phát hiện: $woundDesc tại vị trí $selectedLocationLabel.$symptomsInfo';
      }

      // Tự động bổ sung hồ sơ sức khỏe cá nhân hóa vào ngữ cảnh nếu có và chưa xuất hiện trong rawText
      final userHealthSummary = currentUser?.buildAiHealthProfileSummary() ?? '';
      if (userHealthSummary.isNotEmpty && !rawText.contains('[HỒ SƠ SỨC KHỎE BỆNH NHÂN')) {
        if (woundContext != null && woundContext.isNotEmpty) {
          woundContext = '$woundContext\n\n$userHealthSummary';
        } else {
          woundContext = userHealthSummary;
        }
      }

      // Chuẩn bị danh sách lịch sử hội thoại
      final conversationHistory = _chatMessages
          .map(
            (m) => {'role': m.isUser ? 'user' : 'model', 'text': m.messageText},
          )
          .toList();

      String replyText;

      // Google Gemini keeps its existing API and configuration.
      replyText = await GeminiService.instance.sendChatMessage(
        conversationHistory: conversationHistory,
        userMessage: rawText,
        woundContext: woundContext,
      );
      if (_chatDisposed) return;

      final replyNow = DateTime.now();
      final replyTime =
          '${replyNow.hour.toString().padLeft(2, '0')}:${replyNow.minute.toString().padLeft(2, '0')}';

      _chatMessages.add(
        ChatMessageModel(
          id: 'ai_${replyNow.microsecondsSinceEpoch}',
          isUser: false,
          messageText: replyText,
          timestamp: replyTime,
          modelSource: requestModel,
        ),
      );
    } catch (e) {
      if (_chatDisposed) return;
      final replyNow = DateTime.now();
      final replyTime =
          '${replyNow.hour.toString().padLeft(2, '0')}:${replyNow.minute.toString().padLeft(2, '0')}';

      _chatMessages.add(
        ChatMessageModel(
          id: 'ai_${replyNow.microsecondsSinceEpoch}',
          isUser: false,
          modelSource: requestModel,
          messageText:
              '⚠️ Đã xảy ra lỗi khi kết nối với mô hình AI: $e\n\nVui lòng kiểm tra lại kết nối mạng hoặc thử lại sau ít phút.',
          timestamp: replyTime,
        ),
      );
    } finally {
      if (!_chatDisposed) {
        _isAiThinking = false;
        notifyListeners();
        _scrollToLatestMessage();
        if (requestModel == 'medgemma') unawaited(refreshChatStatus());
      }
    }
  }
}
