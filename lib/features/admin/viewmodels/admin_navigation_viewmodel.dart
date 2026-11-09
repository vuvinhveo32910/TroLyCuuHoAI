import 'package:flutter/material.dart';

import '../models/admin_dashboard_models.dart';

mixin DieuHuongQuanTriViewModel on ChangeNotifier {
  // Trạng thái đang mở phân hệ Quản trị (true) hay phân hệ Người dùng (false)
  bool _isAdminPortalActive = false;
  bool get isAdminPortalActive => _isAdminPortalActive;

  // Chỉ số màn hình trong phân hệ Quản trị:
  // 0 = Đăng nhập quản trị (Màn hình 9)
  // 1 = Không gian làm việc Quản trị sau khi đăng nhập (Màn hình 10: Dashboard)
  int _currentAdminScreenIndex = 0;
  int get currentAdminScreenIndex => _currentAdminScreenIndex;

  // Trạng thái đã xác thực tài khoản quản trị thành công hay chưa
  bool _isAdminAuthenticated = false;
  bool get isAdminAuthenticated => _isAdminAuthenticated;

  // Chỉ số mục đang chọn trên thanh Sidebar bên trái của Quản trị (Mặc định: 1 = Dashboard)
  int _selectedAdminSidebarIndex = 1;
  int get selectedAdminSidebarIndex => _selectedAdminSidebarIndex;

  // Danh sách các mục menu dọc trên Sidebar Quản trị
  final List<AdminSidebarItemModel> adminSidebarItems = const [
    AdminSidebarItemModel(
      id: 'admin_root',
      title: 'Quản trị',
      icon: Icons.home_outlined,
      hasTrailingChevron: true,
    ),
    AdminSidebarItemModel(
      id: 'dashboard',
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
    ),
    AdminSidebarItemModel(
      id: 'ai_feedback_audit',
      title: 'Đánh giá từ người dùng',
      icon: Icons.rate_review_outlined,
    ),
    AdminSidebarItemModel(
      id: 'knowledge_base',
      title: 'Knowledge Base',
      icon: Icons.menu_book_outlined,
    ),
    AdminSidebarItemModel(
      id: 'injury_types',
      title: 'Loại tổn thương',
      icon: Icons.shield_outlined,
    ),
    AdminSidebarItemModel(
      id: 'rule_engine',
      title: 'Rule Engine',
      icon: Icons.tune_outlined,
    ),
    AdminSidebarItemModel(
      id: 'history_analytics',
      title: 'Lịch sử & Thống kê',
      icon: Icons.analytics_outlined,
    ),
    AdminSidebarItemModel(
      id: 'user_management',
      title: 'Quản lý người dùng',
      icon: Icons.people_alt_outlined,
    ),
    AdminSidebarItemModel(
      id: 'admin_profile',
      title: 'Hồ sơ tài khoản',
      icon: Icons.badge_outlined,
    ),
    AdminSidebarItemModel(
      id: 'settings',
      title: 'Cấu hình',
      icon: Icons.settings_outlined,
      hasTrailingChevron: true,
    ),
  ];

  /// Đồng bộ trạng thái cổng Quản trị ngay khi khởi chạy ứng dụng từ URL trình duyệt (/admin)
  void syncPortalWithUrl({required bool isAdminUrl}) {
    _isAdminPortalActive = isAdminUrl;
    if (isAdminUrl && !_isAdminAuthenticated) {
      _currentAdminScreenIndex = 0; // Luôn mở Màn hình 9: Đăng nhập quản trị
    }
  }

  /// Mở cổng Quản trị hệ thống (Chuyển từ giao diện Người dùng sang Màn hình 9)
  void openAdminPortal() {
    _isAdminPortalActive = true;
    if (!_isAdminAuthenticated) {
      _currentAdminScreenIndex = 0;
    } else {
      _currentAdminScreenIndex = 1;
    }
    notifyListeners();
  }

  /// Quay trở lại giao diện Người dùng (Màn hình 1 - 8)
  void exitAdminPortalToUserApp() {
    _isAdminPortalActive = false;
    notifyListeners();
  }

  /// Điều hướng tới Màn hình 10 (Dashboard quản trị) sau khi đăng nhập thành công ở Màn hình 9
  void completeAdminAuthentication() {
    _isAdminAuthenticated = true;
    _currentAdminScreenIndex = 1;
    _selectedAdminSidebarIndex = 1;
    notifyListeners();
  }

  /// Xử lý khi bấm chọn một mục trên thanh Sidebar Quản trị bên trái
  void selectAdminSidebarIndex(int index) {
    if (index == 0) {
      _selectedAdminSidebarIndex = 1;
    } else {
      _selectedAdminSidebarIndex = index;
    }
    notifyListeners();
  }

  /// Đăng xuất khỏi phân hệ Quản trị và quay về màn hình "9. Đăng nhập quản trị"
  void logoutAdmin() {
    _isAdminAuthenticated = false;
    _currentAdminScreenIndex = 0;
    notifyListeners();
  }
}
