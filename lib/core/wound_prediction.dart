class WoundDetection {
  final String className;
  final String label;
  final String topicId;
  final double confidence;
  final List<double> box;
  const WoundDetection(
    this.className,
    this.label,
    this.topicId,
    this.confidence,
    this.box,
  );

  factory WoundDetection.fromJson(Map<String, dynamic> value) {
    const labels = {
      'tray_xuoc': 'Trầy xước',
      'vet_cat_rach': 'Vết cắt, rách',
      'bong': 'Bỏng',
      'bam_tim': 'Bầm',
    };
    final name = value['class_name'];
    final confidence = value['confidence'];
    final box = value['box'];
    if (!labels.containsKey(name) ||
        confidence is! num ||
        !confidence.isFinite ||
        confidence < 0 ||
        confidence > 1 ||
        box is! List ||
        box.length != 4 ||
        box.any((v) => v is! num || !v.isFinite) ||
        value['topic_id'] is! String) {
      throw const FormatException('Invalid image prediction');
    }
    return WoundDetection(
      name as String,
      labels[name]!,
      value['topic_id'] as String,
      confidence.toDouble(),
      box.map((v) => (v as num).toDouble()).toList(),
    );
  }
}

class WoundImagePrediction {
  final String analysisId;
  final String status;
  final List<WoundDetection> detections;
  final WoundDetection? primary;
  final double width;
  final double height;
  final double analysisSeconds;
  final String notice;
  final Map<String, bool> observations;
  const WoundImagePrediction({
    required this.analysisId,
    required this.status,
    required this.detections,
    required this.primary,
    required this.width,
    required this.height,
    required this.analysisSeconds,
    required this.notice,
    this.observations = const {},
  });

  factory WoundImagePrediction.fromJson(Map<String, dynamic> value) {
    final id = value['analysis_id'];
    final status = value['status'];
    final width = value['image_width'];
    final height = value['image_height'];
    if (id is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{16,128}$').hasMatch(id) ||
        !{
          'detected',
          'multiple',
          'uncertain',
          'no_detection',
        }.contains(status) ||
        value['detections'] is! List ||
        width is! num ||
        height is! num ||
        !width.isFinite ||
        !height.isFinite ||
        width <= 0 ||
        height <= 0) {
      throw const FormatException('Invalid image analysis');
    }
    final items = (value['detections'] as List)
        .map(
          (v) => WoundDetection.fromJson(Map<String, dynamic>.from(v as Map)),
        )
        .toList();
    final primary = value['primary'] == null
        ? null
        : WoundDetection.fromJson(
            Map<String, dynamic>.from(value['primary'] as Map),
          );
    if ((status == 'detected') != (primary != null) ||
        (primary != null && primary.confidence < 0.5)) {
      throw const FormatException('Uncertain prediction cannot select a class');
    }
    final reported = value['observations'];
    const allowedSigns = {'heavy_bleeding', 'foreign_body', 'infection_signs'};
    if (reported != null &&
        (reported is! Map ||
            reported.entries.any(
              (entry) =>
                  !allowedSigns.contains(entry.key) || entry.value is! bool,
            ))) {
      throw const FormatException('Invalid user-reported observations');
    }
    return WoundImagePrediction(
      analysisId: id,
      status: status as String,
      detections: items,
      primary: primary,
      width: width.toDouble(),
      height: height.toDouble(),
      analysisSeconds: (value['analysis_seconds'] as num?)?.toDouble() ?? 0,
      notice:
          value['notice'] as String? ??
          'Đây là dự đoán từ ảnh, chưa xác nhận chẩn đoán.',
      observations: reported == null
          ? const {}
          : Map<String, bool>.from(reported as Map),
    );
  }

  String get observationSummary {
    const labels = {
      'heavy_bleeding': 'chảy máu nhiều/liên tục',
      'foreign_body': 'có dị vật cắm vào vết thương',
      'infection_signs': 'có mủ hoặc sưng đỏ tấy',
    };
    final selected = labels.entries
        .where((entry) => observations[entry.key] == true)
        .map((entry) => entry.value);
    return selected.isEmpty ? '' : 'Bạn đánh dấu: ${selected.join(', ')}.';
  }

  String get summary {
    if (primary != null) {
      return 'Model ảnh gợi ý: ${primary!.label} (điểm model ${(primary!.confidence * 100).round()}%). '
          'Kết quả cần đối chiếu với tình trạng thực tế.';
    }
    if (status == 'multiple') {
      return 'Ảnh có nhiều nhóm dự đoán: ${detections.map((v) => v.label).toSet().join(', ')}. '
          'Chưa chọn một loại tổn thương để áp dụng hướng dẫn riêng.';
    }
    return 'Ảnh chưa đủ cơ sở để xác định một loại tổn thương. '
        'Kết quả này không loại trừ vết thương; hãy mô tả thêm hoặc gửi ảnh rõ hơn.';
  }
}
