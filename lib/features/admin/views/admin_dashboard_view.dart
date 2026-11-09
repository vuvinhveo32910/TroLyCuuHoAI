// File: lib/views/adminview/dashboard_quan_tri_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/admin_dashboard_models.dart';
import '../viewmodels/admin_viewmodel.dart';
import 'widgets/admin_painters.dart';

class DashboardQuanTriView extends StatelessWidget {
  const DashboardQuanTriView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 16 : 26,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile) ...[
            Text(
              viewModel.dashboardScreenTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D2B6B),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (viewModel.totalAiFeedbackCount > 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.rate_review_rounded, color: Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hệ thống ghi nhận ${viewModel.totalAiFeedbackCount} lượt đánh giá từ người dùng (${viewModel.inaccurateAiReportCount} báo cáo sai lệch). Bạn có thể xem chi tiết để phân tích và cải thiện mô hình.',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final idx = viewModel.adminSidebarItems.indexWhere((it) => it.id == 'ai_feedback_audit');
                      if (idx != -1) viewModel.selectAdminSidebarIndex(idx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Xem đánh giá', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
          _buildKpiCardsRow(viewModel.kpiCards),
          SizedBox(height: isMobile ? 16 : 22),
          _buildBottomAnalyticsSection(viewModel),
        ],
      ),
    );
  }

  Widget _buildKpiCardsRow(List<AdminKpiCardModel> kpiCards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;

        if (isCompact) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: kpiCards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildSingleKpiCard(card),
                  ),
                )
                .toList(),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(kpiCards.length, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < kpiCards.length - 1 ? 18 : 0,
                ),
                child: _buildSingleKpiCard(kpiCards[index]),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSingleKpiCard(AdminKpiCardModel card) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF5), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080D2B6B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: card.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(card.icon, size: 20, color: card.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  card.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              card.mainValue,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: card.valueColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: '${card.growthHighlight} ',
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: card.growthComparisonText,
                    style: const TextStyle(color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAnalyticsSection(AdminViewModel viewModel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        final estimatedLeftCardInnerWidth = isWide
            ? ((constraints.maxWidth - 18) * 0.62) - 48
            : constraints.maxWidth - 48;
        final isNarrowInjuryCard = estimatedLeftCardInnerWidth < 430;

        final injuryChartCard = _buildInjuryStatisticsCard(
          viewModel,
          isNarrowCard: isNarrowInjuryCard,
        );
        final recentActivityCard = _buildRecentActivitiesCard(viewModel);

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 62, child: injuryChartCard),
              const SizedBox(width: 18),
              Expanded(flex: 38, child: recentActivityCard),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            injuryChartCard,
            const SizedBox(height: 16),
            recentActivityCard,
          ],
        );
      },
    );
  }

  Widget _buildInjuryStatisticsCard(
    AdminViewModel viewModel, {
    required bool isNarrowCard,
  }) {
    final donutChartWidget = SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(180, 180),
            painter: AdminInjuryDonutChartPainter(
              segments: viewModel.injuryDistributionStats,
              strokeWidth: 32,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                viewModel.donutCenterCountText,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                viewModel.donutCenterUnitText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final legendWidget = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: viewModel.injuryDistributionStats.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              Text(
                item.formattedPercentage,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF5), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080D2B6B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewModel.injuryStatsCardTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          if (isNarrowCard)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                donutChartWidget,
                const SizedBox(height: 18),
                legendWidget,
              ],
            )
          else
            Row(
              children: [
                const SizedBox(width: 8),
                donutChartWidget,
                const SizedBox(width: 28),
                Expanded(child: legendWidget),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesCard(AdminViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF5), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080D2B6B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewModel.recentActivitiesCardTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(viewModel.recentActivities.length, (index) {
              final activity = viewModel.recentActivities[index];
              final isLast = index == viewModel.recentActivities.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        activity.icon,
                        size: 19,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity.relativeTime,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
