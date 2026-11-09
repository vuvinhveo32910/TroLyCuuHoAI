import '../../../core/storage/local_storage_service.dart';

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/first_aid_models.dart';
import '../models/navigation_model.dart';
import '../models/user_account_model.dart';
import '../../../core/auth/google_auth_service.dart';
import '../../../core/config/google_auth_config.dart';
import '../../../core/email/email_config_service.dart';
import '../../../core/user_management/user_account_service.dart';

mixin DieuHuongCoSoViewModel on ChangeNotifier {
  // Chỉ số màn hình hiện tại:
  // 0 = Trang chủ (Màn hình 1)
  // 1 = Phân tích ảnh AI - Tải/Chụp ảnh (Màn hình 2)
  // 2 = Kết quả phân tích (Màn hình 3)
  // 3 = Hướng dẫn sơ cứu (Màn hình 4)
  // 4 = Tra cứu kiến thức (Màn hình 5)
  // 5 = ChatBox AI (Màn hình 6)
  // 6 = Kho tài liệu y tế - Quản lý tài liệu cục bộ trên thiết bị (Màn hình 7)
  // 7 = Lịch sử phân tích (Màn hình 8)
  int _currentScreenIndex = 0;
  int get currentScreenIndex => _currentScreenIndex;

  // Trạng thái tab đang chọn trên Top Navigation Bar: ['Trang chủ', 'Kiến thức', 'Tài liệu', 'Lịch sử']
  int _selectedNavIndex = 0;
  int get selectedNavIndex => _selectedNavIndex;

  // Trạng thái mục đang chọn trên Sidebar bên trái:
  // 0: Trang chủ, 1: Phân tích ảnh AI, 2: Kiến thức sơ cứu, 3: Tài liệu, 4: Lịch sử phân tích, 5: ChatBox AI
  int _selectedSidebarIndex = 1;
  int get selectedSidebarIndex => _selectedSidebarIndex;

  // Ngăn xếp lịch sử điều hướng màn hình hỗ trợ nút Quay lại (Back button)
  final List<int> _navigationHistory = [0];
  bool get canNavigateBack =>
      _navigationHistory.length > 1 || _currentScreenIndex != 0;

  void _pushScreen(int screenIndex) {
    if (_navigationHistory.isEmpty) {
      _navigationHistory.add(0);
    }
    if (_navigationHistory.last != screenIndex) {
      _navigationHistory.add(screenIndex);
    }
  }

  /// Quay lại màn hình trước đó trong lịch sử, hoặc trở về Trang chủ nếu không còn lịch sử
  void navigateBack() {
    if (_navigationHistory.length > 1) {
      _navigationHistory.removeLast();
      _currentScreenIndex = _navigationHistory.last;
    } else {
      _currentScreenIndex = 0;
      _navigationHistory.clear();
      _navigationHistory.add(0);
    }
    _syncSidebarAndNavIndex();
    notifyListeners();
  }

  /// Chuyển đổi màn hình trực tiếp theo chỉ số (0..7)
  void setScreenIndex(int index) {
    if (index >= 0 && index <= 7) {
      _pushScreen(index);
      _currentScreenIndex = index;
      _syncSidebarAndNavIndex();
      notifyListeners();
    }
  }

  void _syncSidebarAndNavIndex() {
    switch (_currentScreenIndex) {
      case 0:
        _selectedNavIndex = 0;
        _selectedSidebarIndex = 0;
        break;
      case 1:
      case 2:
        _selectedNavIndex = -1;
        _selectedSidebarIndex = 1; // Phân tích ảnh AI
        break;
      case 3:
      case 4:
        _selectedNavIndex = 1; // Kiến thức
        _selectedSidebarIndex = 2; // Kiến thức sơ cứu
        break;
      case 5:
        _selectedNavIndex = -1;
        _selectedSidebarIndex = 5; // ChatBox AI
        break;
      case 6:
        _selectedNavIndex = 2; // Tài liệu
        _selectedSidebarIndex = 3; // Tài liệu
        break;
      case 7:
        _selectedNavIndex = 3; // Lịch sử
        _selectedSidebarIndex = 4; // Lịch sử phân tích
        break;
      default:
        _selectedNavIndex = 0;
        _selectedSidebarIndex = 0;
    }
  }

  // Danh sách tài khoản người dùng đã đăng ký (Đồng bộ với UserAccountService)
  List<UserAccountModel> get registeredAccounts =>
      UserAccountService.instance.accounts;

  // Tài khoản người dùng đang đăng nhập (null = Khách vãng lai)
  UserAccountModel? _currentUser;
  UserAccountModel? get currentUser => _currentUser;

  // Trạng thái tài khoản người dùng: Khách vãng lai (không bắt buộc đăng nhập) hoặc Đã đăng nhập
  bool get isUserLoggedIn => _currentUser != null;

  // Tên người dùng hiển thị (sử dụng username ẩn danh, không lưu tên thật)
  String get currentUserName =>
      _currentUser != null ? '@${_currentUser!.username}' : 'Khách';

  // Tên tài khoản (username) đang đăng nhập
  String? get currentUsername => _currentUser?.username;

  /// Đăng ký tài khoản người dùng mới (chỉ cần username + password, email là tùy chọn)
  /// Tuyệt đối KHÔNG yêu cầu họ tên, số điện thoại hay địa chỉ nhà.
  String? registerUser({
    required String username,
    required String password,
    String? fullName, // Giữ tương thích tham số cũ nếu có gọi
    String? emailOrPhone,
  }) {
    final err = UserAccountService.instance.register(
      username: username,
      password: password,
      emailOrPhone: emailOrPhone,
    );
    if (err != null) return err;

    _currentUser = UserAccountService.instance.findByUsername(username);
    notifyListeners();
    return null;
  }

  /// Cập nhật Hồ sơ thông tin cá nhân & Chỉ số y tế (Lưu trên Supabase, không lưu tên/SĐT/địa chỉ)
  String? updateUserProfile({
    String? gender,
    double? weightKg,
    double? heightCm,
    String? bloodType,
    String? rhFactor,
    List<String>? allergies,
    List<String>? medicalConditions,
    String? otherNotes,
    String? email,
  }) {
    if (_currentUser == null) return 'Bạn chưa đăng nhập tài khoản.';

    final updated = _currentUser!.copyWith(
      gender: gender,
      weightKg: weightKg,
      heightCm: heightCm,
      bloodType: bloodType,
      rhFactor: rhFactor,
      allergies: allergies,
      medicalConditions: medicalConditions,
      otherNotes: otherNotes,
      emailOrPhone: (email != null && email.trim().isNotEmpty)
          ? email.trim()
          : _currentUser!.emailOrPhone,
    );

    _currentUser = updated;
    UserAccountService.instance.updateProfile(updated);
    notifyListeners();
    return null;
  }

  /// Đổi mật khẩu tài khoản đang đăng nhập
  String? changeUserPassword({
    required String oldPassword,
    required String newPassword,
  }) {
    if (_currentUser == null) return 'Bạn chưa đăng nhập tài khoản.';
    if (_currentUser!.password != oldPassword.trim()) {
      return 'Mật khẩu cũ không chính xác. Vui lòng kiểm tra lại.';
    }
    if (newPassword.trim().length < 6) {
      return 'Mật khẩu mới phải có ít nhất 6 ký tự.';
    }

    final updated = _currentUser!.copyWith(password: newPassword.trim());
    _currentUser = updated;
    UserAccountService.instance.changePassword(
      _currentUser!.username,
      newPassword.trim(),
    );
    notifyListeners();
    return null;
  }

  /// Đăng nhập tài khoản bằng username và password
  /// Trả về null nếu thành công, hoặc chuỗi thông báo lỗi nếu thất bại (bao gồm TÀI_KHOẢN_BỊ_KHÓA).
  Future<String?> loginWithCredentials({
    required String username,
    required String password,
    bool rememberMe = true,
  }) async {
    // 1. Thử xác thực trực tiếp qua Stored Procedure Bcrypt trên Supabase
    final res = await UserAccountService.instance.authenticateAsync(
      username: username,
      password: password,
    );

    if (res['success'] == true) {
      _currentUser = res['account'] as UserAccountModel;
      await LocalStorageService.instance.saveUserCredentials(
        rememberMe: rememberMe,
        username: username,
        password: password,
      );
      notifyListeners();
      return null;
    }

    if (res['isLocked'] == true) {
      final reason =
          res['lockReason'] as String? ??
          'Tài khoản của bạn đã bị khóa bởi Quản trị viên.';
      return 'TÀI_KHOẢN_BỊ_KHÓA: $reason';
    }

    // 2. Cơ chế fallback nếu mất kết nối
    final syncResult = UserAccountService.instance.authenticate(
      username: username,
      password: password,
    );
    if (syncResult['success'] == true) {
      _currentUser = syncResult['account'] as UserAccountModel;
      await LocalStorageService.instance.saveUserCredentials(
        rememberMe: rememberMe,
        username: username,
        password: password,
      );
      notifyListeners();
      return null;
    }

    return res['message'] as String? ??
        syncResult['message'] as String? ??
        'Đăng nhập không thành công.';
  }

  /// Đăng nhập bằng tài khoản Google (R1 & R4)
  /// - Phối hợp xác thực qua [GoogleAuthService] (Mock hoặc Live)
  /// - Tạo mới hoặc liên kết tài khoản qua [UserAccountService.signInWithGoogleAsync]
  /// - Cập nhật [_currentUser], lưu phiên làm việc qua [LocalStorageService] và thông báo thay đổi
  /// - Trả về null nếu thành công, hoặc chuỗi thông báo lỗi (bao gồm TÀI_KHOẢN_BỊ_KHÓA)
  Future<String?> loginWithGoogle({
    GoogleAuthService? authServiceOverride,
  }) async {
    final service =
        authServiceOverride ??
        (GoogleAuthConfig.isMockMode
            ? MockGoogleAuthService()
            : LiveGoogleAuthService());

    final authResult = await service.signIn();

    if (authResult.isCancelled) {
      return authResult.errorMessage ?? 'Đăng nhập bằng Google đã bị hủy.';
    }

    if (authResult.needsInteractiveChooser) {
      return 'GOOGLE_ACCOUNT_CHOOSER_REQUIRED';
    }

    if (!authResult.isSuccess ||
        authResult.email == null ||
        authResult.email!.trim().isEmpty ||
        authResult.id == null ||
        authResult.id!.trim().isEmpty) {
      return authResult.errorMessage ??
          'Đăng nhập bằng tài khoản Google không thành công.';
    }

    try {
      final user = await UserAccountService.instance.signInWithGoogleAsync(
        googleId: authResult.id!,
        email: authResult.email!,
        displayName: authResult.displayName,
      );

      if (user.isLocked) {
        final reason =
            user.lockReason ??
            'Tài khoản của bạn đã bị khóa bởi Quản trị viên.';
        return 'TÀI_KHOẢN_BỊ_KHÓA: $reason';
      }

      _currentUser = user;
      await LocalStorageService.instance.saveUserCredentials(
        rememberMe: true,
        username: user.username,
        password: user.password,
      );
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('[UserViewModel] Lỗi khi xử lý đăng nhập Google: $e');
      return 'Không thể kết nối hoặc đồng bộ tài khoản Google: $e';
    }
  }

  /// Đăng nhập hoặc liên kết trực tiếp với tài khoản Google (Gmail) do người dùng chọn/nhập
  /// Đồng bộ trực tiếp lên bảng `user_accounts` trên Supabase Cloud và hỗ trợ nhận OTP qua Gmail đó
  Future<String?> loginWithGoogleAccount({
    required String email,
    String? displayName,
    String? googleId,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return 'Vui lòng nhập địa chỉ Gmail hợp lệ.';
    }

    final resolvedGoogleId = (googleId != null && googleId.trim().isNotEmpty)
        ? googleId.trim()
        : 'google_${cleanEmail.replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

    final resolvedDisplayName =
        (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : cleanEmail.split('@').first;

    return loginWithGoogle(
      authServiceOverride: MockGoogleAuthService(
        mockEmail: cleanEmail,
        mockDisplayName: resolvedDisplayName,
        mockId: resolvedGoogleId,
      ),
    );
  }

  /// Khôi phục phiên đăng nhập người dùng từ bộ nhớ cục bộ nếu có bật Ghi nhớ
  Future<void> restoreSavedUserSession() async {
    final saved = await LocalStorageService.instance.loadUserCredentials();
    if (saved['isLoggedIn'] != true) return;
    if (saved['rememberMe'] != true) return;

    final user = saved['username'] as String? ?? '';
    final pass = saved['password'] as String? ?? '';
    if (user.isEmpty) return;

    // Đối với tài khoản Google (mật khẩu rỗng), kiểm tra bộ nhớ đệm trước
    UserAccountModel? existingUser = UserAccountService.instance.findByUsername(
      user,
    );

    // Nếu chưa có trong cache do bất đồng bộ khởi động, truy vấn trực tiếp Supabase
    if (existingUser == null && pass.isEmpty) {
      existingUser = await UserAccountService.instance.findByUsernameAsync(
        user,
      );
    }

    if (existingUser != null) {
      if (existingUser.isLocked) return;
      if (pass.isEmpty) {
        _currentUser = existingUser;
        notifyListeners();
        return;
      }
    }

    // Chỉ khi không tìm thấy trong cache và pass.isNotEmpty, fall back to loginWithCredentials
    if (pass.isNotEmpty) {
      debugPrint(
        '[UserAuth] Đang tự động khôi phục tài khoản người dùng: $user',
      );
      await loginWithCredentials(
        username: user,
        password: pass,
        rememberMe: true,
      );
    }
  }

  /// Đăng xuất tài khoản người dùng về chế độ Khách (Guest)
  Future<void> logoutUser() async {
    _currentUser = null;
    await LocalStorageService.instance.clearUserSession();
    notifyListeners();
  }

  /// Yêu cầu gửi mã OTP khôi phục mật khẩu qua Email (Lưu tạm và xử lý trên Supabase Cloud)
  /// Đối với tài khoản Google, đảm bảo giải quyết chính xác địa chỉ Gmail liên kết (R3)
  Map<String, dynamic> requestPasswordResetOtp(String identifier) {
    final cleanId = identifier.trim().toLowerCase();
    if (cleanId.isEmpty) {
      return {
        'success': false,
        'message': 'Vui lòng nhập tên tài khoản hoặc địa chỉ email của bạn.',
      };
    }

    UserAccountModel? targetUser;
    for (final acc in UserAccountService.instance.accounts) {
      // 1. So khớp theo tên tài khoản
      if (acc.username.toLowerCase() == cleanId) {
        targetUser = acc;
        break;
      }
      // 2. So khớp theo email/phone
      if (acc.emailOrPhone != null &&
          acc.emailOrPhone!.trim().toLowerCase() == cleanId) {
        targetUser = acc;
        break;
      }
      // 3. Đối với tài khoản liên kết Google, hỗ trợ nhận diện qua Gmail liên kết
      if (acc.isGoogleLinked &&
          acc.emailOrPhone != null &&
          acc.emailOrPhone!.trim().toLowerCase() == cleanId) {
        targetUser = acc;
        break;
      }
    }

    if (targetUser == null) {
      return {
        'success': false,
        'message':
            'Không tìm thấy tài khoản tương ứng với "$identifier" trong hệ thống.',
      };
    }

    // Đảm bảo lấy chính xác địa chỉ Gmail liên kết với tài khoản
    final targetEmail = targetUser.emailOrPhone?.trim() ?? '';
    if (targetEmail.isEmpty) {
      return {
        'success': false,
        'message': 'Tài khoản này chưa thiết lập email khôi phục. Vui lòng liên hệ quản trị viên.',
      };
    }

    final result = EmailConfigService.instance.generateAndDispatchOtp(
      identifier: targetUser.username,
      targetEmail: targetEmail,
      username: targetUser.username,
    );

    return result;
  }

  /// Xác thực mã OTP và cập nhật mật khẩu mới cho tài khoản trên Supabase Cloud
  String? verifyAndResetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) {
    final cleanId = identifier.trim().toLowerCase();
    final cleanOtp = otp.trim();
    final cleanPass = newPassword.trim();

    if (cleanPass.length < 6) {
      return 'Mật khẩu mới phải có ít nhất 6 ký tự.';
    }

    final verifyResult = EmailConfigService.instance.verifyOtp(
      identifier: cleanId,
      otpInput: cleanOtp,
    );

    if (verifyResult['valid'] != true) {
      return verifyResult['message'] as String? ??
          'Mã OTP không hợp lệ hoặc đã hết hạn.';
    }

    final record = verifyResult['record'] as PendingOtpRecord;
    final user = UserAccountService.instance.findByUsername(record.username);

    if (user == null) {
      return 'Không tìm thấy tài khoản tương ứng để cập nhật mật khẩu.';
    }

    // Đặt lại mật khẩu (hỗ trợ cả tài khoản Google chưa có mật khẩu cũ mà không gây lỗi RPC)
    UserAccountService.instance.resetPasswordAsync(
      usernameOrEmail: user.username,
      newPassword: cleanPass,
    );
    if (_currentUser?.username.toLowerCase() == user.username.toLowerCase()) {
      _currentUser = _currentUser!.copyWith(password: cleanPass);
    }

    EmailConfigService.instance.consumeOtp(cleanId);
    notifyListeners();
    return null; // Thành công
  }

  /// Đăng nhập nhanh tương thích ngược
  void loginUser([String name = 'Nguyễn Văn A']) {
    _currentUser = UserAccountModel(
      username: 'user_${DateTime.now().millisecondsSinceEpoch}',
      password: '',
      fullName: name,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  // Trạng thái tên file ảnh đã chọn/chụp giả lập
  String? _selectedImageName;
  String? get selectedImageName => _selectedImageName;

  // Chủ đề hướng dẫn sơ cứu đang được chọn để hiển thị trên Màn hình 4 (Mặc định: 'abrasion' -> 'Trầy xước')
  String _selectedGuideTopicId = 'abrasion';
  String get selectedGuideTopicId => _selectedGuideTopicId;

  // Khai báo getter trừu tượng để kiểm tra hợp lệ chủ đề sơ cứu khi điều hướng
  Map<String, FirstAidGuideModel> get firstAidGuidesByTopic;

  // Hook tự động được gọi khi người dùng chụp/tải ảnh mới để lưu vào Lịch sử phân tích trên Supabase Cloud
  @protected
  void onNewAnalysisRecorded({
    required String imageSourceName,
    String? injuryType,
    int? confidencePercent,
    String? locationLabel,
    String? topicId,
    Uint8List? rawImageBytes,
  }) {}

  // Danh sách 4 mục menu ngang trên Top Navigation Bar
  final List<String> navItems = const [
    'Trang chủ',
    'Kiến thức',
    'Tài liệu',
    'Lịch sử',
  ];

  // Danh sách 6 mục menu dọc trên Sidebar bên trái (Đã loại bỏ Hướng dẫn sơ cứu trùng lặp và hợp nhất vào Kiến thức sơ cứu)
  final List<SidebarMenuItemModel> sidebarMenuItems = const [
    SidebarMenuItemModel(
      id: 'home',
      title: 'Trang chủ',
      icon: Icons.home_outlined,
    ),
    SidebarMenuItemModel(
      id: 'ai_analysis',
      title: 'Phân tích ảnh AI',
      icon: Icons.center_focus_strong_outlined,
    ),
    SidebarMenuItemModel(
      id: 'knowledge',
      title: 'Kiến thức sơ cứu',
      icon: Icons.menu_book_outlined,
    ),
    SidebarMenuItemModel(
      id: 'documents',
      title: 'Tài liệu',
      icon: Icons.description_outlined,
    ),
    SidebarMenuItemModel(
      id: 'analysis_history',
      title: 'Lịch sử phân tích',
      icon: Icons.history_outlined,
    ),
    SidebarMenuItemModel(
      id: 'ai_chatbox',
      title: 'ChatBox AI',
      icon: Icons.smart_toy_outlined,
    ),
  ];

  // =========================================================================
  // LOGIC ĐIỀU HƯỚNG XUYÊN SUỐT GIỮA CÁC MÀN HÌNH
  // =========================================================================

  /// Chuyển sang Màn hình 1: Trang chủ
  void navigateToHome() {
    _currentScreenIndex = 0;
    _navigationHistory.clear();
    _navigationHistory.add(0);
    _syncSidebarAndNavIndex();
    notifyListeners();
  }

  /// Chuyển sang Màn hình 2: Phân tích ảnh AI (Tải ảnh / Chụp ảnh)
  void navigateToAiAnalysis() {
    _pushScreen(1);
    _currentScreenIndex = 1;
    _syncSidebarAndNavIndex();
    notifyListeners();
  }

  /// Chuyển sang Màn hình 3: Kết quả phân tích (Người dùng)
  /// Tự động kích hoạt lưu bản ghi vào Lịch sử phân tích nếu recordHistory == true
  void navigateToAnalysisResult({
    String? imageSourceName,
    bool recordHistory = true,
  }) {
    _selectedImageName = imageSourceName;
    if (recordHistory &&
        imageSourceName != null &&
        imageSourceName.trim().isNotEmpty) {
      onNewAnalysisRecorded(imageSourceName: imageSourceName.trim());
    }
    _pushScreen(2);
    _currentScreenIndex = 2;
    _syncSidebarAndNavIndex();
    notifyListeners();
  }

  /// Chuyển sang Chi tiết Hướng dẫn sơ cứu (Dưới phân hệ Kiến thức sơ cứu)
  void navigateToFirstAidGuide({String? topicId}) {
    if (topicId != null && firstAidGuidesByTopic.containsKey(topicId)) {
      _selectedGuideTopicId = topicId;
    }
    _pushScreen(3);
    _currentScreenIndex = 3;
    _syncSidebarAndNavIndex();
    notifyListeners();
  }

  /// Chuyển sang Màn hình Tra cứu kiến thức sơ cứu (Người dùng)
  void navigateToKnowledgeLookup() {
    _pushScreen(4);
    _currentScreenIndex = 4;
    _syncSidebarAndNavIndex();
    notifyListeners();
  }

  /// Chuyển sang Màn hình ChatBox AI (Người dùng)
  void navigateToChatBoxAi() {
    _pushScreen(5);
    _currentScreenIndex = 5;
    _syncSidebarAndNavIndex();
    notifyListeners();
  }

  /// Chuyển sang Kho tài liệu y tế (Quản lý tài liệu lưu trữ cục bộ trên thiết bị)
  void navigateToMedicalDocuments() {
    _pushScreen(6);
    _currentScreenIndex = 6;
    _syncSidebarAndNavIndex();
    notifyListeners();
  }

  /// Chuyển sang Lịch sử phân tích (Người dùng)
  void navigateToAnalysisHistory() {
    _pushScreen(7);
    _currentScreenIndex = 7;
    _syncSidebarAndNavIndex();
    notifyListeners();
  }

  /// Xử lý khi bấm chọn mục trên Top Navigation Bar: ['Trang chủ', 'Kiến thức', 'Tài liệu', 'Lịch sử']
  void selectNavIndex(int index) {
    if (index == 0) {
      navigateToHome();
    } else if (index == 1) {
      navigateToKnowledgeLookup();
    } else if (index == 2) {
      navigateToMedicalDocuments();
    } else if (index == 3) {
      navigateToAnalysisHistory();
    }
  }

  /// Xử lý khi bấm chọn mục trên thanh Sidebar bên trái:
  /// 0: Trang chủ, 1: Phân tích ảnh AI, 2: Kiến thức sơ cứu, 3: Tài liệu, 4: Lịch sử phân tích, 5: ChatBox AI
  void selectSidebarIndex(int index) {
    if (index == 0) {
      navigateToHome();
    } else if (index == 1) {
      navigateToAiAnalysis();
    } else if (index == 2) {
      navigateToKnowledgeLookup();
    } else if (index == 3) {
      navigateToMedicalDocuments();
    } else if (index == 4) {
      navigateToAnalysisHistory();
    } else if (index == 5) {
      navigateToChatBoxAi();
    }
  }

  void onProfileAvatarPressed() {
    debugPrint(
      '[UserViewModel] Bấm vào thông tin người dùng: $currentUserName',
    );
  }
}
