import 'package:flutter/material.dart';

import '../../../core/history/analysis_history_service.dart';
import '../../../core/user_management/user_account_service.dart';
import '../models/admin_dashboard_models.dart';
import 'admin_navigation_viewmodel.dart';

mixin DashboardQuanTriViewModel on DieuHuongQuanTriViewModel {
  // Tiêu đề chính trên Màn hình 10
  final String dashboardScreenTitle = 'Dashboard';

  // Tiêu đề của 2 thẻ lớn ở hàng dưới
  final String injuryStatsCardTitle = 'Thống kê loại tổn thương';
  final String recentActivitiesCardTitle = 'Hoạt động gần đây';

  // Số liệu trung tâm biểu đồ Donut (Tính từ số ca thực tế trong Supabase)
  String get donutCenterCountText {
    final count = AnalysisHistoryService.instance.totalScans;
    return count > 0 ? '$count' : '0';
  }

  String get donutCenterUnitText => 'ca';

  // Danh sách 3 Thẻ chỉ số KPI ở hàng trên cùng của Màn hình 10 (Đồng bộ thời gian thực từ Supabase)
  List<AdminKpiCardModel> get kpiCards {
    final scans = AnalysisHistoryService.instance.totalScans;
    final users = UserAccountService.instance.accounts.length;

    return [
      AdminKpiCardModel(
        id: 'total_analyses',
        title: 'Tổng lượt phân tích',
        mainValue: scans > 0 ? '$scans' : '0',
        growthHighlight: scans > 0 ? 'Dữ liệu thực' : 'Đang chờ',
        growthComparisonText: 'đồng bộ Supabase',
        icon: Icons.center_focus_strong_outlined,
        iconColor: const Color(0xFF2563EB),
        iconBackgroundColor: const Color(0xFFE8F1FF),
        valueColor: const Color(0xFF2563EB),
      ),
      const AdminKpiCardModel(
        id: 'total_documents',
        title: 'Tài liệu & Hướng dẫn',
        mainValue: '10',
        growthHighlight: 'Chuẩn hóa',
        growthComparisonText: 'y khoa thẩm định',
        icon: Icons.description_outlined,
        iconColor: Color(0xFF2563EB),
        iconBackgroundColor: Color(0xFFE8F1FF),
        valueColor: Color(0xFF0F172A),
      ),
      AdminKpiCardModel(
        id: 'total_users',
        title: 'Tài khoản người dùng',
        mainValue: users > 0 ? '$users' : '0',
        growthHighlight: users > 0 ? 'Bcrypt pgcrypto' : 'Chưa có',
        growthComparisonText: 'đã bảo mật Cloud',
        icon: Icons.people_alt_outlined,
        iconColor: const Color(0xFF0EA5E9),
        iconBackgroundColor: const Color(0xFFE0F2FE),
        valueColor: const Color(0xFF2563EB),
      ),
    ];
  }

  // Danh sách phân khúc trong "Thống kê loại tổn thương" (Tính tự động theo tỷ lệ thực tế trên Supabase)
  List<AdminInjuryStatItemModel> get injuryDistributionStats {
    final service = AnalysisHistoryService.instance;
    final dist = service.injuryDistribution;
    final total = service.totalScans;

    if (total == 0) {
      return const [
        AdminInjuryStatItemModel(
          id: 'abrasion',
          label: 'Trầy xước',
          percentage: 25,
          color: Color(0xFF3B66F5),
        ),
        AdminInjuryStatItemModel(
          id: 'cut_laceration',
          label: 'Vết cắt / rách da',
          percentage: 25,
          color: Color(0xFF5B8DEF),
        ),
        AdminInjuryStatItemModel(
          id: 'burn',
          label: 'Bỏng',
          percentage: 25,
          color: Color(0xFFEC629A),
        ),
        AdminInjuryStatItemModel(
          id: 'bruise',
          label: 'Bầm',
          percentage: 25,
          color: Color(0xFFF5A623),
        ),
      ];
    }

    final colors = [
      const Color(0xFF3B66F5),
      const Color(0xFF5B8DEF),
      const Color(0xFFEC629A),
      const Color(0xFFF5A623),
      const Color(0xFF48B89F),
    ];

    int idx = 0;
    return dist.entries.map((e) {
      final pct = ((e.value / total) * 100).round();
      final color = colors[idx % colors.length];
      idx++;
      return AdminInjuryStatItemModel(
        id: 'stat_${e.key}',
        label: e.key,
        percentage: pct,
        color: color,
      );
    }).toList();
  }

  // Danh sách 4 mục trong thẻ "Hoạt động gần đây" trên Màn hình 10
  final List<AdminRecentActivityModel> recentActivities = const [
    AdminRecentActivityModel(
      id: 'act_1',
      title: 'Đồng bộ Supabase PostgreSQL',
      relativeTime: 'Vừa xong',
      icon: Icons.cloud_done_outlined,
    ),
    AdminRecentActivityModel(
      id: 'act_2',
      title: 'Cập nhật Rule Engine an toàn',
      relativeTime: 'Hôm nay',
      icon: Icons.rule_outlined,
    ),
    AdminRecentActivityModel(
      id: 'act_3',
      title: 'Xác thực tài khoản bằng Bcrypt',
      relativeTime: 'Hôm nay',
      icon: Icons.security_rounded,
    ),
    AdminRecentActivityModel(
      id: 'act_4',
      title: 'Lịch sử quét hình ảnh AI',
      relativeTime: 'Thời gian thực',
      icon: Icons.center_focus_strong_outlined,
    ),
  ];
}
