/// Mô hình dữ liệu cấu hình văn bản hiển thị cho màn hình "9. Đăng nhập quản trị" (Màn hình 9)
class AdminLoginSpecModel {
  final String brandTitle;
  final String brandSubtitle;
  final String formTitle;
  final String usernameLabel;
  final String usernameHint;
  final String passwordLabel;
  final String passwordHint;
  final String rememberMeLabel;
  final String loginButtonLabel;
  final String rightPanelTitle;
  final String rightPanelSubtitle;

  const AdminLoginSpecModel({
    required this.brandTitle,
    required this.brandSubtitle,
    required this.formTitle,
    required this.usernameLabel,
    required this.usernameHint,
    required this.passwordLabel,
    required this.passwordHint,
    required this.rememberMeLabel,
    required this.loginButtonLabel,
    required this.rightPanelTitle,
    required this.rightPanelSubtitle,
  });
}

/// Mô hình thông tin phiên đăng nhập của Quản trị viên
class AdminSessionModel {
  final String username;
  final String displayName;
  final String roleLabel;
  final DateTime? loginTime;

  const AdminSessionModel({
    required this.username,
    required this.displayName,
    this.roleLabel = 'Quản trị hệ thống',
    this.loginTime,
  });
}

/// Mô hình hồ sơ tài khoản Quản trị viên (có thể đổi tên, mật khẩu, email nhận OTP trong /admin)
class AdminProfileModel {
  final String username;
  final String displayName;
  final String email;
  final String password;
  final String roleLabel;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  const AdminProfileModel({
    required this.username,
    required this.displayName,
    required this.email,
    required this.password,
    this.roleLabel = 'Quản trị viên cấp cao',
    this.lastLoginAt,
    required this.createdAt,
  });

  AdminProfileModel copyWith({
    String? username,
    String? displayName,
    String? email,
    String? password,
    String? roleLabel,
    DateTime? lastLoginAt,
    DateTime? createdAt,
  }) {
    return AdminProfileModel(
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      password: password ?? this.password,
      roleLabel: roleLabel ?? this.roleLabel,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'display_name': displayName,
      'email': email,
      'password': password,
      'role_label': roleLabel,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AdminProfileModel.fromMap(Map<String, dynamic> map) {
    return AdminProfileModel(
      username: map['username'] as String? ?? 'admin',
      displayName: map['display_name'] as String? ?? map['displayName'] as String? ?? 'Quản trị viên',
      email: map['email'] as String? ?? 'cuuho.ai.system@gmail.com',
      password: map['password'] as String? ?? 'admin',
      roleLabel: map['role_label'] as String? ?? map['roleLabel'] as String? ?? 'Quản trị viên cấp cao',
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.tryParse(map['last_login_at'] as String)
          : (map['lastLoginAt'] != null ? DateTime.tryParse(map['lastLoginAt'] as String) : null),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now() : DateTime.now()),
    );
  }
}
