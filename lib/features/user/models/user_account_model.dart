// File: lib/features/user/models/user_account_model.dart

/// Mô hình tài khoản & Hồ sơ sức khỏe cá nhân (Zero-Knowledge / Bảo mật cục bộ)
/// Tuyệt đối KHÔNG lưu trữ tên thật, số điện thoại hay địa chỉ nhà của người dùng.
class UserAccountModel {
  final String username;
  final String password;
  final String fullName; // Giữ để tương thích hiển thị, mặc định dùng username
  final DateTime createdAt;
  final String? emailOrPhone; // Tùy chọn: dùng khi cần nhận OTP khôi phục mật khẩu

  // 1. Chỉ số thể chất
  final String? gender; // 'male', 'female', 'other'
  final double? weightKg; // Cân nặng (kg)
  final double? heightCm; // Chiều cao (cm)

  // 2. Nhóm máu & yếu tố Rh
  final String? bloodType; // 'A', 'B', 'AB', 'O'
  final String? rhFactor; // 'Rh+', 'Rh-'

  // 3. Tiền sử dị ứng thuốc & hóa chất (ví dụ: Penicillin, Cồn y tế, Povidone...)
  final List<String> allergies;

  // 4. Bệnh lý nền nguy hiểm ảnh hưởng đến sơ cứu
  // 'diabetes' (Tiểu đường), 'hemophilia' (Máu khó đông), 'cardiovascular' (Tim mạch)...
  final List<String> medicalConditions;

  // 5. Ghi chú y tế bổ sung khác
  final String? otherNotes;

  // 6. Trạng thái hoạt động & Quản trị tài khoản
  final bool isLocked;
  final String? lockReason;
  final DateTime? lastActiveAt;

  // 7. Nhà cung cấp định danh & Liên kết Google OAuth
  final String authProvider; // 'manual', 'google'
  final String? googleId;
  final bool isGoogleLinked;

  const UserAccountModel({
    required this.username,
    required this.password,
    this.fullName = '',
    required this.createdAt,
    this.emailOrPhone,
    this.gender,
    this.weightKg,
    this.heightCm,
    this.bloodType,
    this.rhFactor,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.otherNotes,
    this.isLocked = false,
    this.lockReason,
    this.lastActiveAt,
    this.authProvider = 'manual',
    this.googleId,
    this.isGoogleLinked = false,
  });

  /// Tên hiển thị ẩn danh (ưu tiên username bảo vệ danh tính)
  String get displayName => fullName.isNotEmpty ? fullName : username;

  /// Địa chỉ email nhận mã khôi phục mật khẩu (nếu người dùng đăng ký)
  String get email => emailOrPhone ?? '';

  /// Tính chỉ số BMI tự động nếu có chiều cao và cân nặng
  double? get bmi {
    if (heightCm == null || heightCm! <= 0 || weightKg == null || weightKg! <= 0) {
      return null;
    }
    final heightM = heightCm! / 100.0;
    return weightKg! / (heightM * heightM);
  }

  /// Tiện ích kiểm tra bệnh lý nền
  bool get hasHemophilia => medicalConditions.contains('hemophilia');
  bool get hasDiabetes => medicalConditions.contains('diabetes');
  bool get hasCardiovascular => medicalConditions.contains('cardiovascular');

  /// Kiểm tra người dùng có thông tin hồ sơ sức khỏe / thể chất hay không
  bool get hasHealthData =>
      (gender != null && gender!.trim().isNotEmpty) ||
      (weightKg != null && weightKg! > 0) ||
      (heightCm != null && heightCm! > 0) ||
      (bloodType != null && bloodType!.trim().isNotEmpty) ||
      (rhFactor != null && rhFactor!.trim().isNotEmpty) ||
      allergies.isNotEmpty ||
      medicalConditions.isNotEmpty ||
      (otherNotes != null && otherNotes!.trim().isNotEmpty);

  /// Nhãn giới tính hiển thị tiếng Việt
  String? get genderLabel {
    switch (gender) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      case 'other':
        return 'Khác';
      default:
        return gender;
    }
  }

  /// Đánh giá phân loại thể trạng theo chỉ số BMI
  String? get bmiCategory {
    final val = bmi;
    if (val == null) return null;
    if (val < 18.5) return 'Gầy / Thiếu cân';
    if (val < 25.0) return 'Thể trạng bình thường / Cân đối';
    if (val < 30.0) return 'Thừa cân';
    return 'Béo phì';
  }

  /// Nhóm máu kèm yếu tố Rh (ví dụ: 'O Rh+', 'A Rh-')
  String? get bloodTypeSummary {
    if ((bloodType == null || bloodType!.isEmpty) &&
        (rhFactor == null || rhFactor!.isEmpty)) {
      return null;
    }
    final bt = bloodType ?? '';
    final rh = rhFactor ?? '';
    return '$bt $rh'.trim();
  }

  /// Tạo bản tóm tắt hồ sơ sức khỏe cá nhân (Zero-Knowledge: tuyệt đối không chứa PII như tên, SĐT, địa chỉ)
  /// Được chèn vào prompt để AI cá nhân hóa hướng dẫn sơ cứu và cảnh báo chống chỉ định.
  /// Hỗ trợ [compact] = true cho MedGemma hoặc các mô hình giới hạn độ dài token.
  String buildAiHealthProfileSummary({bool compact = false}) {
    if (!hasHealthData) return '';

    if (compact) {
      final tags = <String>[];
      if (genderLabel != null) tags.add('Giới tính: $genderLabel');
      if (bmi != null) tags.add('BMI: ${bmi!.toStringAsFixed(1)}');
      final bSummary = bloodTypeSummary;
      if (bSummary != null && bSummary.isNotEmpty) {
        tags.add('Nhóm máu: $bSummary');
      }
      final conditions = <String>[];
      if (hasHemophilia) conditions.add('Máu khó đông (Hemophilia)');
      if (hasDiabetes) conditions.add('Tiểu đường');
      if (hasCardiovascular) conditions.add('Tim mạch');
      for (final c in medicalConditions) {
        if (!['hemophilia', 'diabetes', 'cardiovascular'].contains(c)) {
          conditions.add(c);
        }
      }
      if (conditions.isNotEmpty) tags.add('Bệnh nền: ${conditions.join(", ")}');
      if (allergies.isNotEmpty) {
        tags.add('DỊ ỨNG (CẤM DÙNG): ${allergies.join(", ")}');
      }
      if (otherNotes != null && otherNotes!.trim().isNotEmpty) {
        tags.add('Ghi chú: ${otherNotes!.trim()}');
      }
      return tags.map((t) => '[$t]').join('');
    }

    final lines = <String>[];
    lines.add('[HỒ SƠ SỨC KHỎE BỆNH NHÂN (DỮ LIỆU CÁ NHÂN HÓA ẨN DANH)]');

    // 1. Chỉ số thể chất
    final physicalStats = <String>[];
    if (genderLabel != null && genderLabel!.isNotEmpty) {
      physicalStats.add('Giới tính: $genderLabel');
    }
    if (heightCm != null && heightCm! > 0) {
      physicalStats.add('Chiều cao: ${heightCm!.toStringAsFixed(1)}cm');
    }
    if (weightKg != null && weightKg! > 0) {
      physicalStats.add('Cân nặng: ${weightKg!.toStringAsFixed(1)}kg');
    }
    if (bmi != null) {
      final cat = bmiCategory != null ? ' ($bmiCategory)' : '';
      physicalStats.add('BMI: ${bmi!.toStringAsFixed(1)}$cat');
    }
    if (physicalStats.isNotEmpty) {
      lines.add('- Chỉ số thể chất: ${physicalStats.join(', ')}');
    }

    // 2. Nhóm máu & yếu tố Rh
    final bSummary = bloodTypeSummary;
    if (bSummary != null && bSummary.isNotEmpty) {
      lines.add('- Nhóm máu: $bSummary');
    }

    // 3. Bệnh lý nền nguy hiểm
    final conditionsList = <String>[];
    if (hasHemophilia) {
      conditionsList.add(
        'MÁU KHÓ ĐÔNG (Hemophilia) -> BÁO ĐỘNG ĐỎ: Xuất huyết không tự cầm, cấm dùng Aspirin/NSAID, nguy cơ tụ máu chèn ép mô sâu',
      );
    }
    if (hasDiabetes) {
      conditionsList.add(
        'ĐÁI THÁO ĐƯỜNG (Tiểu đường) -> Vết thương rất chậm liền sẹo, biến chứng vi mạch và nguy cơ loét hoại tử/nhiễm trùng cao',
      );
    }
    if (hasCardiovascular) {
      conditionsList.add(
        'BỆNH TIM MẠCH / HUYẾT ÁP -> Nguy cơ sốc chấn thương, cần ổn định nhịp tim và huyết áp, tránh đau đớn quá mức',
      );
    }
    for (final cond in medicalConditions) {
      if (!['hemophilia', 'diabetes', 'cardiovascular'].contains(cond)) {
        conditionsList.add(cond);
      }
    }
    if (conditionsList.isNotEmpty) {
      lines.add('- Bệnh lý nền nguy hiểm: ${conditionsList.join('; ')}');
    }

    // 4. Tiền sử dị ứng thuốc & hóa chất
    if (allergies.isNotEmpty) {
      lines.add('- Tiền sử dị ứng thuốc & hóa chất: ${allergies.join(', ')}');
      lines.add(
        '  * CHỈ THỊ BẮT BUỘC: TUYỆT ĐỐI CHỐNG CHỈ ĐỊNH các hoạt chất/dung dịch sát khuẩn mà bệnh nhân bị dị ứng nêu trên trong toàn bộ hướng dẫn sơ cứu!',
      );
    }

    // 5. Ghi chú y tế bổ sung khác
    if (otherNotes != null && otherNotes!.trim().isNotEmpty) {
      lines.add('- Ghi chú y tế bổ sung: ${otherNotes!.trim()}');
    }

    return lines.join('\n');
  }

  Map<String, dynamic> toMedicalProfileMap() {
    return {
      'gender': gender,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'blood_type': bloodType,
      'rh_factor': rhFactor,
      'allergies': allergies,
      'medical_conditions': medicalConditions,
      'other_notes': otherNotes,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'fullName': fullName,
      'createdAt': createdAt.toIso8601String(),
      'emailOrPhone': emailOrPhone,
      'gender': gender,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'bloodType': bloodType,
      'rhFactor': rhFactor,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'otherNotes': otherNotes,
      'is_locked': isLocked,
      'lock_reason': lockReason,
      'last_active_at': lastActiveAt?.toIso8601String(),
      'auth_provider': authProvider,
      'google_id': googleId,
      'is_google_linked': isGoogleLinked,
    };
  }

  factory UserAccountModel.fromMap(Map<String, dynamic> map) {
    return UserAccountModel(
      username: map['username'] as String? ?? '',
      password: map['password'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : (map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now() : DateTime.now()),
      emailOrPhone: map['emailOrPhone'] as String? ?? map['email_or_phone'] as String?,
      gender: map['gender'] as String?,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? (map['weight_kg'] as num?)?.toDouble(),
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? (map['height_cm'] as num?)?.toDouble(),
      bloodType: map['bloodType'] as String? ?? map['blood_type'] as String?,
      rhFactor: map['rhFactor'] as String? ?? map['rh_factor'] as String?,
      allergies: List<String>.from(map['allergies'] as List? ?? []),
      medicalConditions: List<String>.from(map['medicalConditions'] as List? ?? map['medical_conditions'] as List? ?? []),
      otherNotes: map['otherNotes'] as String? ?? map['other_notes'] as String?,
      isLocked: map['is_locked'] as bool? ?? map['isLocked'] as bool? ?? false,
      lockReason: map['lock_reason'] as String? ?? map['lockReason'] as String?,
      lastActiveAt: map['last_active_at'] != null
          ? DateTime.tryParse(map['last_active_at'] as String)
          : (map['lastActiveAt'] != null ? DateTime.tryParse(map['lastActiveAt'] as String) : null),
      authProvider: map['auth_provider'] as String? ?? map['authProvider'] as String? ?? 'manual',
      googleId: map['google_id'] as String? ?? map['googleId'] as String?,
      isGoogleLinked: map['is_google_linked'] as bool? ??
          map['isGoogleLinked'] as bool? ??
          ((map['auth_provider'] == 'google' || map['authProvider'] == 'google') ||
              map['google_id'] != null ||
              map['googleId'] != null),
    );
  }

  UserAccountModel copyWith({
    String? username,
    String? password,
    String? fullName,
    DateTime? createdAt,
    String? emailOrPhone,
    String? gender,
    double? weightKg,
    double? heightCm,
    String? bloodType,
    String? rhFactor,
    List<String>? allergies,
    List<String>? medicalConditions,
    String? otherNotes,
    bool? isLocked,
    String? lockReason,
    DateTime? lastActiveAt,
    String? authProvider,
    String? googleId,
    bool? isGoogleLinked,
  }) {
    return UserAccountModel(
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      emailOrPhone: emailOrPhone ?? this.emailOrPhone,
      gender: gender ?? this.gender,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      bloodType: bloodType ?? this.bloodType,
      rhFactor: rhFactor ?? this.rhFactor,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      otherNotes: otherNotes ?? this.otherNotes,
      isLocked: isLocked ?? this.isLocked,
      lockReason: lockReason ?? this.lockReason,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      authProvider: authProvider ?? this.authProvider,
      googleId: googleId ?? this.googleId,
      isGoogleLinked: isGoogleLinked ?? this.isGoogleLinked,
    );
  }


}

/// Mô hình yêu cầu mở khóa tài khoản người dùng gửi lên Quản trị viên
class UserUnlockAppealModel {
  final String id;
  final String username;
  final String reason;
  final DateTime createdAt;
  final String status; // 'pending' (Chờ duyệt), 'approved' (Đã mở khóa), 'rejected' (Đã từ chối)
  final String? adminNote;
  final DateTime? resolvedAt;

  const UserUnlockAppealModel({
    required this.id,
    required this.username,
    required this.reason,
    required this.createdAt,
    this.status = 'pending',
    this.adminNote,
    this.resolvedAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Đã mở khóa';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return 'Chờ duyệt';
    }
  }

  UserUnlockAppealModel copyWith({
    String? id,
    String? username,
    String? reason,
    DateTime? createdAt,
    String? status,
    String? adminNote,
    DateTime? resolvedAt,
  }) {
    return UserUnlockAppealModel(
      id: id ?? this.id,
      username: username ?? this.username,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'admin_note': adminNote,
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  factory UserUnlockAppealModel.fromMap(Map<String, dynamic> map) {
    return UserUnlockAppealModel(
      id: map['id']?.toString() ?? '',
      username: map['username'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now() : DateTime.now()),
      status: map['status'] as String? ?? 'pending',
      adminNote: map['admin_note'] as String? ?? map['adminNote'] as String?,
      resolvedAt: map['resolved_at'] != null
          ? DateTime.tryParse(map['resolved_at'] as String)
          : (map['resolvedAt'] != null ? DateTime.tryParse(map['resolvedAt'] as String) : null),
    );
  }
}
