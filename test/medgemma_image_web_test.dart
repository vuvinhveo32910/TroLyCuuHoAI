import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:do_an_cntt_11/core/medgemma_chat_api.dart';

void main() {
  final baseUrl = Uri.parse('http://127.0.0.1:8080/');
  final imageBytes = Uint8List.fromList([1, 2, 3]);

  test('web image scan waits past the old three-second limit', () async {
    final api = MedGemmaChatApi(
      baseUrl: baseUrl,
      client: MockClient((request) async {
        expect(request.url.path, '/api/analyze-image');
        await Future<void>.delayed(const Duration(seconds: 4));
        return http.Response(
          jsonEncode({
            'analysis_id': 'cold_scan_example_1234',
            'status': 'no_detection',
            'detections': [],
            'image_width': 32,
            'image_height': 32,
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);

    final prediction = await api.analyzeImage(imageBytes);
    expect(prediction.status, 'no_detection');
  }, skip: !kIsWeb);

  test('web image scan keeps the server validation error', () async {
    const message = 'Ảnh gửi lên không đọc được.';
    final api = MedGemmaChatApi(
      baseUrl: baseUrl,
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({'error': message}),
          415,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    addTearDown(api.close);

    await expectLater(
      api.analyzeImage(imageBytes),
      throwsA(
        isA<ChatApiException>().having(
          (error) => error.message,
          'message',
          message,
        ),
      ),
    );
  }, skip: !kIsWeb);
}
