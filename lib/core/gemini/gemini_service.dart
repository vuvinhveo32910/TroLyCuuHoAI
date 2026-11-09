import '../supabase/supabase_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'gemini_config_model.dart';

/// Kết quả kiểm tra kết nối Gemini API
class GeminiTestResult {
  final bool isSuccess;
  final String message;
  final int? statusCode;
  final int? latencyMs;

  const GeminiTestResult({
    required this.isSuccess,
    required this.message,
    this.statusCode,
    this.latencyMs,
  });
}

/// Dịch vụ kết nối và xử lý gọi Google Gemini API
class GeminiService {
  GeminiService._internal() {
    fetchConfigFromSupabase();
  }
  static final GeminiService instance = GeminiService._internal();

  GeminiConfigModel _config = const GeminiConfigModel();
  GeminiConfigModel get config => _config;

  /// Nạp cấu hình Gemini từ bảng 'system_configurations' trên Supabase
  Future<void> fetchConfigFromSupabase() async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;
      final data = await client
          .from('system_configurations')
          .select()
          .eq('id', 'app_settings')
          .maybeSingle();

      if (data != null) {
        _config = _config.copyWith(
          apiKey: data['gemini_api_key'] as String? ?? _config.apiKey,
          isEnabled: data['gemini_enabled'] as bool? ?? _config.isEnabled,
          systemInstruction: data['gemini_system_prompt'] as String? ?? _config.systemInstruction,
          maxTokens: (data['gemini_max_tokens'] as int? ?? 4096) < 2048
              ? 4096
              : (data['gemini_max_tokens'] as int),
        );
      }
    } catch (e) {
      debugPrint('[GeminiService] Nạp cấu hình Gemini từ Supabase: $e');
    }
  }

  /// Cập nhật cấu hình Gemini và đồng bộ lên Supabase
  Future<void> updateConfig(GeminiConfigModel newConfig) async {
    _config = newConfig;
    debugPrint('[GeminiService] Đã cập nhật cấu hình: Model=${newConfig.selectedModel}, Enabled=${newConfig.isEnabled}, HasKey=${newConfig.hasValidApiKey}');

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client.from('system_configurations').upsert({
          'id': 'app_settings',
          'gemini_api_key': newConfig.apiKey,
          'gemini_enabled': newConfig.isEnabled,
          'gemini_system_prompt': newConfig.systemInstruction,
          'gemini_max_tokens': newConfig.maxTokens,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('[GeminiService] Lỗi đồng bộ cấu hình Gemini lên Supabase: $e');
    }
  }

  /// Kiểm tra tính hợp lệ và kết nối tới Google Gemini API
  Future<GeminiTestResult> testApiKey({
    required String apiKey,
    String model = 'gemini-3.8-flash',
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return const GeminiTestResult(
        isSuccess: false,
        message: 'Khóa API Gemini chưa được nhập. Vui lòng dán khóa API từ Google AI Studio.',
      );
    }

    // Danh sách model thử nghiệm nếu model chính bị 503 (quá tải) hoặc mã lỗi không tồn tại
    final candidateModels = <String>[
      model,
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-flash-8b',
      'gemini-3.8-flash',
      'gemini-3.6-flash',
      'gemini-flash-latest',
    ];
    final uniqueModels = <String>[];
    for (final m in candidateModels) {
      if (!uniqueModels.contains(m)) uniqueModels.add(m);
    }

    final stopwatch = Stopwatch()..start();
    String lastError = '';
    int? lastStatus;

    for (final candidate in uniqueModels) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$candidate:generateContent?key=$cleanKey',
      );

      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'role': 'user',
                    'parts': [
                      {'text': 'Xin chào, bạn có hoạt động không? Trả lời ngắn gọn: Sẵn sàng.'}
                    ]
                  }
                ],
                'generationConfig': {
                  'temperature': 0.2,
                  'maxOutputTokens': 50,
                },
              }),
            )
            .timeout(const Duration(seconds: 12));

        lastStatus = response.statusCode;

        if (response.statusCode == 200) {
          stopwatch.stop();
          final latency = stopwatch.elapsedMilliseconds;
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            return GeminiTestResult(
              isSuccess: true,
              message: 'Kết nối thành công tới Gemini Flash API! Độ trễ phản hồi: ${latency}ms.',
              statusCode: 200,
              latencyMs: latency,
            );
          }
        } else if (response.statusCode == 503 || response.statusCode == 429 || response.statusCode == 404) {
          debugPrint('[GeminiService.testApiKey] Model $candidate trả về ${response.statusCode}, thử tiếp candidate...');
          continue;
        } else {
          String detailMessage = 'Lỗi HTTP ${response.statusCode}';
          try {
            final errorData = jsonDecode(response.body);
            if (errorData['error'] != null && errorData['error']['message'] != null) {
              detailMessage = errorData['error']['message'];
              final msg = detailMessage.toLowerCase();
              if (msg.contains('not found') || msg.contains('model') || msg.contains('unsupported') || msg.contains('unknown')) {
                continue;
              }
            }
          } catch (_) {}
          lastError = detailMessage;
          if (response.statusCode == 400 && !detailMessage.toLowerCase().contains('api key') && !detailMessage.toLowerCase().contains('api_key')) {
            continue;
          }
          break;
        }
      } catch (e) {
        debugPrint('[GeminiService.testApiKey] Ngoại lệ khi thử $candidate: $e');
        continue;
      }
    }

    stopwatch.stop();
    if (lastStatus == 400) {
      return GeminiTestResult(
        isSuccess: false,
        message: 'Khóa API không hợp lệ: $lastError',
        statusCode: 400,
      );
    } else if (lastStatus == 403) {
      return GeminiTestResult(
        isSuccess: false,
        message: 'Truy cập bị từ chối: Khóa API chưa kích hoạt Generative Language API hoặc bị giới hạn vùng/IP.',
        statusCode: 403,
      );
    }

    return GeminiTestResult(
      isSuccess: false,
      message: 'Không thể kết nối tới Google Gemini ($lastStatus): ${lastError.isNotEmpty ? lastError : "Máy chủ Google tạm thời quá tải hoặc kết nối mạng không ổn định"}',
      statusCode: lastStatus,
    );
  }

  /// Gửi tin nhắn tới Google Gemini API kèm lịch sử hội thoại
  Future<String> sendChatMessage({
    required List<Map<String, String>> conversationHistory,
    required String userMessage,
    String? woundContext,
  }) async {
    // Nếu Gemini chưa được bật hoặc chưa nhập API Key -> Trả về câu trả lời y khoa dự phòng
    if (!_config.isEnabled || !_config.hasValidApiKey) {
      return _generateOfflineFallback(userMessage, woundContext);
    }

    final cleanKey = _config.apiKey.trim();

    // Chuẩn bị contents gửi lên Gemini
    final List<Map<String, dynamic>> contents = [];

    // Chỉ lấy lịch sử hội thoại trước đó (loại trừ tin nhắn hiện tại nếu đã có trong danh sách)
    final pastHistory = conversationHistory.isNotEmpty &&
            conversationHistory.last['text'] == userMessage
        ? conversationHistory.sublist(0, conversationHistory.length - 1)
        : conversationHistory;

    // Giới hạn 6 tin nhắn gần nhất để đảm bảo luân phiên hợp lệ
    final recentHistory = pastHistory.length > 6
        ? pastHistory.sublist(pastHistory.length - 6)
        : pastHistory;

    for (final item in recentHistory) {
      final role = item['role'] == 'user' ? 'user' : 'model';
      final text = item['text'] ?? '';
      if (text.trim().isNotEmpty) {
        // Đảm bảo không có 2 lượt liên tiếp cùng 1 role
        if (contents.isNotEmpty && contents.last['role'] == role) {
          continue;
        }
        contents.add({
          'role': role,
          'parts': [{'text': text}],
        });
      }
    }

    // Đảm bảo lượt trước đó không phải là 'user' để lượt cuối cùng dưới đây hợp lệ
    if (contents.isNotEmpty && contents.last['role'] == 'user') {
      contents.removeLast();
    }

    // Ghép ngữ cảnh vết thương & hồ sơ y tế bệnh nhân (nếu có từ phân tích ảnh hoặc thông tin cá nhân)
    String effectiveUserMessage = userMessage;
    if (woundContext != null && woundContext.isNotEmpty) {
      effectiveUserMessage =
          '[Ngữ cảnh y tế & Hồ sơ bệnh nhân:\n$woundContext]\n\nCâu hỏi: $userMessage';
    }

    contents.add({
      'role': 'user',
      'parts': [{'text': effectiveUserMessage}],
    });

    // Danh sách các model ứng viên theo thứ tự ưu tiên:
    // Tự động failover thông minh nếu Google trả về 503 (quá tải), 429 (hạn mức) hoặc 404/400 (chưa hỗ trợ model ID)
    final candidateModels = <String>[
      _config.selectedModel,
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-flash-8b',
      'gemini-3.8-flash',
      'gemini-3.6-flash',
      'gemini-flash-latest',
    ];
    final uniqueCandidates = <String>[];
    for (final m in candidateModels) {
      if (m.trim().isNotEmpty && !uniqueCandidates.contains(m.trim())) {
        uniqueCandidates.add(m.trim());
      }
    }

    int? lastErrorCode;
    String lastErrorMessage = '';

    for (final modelName in uniqueCandidates) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$cleanKey',
      );

      try {
        final payload = {
          'system_instruction': {
            'parts': [
              {'text': _config.systemInstruction}
            ]
          },
          'contents': contents,
          'generationConfig': {
            'temperature': _config.temperature,
            'maxOutputTokens': _config.maxTokens < 2048 ? 4096 : _config.maxTokens,
            'topP': 0.95,
            'topK': 40,
            'thinkingConfig': {
              'thinkingBudget': 0,
            },
          },
        };

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 22));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            if (content != null && content['parts'] != null) {
              final parts = content['parts'] as List;
              final textBuffer = StringBuffer();
              for (final part in parts) {
                if (part['text'] != null && part['thought'] != true) {
                  textBuffer.write(part['text']);
                }
              }
              final reply = textBuffer.toString().trim();
              if (reply.isNotEmpty) {
                debugPrint('[GeminiService] Phản hồi thành công từ model: $modelName');
                return reply;
              }
            }
          }
          return 'Mô hình Gemini không tạo được câu trả lời phù hợp. Bạn hãy thử diễn đạt lại câu hỏi về tình trạng vết thương nhé.';
        } else {
          lastErrorCode = response.statusCode;
          debugPrint('[GeminiService] Model $modelName trả về mã ${response.statusCode}: ${response.body}');

          // 503 (Overloaded) hoặc 429 (Rate limit) hoặc 404 -> Thử model candidate kế tiếp
          if (response.statusCode == 503 || response.statusCode == 429 || response.statusCode == 404) {
            continue;
          }

          // Kiểm tra lỗi chi tiết từ Google
          try {
            final errorData = jsonDecode(response.body);
            if (errorData['error'] != null && errorData['error']['message'] != null) {
              lastErrorMessage = errorData['error']['message'];
              final msg = lastErrorMessage.toLowerCase();
              if (msg.contains('not found') || msg.contains('model') || msg.contains('unsupported') || msg.contains('unknown')) {
                continue;
              }
            }
          } catch (_) {}

          if (response.statusCode == 400 && !lastErrorMessage.toLowerCase().contains('api key') && !lastErrorMessage.toLowerCase().contains('api_key')) {
            continue;
          }
          break;
        }
      } catch (e) {
        debugPrint('[GeminiService] Ngoại lệ khi gọi model $modelName: $e');
        continue;
      }
    }

    final String noticeCode = lastErrorCode != null ? 'Mã $lastErrorCode' : 'Gián đoạn kết nối';
    final String extraNotice = lastErrorMessage.isNotEmpty ? ' - $lastErrorMessage' : '';

    return _generateOfflineFallback(
      userMessage,
      woundContext,
      prefixNotice: '*(Lưu ý: Không thể kết nối Gemini API [$noticeCode$extraNotice]. Trợ lý đang cung cấp hướng dẫn sơ cứu chuẩn y tế ngoại tuyến)*\n\n',
    );
  }

  /// Câu trả lời y tế lâm sàng ngoại tuyến dự phòng khi chưa cấu hình Gemini API Key
  String _generateOfflineFallback(
    String userQuestion,
    String? woundContext, {
    String prefixNotice = '',
  }) {
    final q = userQuestion.toLowerCase();

    if (q.contains('bỏng') || q.contains('phỏng') || q.contains('nước sôi') || q.contains('bô xe')) {
      return '$prefixNotice'
          '### 🩹 HƯỚNG DẪN CÁC BƯỚC SƠ CỨU BỎNG NHIỆT / NƯỚC SÔI:\n\n'
          '**1. Bước 1: Làm mát ngay lập tức**\n'
          '• Xả vùng da bị bỏng dưới vòi nước sạch mát (15 - 25°C) liên tục trong **15 - 20 phút** để hạ nhiệt độ mô sâu.\n\n'
          '**2. Bước 2: Tháo vật dụng chèn ép**\n'
          '• Nhẹ nhàng tháo nhẫn, đồng hồ, vòng tay trước khi vùng bỏng bị sưng phù nề.\n\n'
          '**3. Bước 3: Bảo vệ vết bỏng**\n'
          '• Dùng gạc vô trùng ẩm hoặc màng bọc thực phẩm sạch che phủ nhẹ nhàng lên vết bỏng.\n\n'
          '⚠️ **NHỮNG ĐIỀU TUYỆT ĐỐI KHÔNG ĐƯỢC LÀM:**\n'
          '• **KHÔNG** chườm đá lạnh trực tiếp (gây bỏng lạnh hoại tử da).\n'
          '• **KHÔNG** bôi kem đánh răng, mỡ trăn, nước mắm hay lòng đỏ trứng.\n'
          '• **KHÔNG** chọc vỡ các bọng nước phồng rộp.\n\n'
          '🚨 **ĐẾN BỆNH VIỆN NGAY NẾU:** Bỏng lớn hơn lòng bàn tay, bỏng ở vùng mặt, mắt, bàn tay, hoặc do hóa chất, điện giật.';
    }

    if (q.contains('cắt') || q.contains('rách') || q.contains('chảy máu') || q.contains('đứt tay')) {
      return '$prefixNotice'
          '### 🩹 HƯỚNG DẪN CẦM MÁU VÀ XỬ LÝ VẾT CẮT / VẾT RÁCH DA:\n\n'
          '**1. Bước 1: Cầm máu bằng ấn ép trực tiếp**\n'
          '• Đặt một miếng gạc vô trùng hoặc khăn sạch ép trực tiếp và liên tục lên miệng vết thương trong **10 - 15 phút**.\n'
          '• Nâng cao vùng chi bị thương cao hơn tim nếu có thể.\n\n'
          '**2. Bước 2: Làm sạch và sát khuẩn**\n'
          '• Rửa trôi đất cát xung quanh bằng nước muối sinh lý 0.9% hoặc nước sạch.\n'
          '• Sát khuẩn mép vết thương bằng dung dịch Povidone-Iodine 10%.\n\n'
          '**3. Bước 3: Băng bảo vệ**\n'
          '• Khép hai mép vết rách lại và dùng băng cuộn hoặc băng cá nhân cố định vừa phải.\n\n'
          '⚠️ **ĐIỀU CẤM KỴ:**\n'
          '• Không đắp thuốc lá, bột cà phê, tro than hay lá cây lên vết thương hở.\n'
          '• Không liên tục mở gạc ra xem trong lúc đang ấn ép cầm máu.\n\n'
          '🚨 **CẦN ĐẾN CƠ SỞ Y TẾ NẾU:** Chảy máu phun thành tia, máu thấm ướt nhiều lớp gạc không cầm sau 15 phút, vết cắt sâu > 0.5cm (cần khâu trong 6 giờ đầu) hoặc cần tiêm phòng uốn ván.';
    }

    if (q.contains('trầy') || q.contains('xước') || q.contains('té xe') || q.contains('ngã')) {
      return '$prefixNotice'
          '### 🩹 HƯỚNG DẪN CÁC BƯỚC XỬ LÝ VẾT TRẦY XƯỚC NGOÀI DA:\n\n'
          '**1. Bước 1: Rửa sạch tay và vết thương**\n'
          '• Rửa tay với xà phòng. Xả nhẹ nước sạch hoặc nước muối sinh lý 0.9% để rửa trôi toàn bộ đất cát, bụi bẩn dính trên vết trầy.\n\n'
          '**2. Bước 2: Sát khuẩn vết thương**\n'
          '• Thấm nhẹ gạc vô trùng quanh vết thương, thoa dung dịch sát khuẩn Povidone-Iodine 10% để tiêu diệt vi khuẩn.\n\n'
          '**3. Bước 3: Băng bảo vệ**\n'
          '• Nếu vết trầy nhỏ, có thể để thoáng cho khô tự nhiên. Nếu vết rộng hoặc dễ cọ xát với quần áo, hãy dán băng gạc thoáng khí và thay băng mỗi ngày.\n\n'
          '⚠️ **LƯU Ý:** Không dùng cồn 90 độ đổ trực tiếp vào miệng vết thương hở (sẽ phá hủy tế bào mô lành). Tiêm ngừa uốn ván nếu té xe ngoài đường dính đất bẩn.';
    }

    if (q.contains('bầm') || q.contains('tím') || q.contains('va quẹt') || q.contains('sưng')) {
      return '$prefixNotice'
          '### 🩹 QUY TRÌNH 4 BƯỚC R.I.C.E XỬ LÝ BẦM TÍM & CHẤN THƯƠNG PHẦN MỀM:\n\n'
          '*(R.I.C.E là quy trình 4 bước chuẩn gồm: Nghỉ ngơi - Chườm lạnh - Băng ép - Kê cao)*\n\n'
          '**1. R - Rest (Nghỉ ngơi):** Hạn chế vận động vùng chi đang bị bầm tím đau nhức.\n'
          '**2. I - Ice (Chườm lạnh):** Bọc túi đá trong khăn bông sạch, chườm lên vùng bầm 15 - 20 phút/lần (3-4 lần/ngày trong **48 giờ đầu**) để co mạch máu ngầm, giảm xuất huyết và bớt sưng đau.\n'
          '**3. C - Compression (Băng ép):** Quấn băng thun đàn hồi nhẹ quanh vùng chấn thương để hạn chế phù nề (không quấn quá chặt gây tê tím đầu ngón).\n'
          '**4. E - Elevation (Kê cao):** Kê cao vùng chi bị thương cao hơn mức tim khi nằm nghỉ.\n\n'
          '⚠️ **ĐIỀU TUYỆT ĐỐI KHÔNG LÀM:**\n'
          '• **KHÔNG** xoa bóp dầu nóng, cao dán hoặc uống rượu thuốc trong 48 giờ đầu (nhiệt nóng làm giãn mạch máu khiến vết bầm lan rộng hơn).\n\n'
          '🚨 **ĐI CHỤP X-QUANG NẾU:** Đau chói dữ dội, biến dạng khớp, không cử động được chi (nghi ngờ gãy xương).';
    }

    if (q.contains('dị vật') || q.contains('thủy tinh') || q.contains('que') || q.contains('đinh')) {
      return '$prefixNotice'
          '### 🚨 NGUYÊN TẮC VÀNG KHI CÓ DỊ VẬT CẮM VÀO VẾT THƯƠNG:\n\n'
          '🔴 **TUYỆT ĐỐI KHÔNG TỰ Ý RÚT DỊ VẬT RA!**\n'
          '• Dị vật đang đóng vai trò nút chặn cầm máu tạm thời. Rút dị vật ra tại chỗ có thể gây đứt mạch máu ngầm và xuất huyết dữ dội nguy hiểm tính mạng!\n\n'
          '**CÁC BƯỚC XỬ LÝ:**\n'
          '1. Giữ nguyên dị vật tại vị trí cũ.\n'
          '2. Dùng hai cuộn băng hoặc khăn sạch chèn chặt hai bên dị vật để cố định không cho xê dịch.\n'
          '3. Băng vòng xung quanh để giữ dị vật đứng yên.\n'
          '4. Đưa nạn nhân đến phòng cấp cứu gần nhất để bác sĩ phẫu thuật lấy dị vật và tiêm phòng uốn ván.';
    }

    return '$prefixNotice'
        'Xin chào! Tôi là Trợ Lý Cứu Hộ Y Tế AI.\n\n'
        'Tôi có thể hướng dẫn bạn các bước sơ cứu chuẩn y tế cho 4 nhóm thương tổn ngoài da:\n'
        '• 🩹 **Trầy xước da:** Rửa sạch, sát trùng, chống sẹo thâm.\n'
        '• ✂️ **Vết cắt / rách:** Kỹ thuật ấn ép cầm máu, khâu thẩm mỹ.\n'
        '• 🔥 **Bỏng nhiệt / nước sôi:** Làm mát hạ nhiệt, chăm sóc bọng nước.\n'
        '• 🟣 **Bầm tím phần mềm:** Quy trình chườm lạnh 4 bước R.I.C.E.\n'
        '• ⚠️ **Dị vật / Chảy máu nặng:** Cố định dị vật và chuyển viện cấp cứu.\n\n';
  }
}
