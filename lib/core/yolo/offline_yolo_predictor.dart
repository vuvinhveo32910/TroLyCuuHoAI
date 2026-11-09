// File: lib/core/yolo/offline_yolo_predictor.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../wound_prediction.dart';

/// Bộ phân tích hình ảnh Offline trực tiếp sử dụng mô hình YOLOv8 (lib/AI_Model/best.pt)
/// Không bắt buộc phải mở server hay mạng Internet. Chạy thẳng qua tiến trình Python cục bộ.
class OfflineYoloPredictor {
  static Future<WoundImagePrediction?> predictOffline(
    Uint8List imageBytes, {
    double contrast = 1.0,
  }) async {
    if (kIsWeb) return null;

    try {
      // 1. Tìm đường dẫn script predict_cli.py
      final currentDir = Directory.current.path;
      final scriptCandidates = [
        '$currentDir/backend/predict_cli.py',
        '$currentDir/predict_cli.py',
        'D:/IT/Code/Projects/DoAnIT/do_an_cntt_11/backend/predict_cli.py',
      ];

      String? scriptPath;
      for (final candidate in scriptCandidates) {
        if (File(candidate).existsSync()) {
          scriptPath = candidate;
          break;
        }
      }

      if (scriptPath == null) {
        debugPrint('[OfflineYoloPredictor] Không tìm thấy script backend/predict_cli.py');
        return null;
      }

      // 2. Tìm trình thông dịch Python trên máy
      final pythonCandidates = [
        'python',
        'C:\\Users\\fvgfv\\AppData\\Local\\Microsoft\\WindowsApps\\python.exe',
        'D:\\Models\\medgemma-env\\Scripts\\python.exe',
        'py',
      ];

      String? pythonExe;
      for (final py in pythonCandidates) {
        try {
          final testRes = await Process.run(py, ['--version']);
          if (testRes.exitCode == 0) {
            pythonExe = py;
            break;
          }
        } catch (_) {}
      }

      if (pythonExe == null) {
        debugPrint('[OfflineYoloPredictor] Không tìm thấy trình thông dịch Python khả dụng trên máy');
        return null;
      }

      // 3. Ghi dữ liệu ảnh ra file tạm để Python đọc
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/wound_scan_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(imageBytes);

      try {
        debugPrint('[OfflineYoloPredictor] Đang nhận diện trực tiếp bằng mô hình offline best.pt...');
        var runRes = await Process.run(
          pythonExe,
          [scriptPath, tempFile.path, contrast.toString()],
        ).timeout(const Duration(seconds: 45));

        // Nếu máy người dùng thiếu thư viện ultralytics / pillow, tự động cài đặt ngầm
        final stderrStr = runRes.stderr.toString();
        if (runRes.exitCode != 0 &&
            (stderrStr.contains('No module named') ||
                stderrStr.contains('ultralytics') ||
                stderrStr.contains('PIL'))) {
          debugPrint('[OfflineYoloPredictor] Phát hiện thiếu thư viện Python. Đang tự động tải ultralytics & pillow...');
          await Process.run(pythonExe, [
            '-m',
            'pip',
            'install',
            'ultralytics',
            'pillow',
            '--quiet',
          ]).timeout(const Duration(minutes: 3));

          // Thử lại lần 2 sau khi đã cài đặt xong
          runRes = await Process.run(
            pythonExe,
            [scriptPath, tempFile.path, contrast.toString()],
          ).timeout(const Duration(seconds: 45));
        }

        if (runRes.exitCode == 0) {
          final stdoutStr = runRes.stdout.toString().trim();
          if (stdoutStr.startsWith('{') && stdoutStr.endsWith('}')) {
            final jsonMap = jsonDecode(stdoutStr) as Map<String, dynamic>;
            if (jsonMap['error'] == null) {
              debugPrint('[OfflineYoloPredictor] Nhận diện offline thành công từ best.pt!');
              return WoundImagePrediction.fromJson(jsonMap);
            } else {
              debugPrint('[OfflineYoloPredictor] Lỗi xử lý model: ${jsonMap['error']}');
            }
          }
        } else {
          debugPrint('[OfflineYoloPredictor] Lỗi Process (code ${runRes.exitCode}): ${runRes.stderr}');
        }
      } finally {
        if (tempFile.existsSync()) {
          try {
            await tempFile.delete();
          } catch (_) {}
        }
      }
    } catch (e, stack) {
      debugPrint('[OfflineYoloPredictor] Ngoại lệ khi quét offline: $e\n$stack');
    }

    return null;
  }
}
