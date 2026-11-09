import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';

import '../../../core/rule_engine/rule_models.dart';
import '../../../core/medgemma_chat_api.dart';
import '../../../core/wound_prediction.dart';
import '../models/image_analysis_models.dart';
import 'analysis_result_viewmodel.dart';
import 'first_aid_viewmodel.dart';
import 'user_navigation_viewmodel.dart';

mixin PhanTichAnhViewModel
    on DieuHuongCoSoViewModel, HuongDanSoCuuViewModel, KetQuaPhanTichViewModel {
  // Cấu hình văn bản chuẩn theo giao diện
  final AiUploadSpecModel uploadSpec = const AiUploadSpecModel(
    screenTitle: 'Phân tích hình ảnh tổn thương',
    dropzonePrefixText: 'Kéo thả ảnh vào đây, ',
    dropzoneActionText: 'chọn ảnh hoặc dán ảnh (Ctrl+V)',
    supportedFormatsText: 'Hỗ trợ: JPG, PNG, WEBP (tối đa 10MB)',
    selectButtonLabel: 'Chọn ảnh từ máy',
    dividerText: 'Hoặc chụp ảnh trực tiếp',
    cameraButtonLabel: 'Chụp ảnh bằng Camera',
    noticeBoldText:
        'Lưu ý: Hệ thống chỉ hỗ trợ phân tích các vết thương ngoài da.',
    noticeDetailText: 'Model YOLO AI sẽ quét và tự động nhận diện: Trầy xước, Vết cắt, Bỏng, Bầm tím.',
  );

  // Trạng thái ảnh đang được nạp chờ quét (Staged image)
  Uint8List? _stagedImageBytes;
  Uint8List? get stagedImageBytes => _stagedImageBytes;

  String? _stagedImageName;
  String? get stagedImageName => _stagedImageName;

  bool get hasStagedImage =>
      _stagedImageBytes != null && _stagedImageBytes!.isNotEmpty;

  // Trạng thái đang quét AI & tiến trình Progress bar
  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  double _analysisProgress = 0.0;
  double get analysisProgress => _analysisProgress;

  String _analysisStatusMessage = 'Đang chuẩn bị...';
  String get analysisStatusMessage => _analysisStatusMessage;

  // Hệ số độ tương phản hiện tại (1.0 là gốc)
  double _appliedContrast = 1.0;
  double get appliedContrast => _appliedContrast;

  // Cảm giác đau (3 mức: Không đau, Đau nhẹ, Đau nặng)
  PainLevel _painLevel = PainLevel.mild;
  PainLevel get painLevel => _painLevel;

  void setPainLevel(PainLevel level) {
    if (_painLevel != level) {
      _painLevel = level;
      toggleWarningSymptom(painLevel: level);
      notifyListeners();
    }
  }

  void setPainLevelFromIndex(int index) {
    switch (index) {
      case 0:
        setPainLevel(PainLevel.none);
        break;
      case 1:
        setPainLevel(PainLevel.mild);
        break;
      case 2:
        setPainLevel(PainLevel.severe);
        break;
    }
  }

  // 3 Checkbox tình trạng quan sát kèm theo khi quét vết thương:
  bool _hasForeignBody = false; // Có dị vật cắm vào vết thương
  bool get hasForeignBody => _hasForeignBody;

  bool _isBleeding = false; // Đang chảy máu nhiều / liên tục
  bool get isBleeding => _isBleeding;

  bool _hasPusOrInfection = false; // Chảy mủ / Sưng đỏ tấy (nhiễm trùng)
  bool get hasPusOrInfection => _hasPusOrInfection;

  void toggleHasForeignBody(bool? val) {
    _hasForeignBody = val ?? false;
    notifyListeners();
  }

  void toggleIsBleeding(bool? val) {
    _isBleeding = val ?? false;
    notifyListeners();
  }

  void toggleHasPusOrInfection(bool? val) {
    _hasPusOrInfection = val ?? false;
    notifyListeners();
  }

  void resetWoundCheckboxes() {
    _hasForeignBody = false;
    _isBleeding = false;
    _hasPusOrInfection = false;
    _painLevel = PainLevel.mild;
    notifyListeners();
  }

  // Ảnh thực tế lần quét gần nhất
  Uint8List? _lastSelectedImageBytes;
  Uint8List? get lastSelectedImageBytes => _lastSelectedImageBytes;

  String? _lastSelectedImageName;
  String? get lastSelectedImageName => _lastSelectedImageName;

  /// Địa chỉ Backend AI FastAPI (mặc định localhost cổng 8000)
  MedGemmaChatApi imageApi = MedGemmaChatApi();
  WoundImagePrediction? lastWoundPrediction;
  bool _imageDisposed = false;
  void disposeImageAnalysis() {
    _imageDisposed = true;
    imageApi.close();
  }

  /// Mở hộp thoại chọn ảnh từ thiết bị (chỉ nạp ảnh vào trạng thái chờ, chưa quét ngay)
  Future<void> pickAndStageImage(BuildContext context) async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
      );

      if (files.isEmpty) {
        return;
      }

      final file = files.first;
      Uint8List? imageBytes;
      if (file.path != null && file.path!.isNotEmpty) {
        final f = File(file.path!);
        if (await f.exists()) {
          imageBytes = await f.readAsBytes();
        }
      }
      imageBytes ??= await file.readAsBytes();
      final fileName = file.name;

      if (imageBytes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể đọc dữ liệu từ tệp ảnh này.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      lastWoundPrediction = null;
      _stagedImageBytes = imageBytes;
      _stagedImageName = fileName;
      _lastSelectedImageBytes = imageBytes;
      _lastSelectedImageName = fileName;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã nạp ảnh "$fileName". Nhấn "Bắt đầu quét AI" để phân tích!',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF15803D),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Dán ảnh trực tiếp từ Clipboard (hỗ trợ cả sao chép pixel ảnh và sao chép file ảnh từ File Explorer)
  Future<void> pasteAndStageImage(BuildContext context) async {
    try {
      Uint8List? imageBytes = await Pasteboard.image;
      String fileName =
          'clipboard_${DateTime.now().millisecondsSinceEpoch}.png';

      // Nếu không có pixel ảnh trực tiếp, kiểm tra xem người dùng có sao chép tệp ảnh từ Windows Explorer không
      if (imageBytes == null || imageBytes.isEmpty) {
        try {
          final files = await Pasteboard.files();
          if (files.isNotEmpty) {
            final firstFilePath = files.first;
            final ext = firstFilePath.split('.').last.toLowerCase();
            if (['jpg', 'jpeg', 'png', 'webp', 'bmp'].contains(ext)) {
              final f = File(firstFilePath);
              if (await f.exists()) {
                imageBytes = await f.readAsBytes();
                fileName = firstFilePath.split(RegExp(r'[\\/]')).last;
              }
            }
          }
        } catch (_) {}
      }

      if (imageBytes == null || imageBytes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Clipboard chưa có hình ảnh. Bạn có thể sao chép (Copy) ảnh hoặc file ảnh rồi nhấn Ctrl+V để dán!',
                    ),
                  ),
                ],
              ),
              backgroundColor: Color(0xFFD97706),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Xác định định dạng thật của ảnh từ magic bytes
      if (imageBytes.length >= 4) {
        if (imageBytes[0] == 0x42 &&
            imageBytes[1] == 0x4D &&
            !fileName.toLowerCase().endsWith('.bmp')) {
          fileName = 'clipboard_${DateTime.now().millisecondsSinceEpoch}.bmp';
        } else if (imageBytes[0] == 0xFF &&
            imageBytes[1] == 0xD8 &&
            !fileName.toLowerCase().endsWith('.jpg') &&
            !fileName.toLowerCase().endsWith('.jpeg')) {
          fileName = 'clipboard_${DateTime.now().millisecondsSinceEpoch}.jpg';
        } else if (imageBytes[0] == 0x89 &&
            imageBytes[1] == 0x50 &&
            !fileName.toLowerCase().endsWith('.png')) {
          fileName = 'clipboard_${DateTime.now().millisecondsSinceEpoch}.png';
        }
      }

      lastWoundPrediction = null;
      _stagedImageBytes = imageBytes;
      _stagedImageName = fileName;
      _lastSelectedImageBytes = imageBytes;
      _lastSelectedImageName = fileName;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã dán ảnh "$fileName" thành công! Nhấn "Bắt đầu quét AI" để phân tích.',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF15803D),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đọc ảnh từ Clipboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Chụp ảnh hoặc chọn ảnh trực tiếp từ Camera thiết bị (tối ưu cho Web mobile, Android, iOS)
  Future<void> captureImageFromCamera(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 92,
      );

      if (photo == null) {
        return;
      }

      final imageBytes = await photo.readAsBytes();
      if (imageBytes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể đọc dữ liệu ảnh từ Camera.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final fileName = photo.name.isNotEmpty
          ? photo.name
          : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';

      lastWoundPrediction = null;
      _stagedImageBytes = imageBytes;
      _stagedImageName = fileName;
      _lastSelectedImageBytes = imageBytes;
      _lastSelectedImageName = fileName;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã chụp ảnh từ Camera thành công! Nhấn "Bắt đầu quét AI" để phân tích.',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF15803D),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở camera trên thiết bị này: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Hủy ảnh đang chờ quét để chọn ảnh khác
  void clearStagedImage() {
    _stagedImageBytes = null;
    _stagedImageName = null;
    resetWoundCheckboxes();
    notifyListeners();
  }

  /// Bắt đầu quét phân tích ảnh bằng mô hình YOLO, kèm thanh tiến trình chạy mượt mà
  Future<void> startAnalysis(
    BuildContext context, {
    double contrast = 1.0,
  }) async {
    if (_imageDisposed || _isAnalyzing) return;
    final imageBytes = _stagedImageBytes ?? _lastSelectedImageBytes;
    final fileName = _stagedImageName ?? _lastSelectedImageName ?? 'image.jpg';

    if (imageBytes == null || imageBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn hoặc dán ảnh trước khi bắt đầu quét!'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    _lastSelectedImageBytes = imageBytes;
    _lastSelectedImageName = fileName;
    _appliedContrast = contrast;

    // 1. Kích hoạt trạng thái quét và bắt đầu progress bar
    _isAnalyzing = true;
    _analysisProgress = 0.10;
    _analysisStatusMessage = contrast != 1.0
        ? 'Đang chuẩn bị quét lại (Độ tương phản x${contrast.toStringAsFixed(1)})...'
        : 'Đang kiểm tra kết nối mô hình YOLO AI...';
    notifyListeners();

    Timer? progressTimer;
    progressTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (_imageDisposed || !_isAnalyzing) {
        timer.cancel();
        return;
      }
      if (_analysisProgress < 0.85) {
        _analysisProgress += 0.08;
        if (_analysisProgress >= 0.35 && _analysisProgress < 0.65) {
          _analysisStatusMessage = contrast != 1.0
              ? 'Đang áp dụng bộ lọc tăng cường tương phản x${contrast.toStringAsFixed(1)}...'
              : 'Đang tải dữ liệu ảnh lên mô hình AI...';
        } else if (_analysisProgress >= 0.65) {
          _analysisStatusMessage =
              'Mô hình YOLO đang nhận diện và khoanh vùng tổn thương...';
        }
        notifyListeners();
      }
    });

    try {
      final prediction = await imageApi.analyzeImage(
        imageBytes,
        contrast: contrast,
        observations: {
          'heavy_bleeding': _isBleeding,
          'foreign_body': _hasForeignBody,
          'infection_signs': _hasPusOrInfection,
        },
      );
      progressTimer.cancel();
      if (_imageDisposed) return;
      lastWoundPrediction = prediction;
      _analysisProgress = 1.0;
      _analysisStatusMessage = 'Phân tích hoàn tất!';
      final primary = prediction.primary;
      final isDetected = primary != null;
      final injuryType = primary?.label ?? 'Chưa xác định';
      final confidence = ((primary?.confidence ?? 0) * 100).round();
      final topicId = primary?.topicId ?? '';
      final message = prediction.summary;
      final Map<String, dynamic> data = {
        'box': primary?.box,
        'image_width': prediction.width,
        'image_height': prediction.height,
        'all_detections': prediction.detections
            .map(
              (item) => {
                'vn_label': item.label,
                'topic_id': item.topicId,
                'confidence_percent': (item.confidence * 100).round(),
                'severity': 'Chưa xác định từ ảnh',
                'box': item.box,
                'class_name_raw': item.className,
              },
            )
            .toList(),
      };
      {
        List<double>? boxCoords;
        if (data['box'] != null && data['box'] is List) {
          boxCoords = (data['box'] as List)
              .map((e) => (e as num).toDouble())
              .toList();
        }

        // Đọc danh sách tất cả các tổn thương phát hiện trên ảnh
        final List<DetectedWoundItemModel> allDetections = [];
        if (data['all_detections'] != null && data['all_detections'] is List) {
          for (final item in data['all_detections'] as List) {
            if (item is Map<String, dynamic>) {
              allDetections.add(DetectedWoundItemModel.fromJson(item));
            }
          }
        }

        final double? imgW = (data['image_width'] as num?)?.toDouble();
        final double? imgH = (data['image_height'] as num?)?.toDouble();

        final bool hasMulti = allDetections.length > 1;
        final String bannerTitle = isDetected
            ? (hasMulti
                  ? 'Phát hiện kết hợp ${allDetections.length} vết thương trên ảnh'
                  : (contrast != 1.0
                        ? 'Kết quả quét lại (Tương phản x${contrast.toStringAsFixed(1)})'
                        : 'Kết quả phân tích AI'))
            : 'Không tìm thấy tổn thương rõ ràng';

        // 5. Cập nhật Model Kết quả phân tích thật
        final realResult = AiAnalysisResultModel(
          bannerTitle: bannerTitle,
          confidencePercent: confidence,
          injuryType: injuryType,
          boundingBoxLabel: isDetected
              ? '$injuryType $confidence%'
              : 'Không có vết thương',
          infoCardTitle: hasMulti
              ? 'Thông tin nhận diện AI (${allDetections.length} tổn thương)'
              : 'Thông tin nhận diện AI',
          injuryTypeLabel: 'Loại tổn thương:',
          confidenceRowLabel: 'Độ tin cậy:',
          locationRowLabel: 'Vị trí:',
          bottomNoticeText: isDetected
              ? (hasMulti
                    ? 'Ảnh có nhiều dự đoán; cần đối chiếu với mô tả thực tế trước khi chọn hướng dẫn.'
                    : 'Mô hình YOLO đã nhận diện thành công vết thương trên ảnh. Bạn có thể chọn vị trí cơ thể và xem hướng dẫn sơ cứu.')
              : 'Mô hình YOLO không phát hiện thấy vết thương ngoài da rõ ràng. Nếu bạn đang đau, hãy xem các mục sơ cứu khẩn cấp hoặc chọn thủ công bên dưới.',
          primaryActionLabel: isDetected
              ? 'Xem hướng dẫn sơ cứu'
              : 'Tra cứu sơ cứu chung',
          rawImageBytes: imageBytes,
          imageFileName: fileName,
          detectedTopicId: topicId,
          isDetected: isDetected,
          boundingBox: boxCoords,
          originalImageWidth: imgW,
          originalImageHeight: imgH,
          detectionMessage: message,
          serverAnalysisId: prediction.analysisId,
          allDetections: allDetections,
          appliedContrast: contrast,
        );

        setAnalysisResult(realResult);

        // Chờ 300ms để người dùng thấy progress đạt 100%
        await Future.delayed(const Duration(milliseconds: 300));
        if (_imageDisposed) return;
        _isAnalyzing = false;
        _stagedImageBytes = null; // Reset staging sau khi phân tích xong
        _stagedImageName = null;
        notifyListeners();

        // Ghi lại lịch sử phân tích trên Supabase Cloud
        onNewAnalysisRecorded(
          imageSourceName: fileName,
          injuryType: isDetected
              ? (hasMulti ? realResult.combinedInjurySummary : injuryType)
              : 'Không phát hiện tổn thương rõ ràng',
          confidencePercent: isDetected ? confidence : null,
          locationLabel: 'Chưa xác định',
          topicId: topicId,
          rawImageBytes: imageBytes,
        );

        // Đồng bộ các vết thương phát hiện, mức độ đau và 3 checkbox lâm sàng sang Rule Engine
        final List<String> secIds = allDetections.length > 1
            ? allDetections.skip(1).map((d) => d.topicId).toList()
            : const [];
        final List<String> secNames = allDetections.length > 1
            ? allDetections.skip(1).map((d) => d.label).toList()
            : const [];

        updateInjuryContext(
          topicId: topicId,
          injuryTypeName: injuryType,
          locationId: 'arm',
          confidencePercent: confidence,
          painLevel: _painLevel,
          secondaryInjuryTypeIds: secIds,
          secondaryInjuryTypeNames: secNames,
        );
        toggleWarningSymptom(
          hasDeepWoundOrForeignBody: _hasForeignBody,
          isBleedingHeavy: _isBleeding,
          hasSignsOfInfection: _hasPusOrInfection,
          painLevel: _painLevel,
        );

        // Chuyển sang màn hình Kết quả phân tích
        navigateToAnalysisResult(imageSourceName: fileName);
      }
    } catch (error) {
      progressTimer.cancel();
      if (_imageDisposed) return;
      _isAnalyzing = false;
      notifyListeners();

      if (context.mounted) {
        _showAnalysisErrorDialog(
          context,
          fileName,
          imageBytes,
          error is ChatApiException
              ? error.message
              : 'Có lỗi khi xử lý kết quả phân tích. Hãy thử lại.',
        );
      }
    }
  }

  /// Quét lại hình ảnh với độ tương phản thay đổi (contrast enhancement)
  Future<void> reScanWithContrast(
    BuildContext context, {
    double newContrast = 1.35,
  }) async {
    await startAnalysis(context, contrast: newContrast);
  }

  void _showAnalysisErrorDialog(
    BuildContext context,
    String fileName,
    Uint8List imageBytes,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD97706),
              size: 28,
            ),
            SizedBox(width: 10),
            Text('Chưa thể quét hình ảnh'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final fallbackResult = AiAnalysisResultModel(
                bannerTitle: 'Ảnh đã chọn (Chưa có kết quả quét)',
                confidencePercent: 0,
                injuryType: 'Chưa phân tích được',
                boundingBoxLabel: 'Chưa phát hiện',
                infoCardTitle: 'Thông tin tệp ảnh',
                injuryTypeLabel: 'Trạng thái:',
                confidenceRowLabel: 'Kết nối:',
                bottomNoticeText: 'Không thể nhận diện tổn thương từ ảnh. Bạn có thể tra cứu sơ cứu thủ công theo danh mục bên dưới.',
                primaryActionLabel: 'Tra cứu sơ cứu',
                rawImageBytes: imageBytes,
                imageFileName: fileName,
                detectedTopicId: 'abrasion',
                isDetected: false,
              );
              setAnalysisResult(fallbackResult);
              navigateToAnalysisResult(imageSourceName: fileName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xem ảnh đã chọn'),
          ),
        ],
      ),
    );
  }

  void onSelectImageFromFilePressed(BuildContext context) {
    pickAndStageImage(context);
  }

  void onCaptureFromCameraPressed(BuildContext context) {
    captureImageFromCamera(context);
  }

  void onPasteImagePressed(BuildContext context) {
    pasteAndStageImage(context);
  }
}
