import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../features/user/models/chat_models.dart';
import 'wound_prediction.dart';
import 'yolo/offline_yolo_predictor.dart';

class ChatApiException implements Exception {
  final String message;
  const ChatApiException(this.message);
  @override
  String toString() => message;
}

class MedGemmaChatApi {
  final http.Client _client;
  final Uri baseUrl;
  final Duration timeout;
  MedGemmaChatApi({
    http.Client? client,
    Uri? baseUrl,
    this.timeout = const Duration(seconds: 310),
  }) : _client = client ?? http.Client(),
       baseUrl = baseUrl ?? defaultBaseUrl();

  static Uri defaultBaseUrl() {
    const configured = String.fromEnvironment('MEDGEMMA_API_BASE_URL');
    final value = configured.isNotEmpty
        ? configured
        : (kIsWeb && !{'localhost', '127.0.0.1'}.contains(Uri.base.host)
              ? Uri.base.origin
              : 'http://127.0.0.1:8765');
    return resolveBaseUrl(value, Uri.base);
  }

  static Uri resolveBaseUrl(String value, Uri page) {
    final uri = page.resolve(value.endsWith('/') ? value : '$value/');
    if (!{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      throw ArgumentError('Invalid MedGemma API URL');
    }
    return uri;
  }

  Uri endpoint(String path) => baseUrl.resolve(path);

  Future<Map<String, dynamic>> _request(
    String path, {
    Map<String, dynamic>? body,
    Duration? requestTimeout,
  }) async {
    try {
      final uri = endpoint(path);
      final response =
          await (body == null
                  ? _client.get(uri)
                  : _client.post(
                      uri,
                      headers: {
                        'Content-Type': 'application/json; charset=utf-8',
                      },
                      body: jsonEncode(body),
                    ))
              .timeout(requestTimeout ?? timeout);
      if (response.statusCode != 200) {
        if ({400, 410, 413, 415}.contains(response.statusCode)) {
          final error = jsonDecode(utf8.decode(response.bodyBytes));
          if (error is Map && error['error'] is String) {
            throw ChatApiException(error['error'] as String);
          }
        }
        if (response.statusCode == 429) {
          throw const ChatApiException(
            'AI đang nạp hoặc xử lý câu khác. Hãy đợi rồi thử lại.',
          );
        }
        if (response.statusCode == 422) {
          throw const ChatApiException(
            'AI chưa hoàn tất câu trả lời. Bạn có thể thử lại.',
          );
        }
        if (response.statusCode == 403) {
          throw const ChatApiException(
            'Dịch vụ chưa cho phép web này kết nối. Hãy kiểm tra cấu hình kết nối.',
          );
        }
        throw const ChatApiException(
          'Dịch vụ AI chưa xử lý được yêu cầu. Hãy kiểm tra trạng thái rồi thử lại.',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return decoded;
    } on ChatApiException {
      rethrow;
    } on TimeoutException {
      throw const ChatApiException(
        'Chờ AI quá lâu. Yêu cầu trước có thể vẫn đang xử lý; hãy đợi rồi thử lại.',
      );
    } on FormatException {
      throw const ChatApiException(
        'Dịch vụ trả về dữ liệu chưa hợp lệ. Hãy thử kết nối lại.',
      );
    } on http.ClientException {
      throw const ChatApiException(
        'Chưa kết nối được dịch vụ chat AI. Hãy khởi động dịch vụ rồi thử lại.',
      );
    } catch (_) {
      throw const ChatApiException(
        'Kết nối chat AI bị gián đoạn. Hãy kiểm tra dịch vụ rồi thử lại.',
      );
    }
  }

  Future<Map<String, dynamic>> status() =>
      _request('api/status', requestTimeout: const Duration(seconds: 10));
  Future<void> warmup() async {
    await _request(
      'api/warmup',
      body: {},
      requestTimeout: const Duration(seconds: 10),
    );
  }

  Future<WoundImagePrediction> analyzeImage(
    Uint8List bytes, {
    double contrast = 1,
    Map<String, bool> observations = const {},
  }) async {
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const ChatApiException(
        'Hãy chọn ảnh có dung lượng từ 1 byte đến 10 MB.',
      );
    }

    try {
      final value = await _request(
        'api/analyze-image',
        body: {
          'image_base64': base64Encode(bytes),
          'contrast': contrast,
          if (observations.isNotEmpty) 'observations': observations,
        },
        // Web needs to wait for the server to load YOLO on the first scan.
        requestTimeout: const Duration(seconds: kIsWeb ? 60 : 3),
      );
      return WoundImagePrediction.fromJson(value);
    } on ChatApiException {
      if (kIsWeb) rethrow;
    } catch (_) {
      if (kIsWeb) {
        throw const ChatApiException(
          'Server trả về kết quả nhận diện chưa hợp lệ. Hãy thử lại.',
        );
      }
    }

    // Desktop can run the local predictor when the server request fails.
    debugPrint('[MedGemmaChatApi] Nhận diện vết thương bằng mô hình offline duy nhất: lib/AI_Model/best.pt...');
    final offlinePrediction = await OfflineYoloPredictor.predictOffline(
      bytes,
      contrast: contrast,
    );
    if (offlinePrediction != null) {
      return offlinePrediction;
    }

    throw const ChatApiException(
      'Không thể nhận diện hình ảnh bằng mô hình best.pt. Vui lòng kiểm tra Python trên máy.',
    );
  }

  Future<ChatMessageModel> ask(
    String question, {
    int? guideId,
    String? imageAnalysisId,
    bool imageInitial = false,
  }) async {
    final value = await _request(
      'api/chat',
      body: {
        'message': question,
        'mode': 'grounded',
        'guide_id': ?guideId,
        'image_analysis_id': ?imageAnalysisId,
        if (imageInitial) 'image_initial': true,
      },
    );
    if (value['answer'] is! String ||
        (value['answer'] as String).trim().isEmpty ||
        value['truncated'] == true) {
      throw const ChatApiException(
        'AI chưa tạo được câu trả lời hoàn chỉnh. Hãy thử lại.',
      );
    }
    final citations = <ChatCitation>[];
    if (value['citations'] is List) {
      for (final source in value['citations'] as List) {
        if (source is! Map || source['pdf_url'] is! String) continue;
        final uri = endpoint(source['pdf_url'] as String);
        if (!{'http', 'https'}.contains(uri.scheme) ||
            uri.origin != baseUrl.origin ||
            !uri.path.startsWith('/api/source/')) {
          continue;
        }
        citations.add(
          ChatCitation(
            title: '${source['title'] ?? 'Nguồn tài liệu'}',
            pages: '${source['pages'] ?? ''}',
            url: uri,
          ),
        );
      }
    }
    final options = <ChatGuideOption>[];
    if (value['route'] == 'clarify' && value['guides'] is List) {
      for (final guide in value['guides'] as List) {
        if (guide is Map && guide['id'] is int && guide['title'] is String) {
          options.add(
            ChatGuideOption(
              id: guide['id'] as int,
              title: guide['title'] as String,
            ),
          );
        }
      }
    }
    final now = DateTime.now();
    return ChatMessageModel(
      id: 'ai_${now.microsecondsSinceEpoch}',
      isUser: false,
      modelSource: citations.isNotEmpty
          ? 'sqlite'
          : (value['route'] == 'conversation' ? 'app' : 'medgemma'),
      messageText: value['answer'] as String,
      timestamp:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      evidenceLabel:
          value['source_review_label'] as String? ??
          (value['evidence_mode'] == 'model_only'
              ? 'AI trả lời — chưa đối chiếu nguồn'
              : ''),
      notice: value['fallback_notice'] as String? ?? '',
      citations: citations,
      guideOptions: options,
      originalQuestion: question,
      suggestedQuery: (value['query_interpretation'] is Map)
          ? value['query_interpretation']['suggested_query'] as String?
          : null,
      elapsedSeconds: (value['elapsed_seconds'] as num?)?.toDouble(),
    );
  }

  void close() => _client.close();
}
