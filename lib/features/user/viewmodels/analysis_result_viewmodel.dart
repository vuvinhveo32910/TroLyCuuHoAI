import 'package:flutter/material.dart';

import '../models/image_analysis_models.dart';
import 'first_aid_viewmodel.dart';
import 'user_navigation_viewmodel.dart';

mixin KetQuaPhanTichViewModel
    on DieuHuongCoSoViewModel, HuongDanSoCuuViewModel {
  // Trạng thái vị trí tổn thương đang được chọn trên Màn hình 3 (Mặc định: 'arm' -> 'Cánh tay')
  String _selectedLocationId = 'arm';
  String get selectedLocationId => _selectedLocationId;

  // Trạng thái mở/đóng bảng chọn thủ công loại tổn thương khi AI đoán sai/không phù hợp
  bool _isShowingManualPicker = false;
  bool get isShowingManualPicker => _isShowingManualPicker;

  // Dữ liệu kết quả phân tích AI thực tế từ model YOLO
  AiAnalysisResultModel _analysisResult = const AiAnalysisResultModel(
    bannerTitle: 'Kết quả phân tích AI',
    confidenceLabelPrefix: 'Độ tin cậy:',
    confidencePercent: 0,
    injuryType: 'Chưa có ảnh quét',
    boundingBoxLabel: 'Chờ phân tích',
    infoCardTitle: 'Thông tin nhận diện AI',
    injuryTypeLabel: 'Loại tổn thương:',
    confidenceRowLabel: 'Độ tin cậy:',
    locationRowLabel: 'Vị trí:',
    locationSectionTitle: 'Chọn vị trí tổn thương',
    bottomNoticeText:
        'Hệ thống đã phân tích tổn thương bằng mô hình YOLO. Vui lòng chọn vị trí cụ thể để xem hướng dẫn sơ cứu phù hợp.',
    primaryActionLabel: 'Xem hướng dẫn sơ cứu',
    detectedTopicId: 'abrasion',
    isDetected: false,
  );
  AiAnalysisResultModel get analysisResult => _analysisResult;

  /// Cập nhật kết quả phân tích mới từ kết quả quét của model YOLO
  void setAnalysisResult(AiAnalysisResultModel newResult) {
    _analysisResult = newResult;
    _isShowingManualPicker = false;
    notifyListeners();
  }

  /// Bật/tắt giao diện chọn thủ công loại tổn thương
  void toggleManualPicker() {
    _isShowingManualPicker = !_isShowingManualPicker;
    notifyListeners();
  }

  /// 4 loại vết thương chuẩn mà mô hình AI hỗ trợ nhận diện và cung cấp bài sơ cứu
  final List<ManualInjuryOptionModel> manualInjuryOptions = const [
    ManualInjuryOptionModel(
      id: 'tray_xuoc',
      label: 'Trầy xước ngoài da',
      topicId: 'abrasion',
      severity: 'Nhẹ',
      icon: Icons.healing_outlined,
      description: 'Vết thương tróc biểu bì nông, rỉ dịch hoặc máu nhẹ.',
    ),
    ManualInjuryOptionModel(
      id: 'vet_cat_rach',
      label: 'Vết cắt / rách da',
      topicId: 'cut_laceration',
      severity: 'Cần chú ý',
      icon: Icons.content_cut_outlined,
      description: 'Tổn thương do vật sắc nhọn cứa hoặc rách toác, cần cầm máu.',
    ),
    ManualInjuryOptionModel(
      id: 'bong',
      label: 'Bỏng nhiệt / hóa chất',
      topicId: 'burn',
      severity: 'Quan trọng',
      icon: Icons.local_fire_department_outlined,
      description: 'Vết thương đỏ rát, phồng rộp do nhiệt độ cao, hóa chất hoặc nước sôi.',
    ),
    ManualInjuryOptionModel(
      id: 'bam_tim',
      label: 'Bầm tím / đụng dập',
      topicId: 'bruise',
      severity: 'Nhẹ',
      icon: Icons.bubble_chart_outlined,
      description: 'Tụ máu dưới da do va đập mạnh, sưng tấy đau nhức phần mềm.',
    ),
  ];

  /// Người dùng chọn trực tiếp loại vết thương khi kết quả quét AI không đúng
  void selectManualInjury(ManualInjuryOptionModel option) {
    _analysisResult = _analysisResult.copyWith(
      bannerTitle: 'Đã xác nhận: ${option.label}',
      injuryType: option.label,
      confidencePercent: 100,
      detectedTopicId: option.topicId,
      isDetected: true,
      isManualSelection: true,
      boundingBoxLabel: '${option.label} (Người dùng chọn)',
      bottomNoticeText:
          'Bạn đã xác định vết thương là "${option.label}". Hãy chọn vị trí tổn thương trên cơ thể và nhấn "Xem hướng dẫn sơ cứu".',
      detectionMessage:
          'Xác nhận thủ công: ${option.label}. Mức độ: ${option.severity}. ${option.description}',
      primaryActionLabel: 'Xem hướng dẫn sơ cứu ${option.label}',
    );

    _isShowingManualPicker = false;
    notifyListeners();
  }

  /// Danh sách 5 vị trí tổn thương trên Màn hình 3
  final List<InjuryLocationOptionModel> injuryLocations = const [
    InjuryLocationOptionModel(
      id: 'arm',
      label: 'Cánh tay',
      fallbackIcon: Icons.front_hand_outlined,
    ),
    InjuryLocationOptionModel(
      id: 'leg',
      label: 'Chân',
      fallbackIcon: Icons.directions_walk_outlined,
    ),
    InjuryLocationOptionModel(
      id: 'head',
      label: 'Đầu',
      fallbackIcon: Icons.face_outlined,
    ),
    InjuryLocationOptionModel(
      id: 'back',
      label: 'Lưng',
      fallbackIcon: Icons.accessibility_new_outlined,
    ),
    InjuryLocationOptionModel(
      id: 'other',
      label: 'Khác',
      fallbackIcon: Icons.open_with_outlined,
    ),
  ];

  /// Lấy nhãn tên vị trí tổn thương đang được chọn để hiển thị trong thẻ "Thông tin nhận diện"
  String get selectedLocationLabel {
    for (final option in injuryLocations) {
      if (option.id == _selectedLocationId) {
        return option.label;
      }
    }
    return injuryLocations.first.label;
  }

  /// Cập nhật vị trí tổn thương khi người dùng chọn 1 trong 5 vị trí trên Màn hình 3
  void selectInjuryLocation(String locationId) {
    if (_selectedLocationId == locationId) return;
    _selectedLocationId = locationId;
    notifyListeners();
  }

  /// Xử lý khi bấm nút "Xem hướng dẫn sơ cứu" trên Màn hình 3:
  /// Tự động mở đúng bài sơ cứu của loại vết thương mà AI hoặc người dùng vừa chọn
  @override
  void onViewFirstAidGuidePressed() {
    final topic = _analysisResult.detectedTopicId.isNotEmpty
        ? _analysisResult.detectedTopicId
        : 'abrasion';
    navigateToFirstAidGuide(topicId: topic);
  }
}
