import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:do_an_cntt_11/core/medgemma_chat_api.dart';
import 'package:do_an_cntt_11/core/wound_prediction.dart';
import 'package:do_an_cntt_11/features/user/viewmodels/user_viewmodel.dart';
import 'package:do_an_cntt_11/features/user/views/chat_view.dart';

http.Response ready() => http.Response(
  jsonEncode({'model_state': 'ready', 'reference_entries': 21}),
  200,
);

http.Response reply({bool source = false}) => http.Response(
  jsonEncode({
    'answer': 'Nội dung kiểm tra kết nối.',
    'truncated': false,
    'route': source ? 'source_grounded' : 'model_fallback',
    'evidence_mode': source ? 'source_demo' : 'model_only',
    'source_review_label': source
        ? 'Đối chiếu nguồn — chưa duyệt chuyên môn'
        : 'AI chưa đối chiếu nguồn',
    'elapsed_seconds': 0.2,
    'citations': source
        ? [
            {
              'title': 'Tài liệu nguồn',
              'pages': '2–3',
              'pdf_url': '/api/source/example',
            },
          ]
        : [],
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

UserViewModel viewModel(MockClient client) {
  final vm = UserViewModel();
  vm.chatApi.close();
  vm.chatApi = MedGemmaChatApi(
    client: client,
    baseUrl: Uri.parse('http://192.168.1.42:8080/'),
  );
  return vm;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('relative API address follows the server on localhost and LAN', () {
    for (final host in ['127.0.0.1', '192.168.1.42']) {
      final base = MedGemmaChatApi.resolveBaseUrl(
        '/',
        Uri.parse('http://$host:8080/'),
      );
      expect(base.resolve('api/chat').toString(), 'http://$host:8080/api/chat');
    }
    expect(
      () => MedGemmaChatApi.resolveBaseUrl('file:///private/', Uri.base),
      throwsArgumentError,
    );
  });

  test(
    'Gemini remains selectable and MedGemma sends to the local API',
    () async {
      final requests = <http.Request>[];
      final vm = viewModel(
        MockClient((request) async {
          requests.add(request);
          return request.url.path == '/api/status'
              ? ready()
              : reply(source: true);
        }),
      );
      expect(vm.selectedChatModelId, 'gemini');
      expect(
        vm.availableChatModels.map((model) => model.id),
        containsAll(['gemini', 'medgemma']),
      );
      vm.switchChatModel('medgemma');
      await vm.sendChatMessage('Tay tôi bị trầy');
      final request = requests.singleWhere(
        (item) => item.url.path == '/api/chat',
      );
      expect(request.url.host, '192.168.1.42');
      expect(jsonDecode(request.body), {
        'message': 'Tay tôi bị trầy',
        'mode': 'grounded',
      });
      expect(vm.chatMessages.last.modelSource, 'sqlite');
      expect(
        vm.chatMessages.last.citations.single.url.toString(),
        'http://192.168.1.42:8080/api/source/example',
      );
      vm.switchChatModel('gemini');
      expect(vm.selectedChatModelId, 'gemini');
      vm.dispose();
    },
  );

  test('model cannot change while its request is in flight', () async {
    final pending = Completer<http.Response>();
    final vm = viewModel(
      MockClient(
        (request) async =>
            request.url.path == '/api/status' ? ready() : pending.future,
      ),
    );
    vm.switchChatModel('medgemma');
    final send = vm.sendChatMessage('2 + 2 bằng bao nhiêu?');
    vm.switchChatModel('gemini');
    expect(vm.selectedChatModelId, 'medgemma');
    expect(vm.isAiThinking, isTrue);
    pending.complete(reply());
    await send;
    expect(vm.chatMessages.last.modelSource, 'medgemma');
    expect(vm.isAiThinking, isFalse);
    vm.dispose();
  });

  test('dispose ignores late network replies', () async {
    final pending = Completer<http.Response>();
    final vm = viewModel(
      MockClient(
        (request) async =>
            request.url.path == '/api/status' ? ready() : pending.future,
      ),
    );
    vm.switchChatModel('medgemma');
    final send = vm.sendChatMessage('Kiểm tra');
    vm.dispose();
    pending.complete(reply());
    await send;
    expect(vm.chatMessages.length, 1);
  });

  test('image consult uses server-owned analysis rather than a fabricated diagnosis', () async {
    final observed = Completer<Map<String, dynamic>>();
    final vm = viewModel(
      MockClient((request) async {
        if (request.url.path == '/api/status') return ready();
        observed.complete(
          Map<String, dynamic>.from(jsonDecode(request.body) as Map),
        );
        return reply(source: true);
      }),
    );
    vm.lastWoundPrediction = const WoundImagePrediction(
      analysisId: 'server_analysis_id_123',
      status: 'no_detection',
      detections: [],
      primary: null,
      width: 100,
      height: 100,
      analysisSeconds: 0.1,
      notice: 'Chưa xác nhận loại tổn thương.',
    );
    vm.setAnalysisResult(
      vm.analysisResult.copyWith(serverAnalysisId: 'server_analysis_id_123'),
    );
    vm.switchChatModel('medgemma');
    vm.consultAiWithCurrentAnalysis();
    final payload = await observed.future;
    expect(payload['image_analysis_id'], 'server_analysis_id_123');
    expect(payload['image_initial'], isTrue);
    expect(payload['message'], isNot(contains('chẩn đoán')));
    await Future<void>.delayed(Duration.zero);
    vm.dispose();
  });

  test(
    'a different image result cannot reuse the previous analysis ID',
    () async {
      final observed = Completer<Map<String, dynamic>>();
      final vm = viewModel(
        MockClient((request) async {
          if (request.url.path == '/api/status') return ready();
          observed.complete(
            Map<String, dynamic>.from(jsonDecode(request.body) as Map),
          );
          return reply();
        }),
      );
      vm.lastWoundPrediction = const WoundImagePrediction(
        analysisId: 'previous_analysis_123',
        status: 'no_detection',
        detections: [],
        primary: null,
        width: 100,
        height: 100,
        analysisSeconds: 0.1,
        notice: 'Chưa xác nhận.',
      );
      vm.setAnalysisResult(
        vm.analysisResult.copyWith(serverAnalysisId: 'different_analysis_123'),
      );
      vm.switchChatModel('medgemma');
      vm.consultAiWithCurrentAnalysis();
      final payload = await observed.future;
      expect(payload.containsKey('image_analysis_id'), isFalse);
      expect(payload.containsKey('image_initial'), isFalse);
      await Future<void>.delayed(Duration.zero);
      vm.dispose();
    },
  );

  testWidgets('mobile chat shows both model choices and real source metadata', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = viewModel(
      MockClient(
        (request) async =>
            request.url.path == '/api/status' ? ready() : reply(source: true),
      ),
    );
    vm.switchChatModel('medgemma');
    await vm.sendChatMessage('Kiểm tra tài liệu');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: Scaffold(body: ChatBoxAiView())),
      ),
    );
    await tester.pump();
    expect(find.text('Tài liệu SQLite'), findsOneWidget);
    expect(find.textContaining('21 mục tham khảo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('MedGemma (LAN Server)'));
    await tester.pumpAndSettle();
    expect(find.text('Google Gemini 3.8 Flash'), findsOneWidget);
    expect(find.text('MedGemma 1.5 4B'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
}
