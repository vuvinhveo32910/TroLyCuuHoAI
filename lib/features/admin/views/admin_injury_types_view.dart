import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/rule_engine/rule_models.dart';
import '../viewmodels/admin_management_viewmodel.dart';
import '../viewmodels/admin_viewmodel.dart';
import 'widgets/admin_pagination_footer.dart';

// =============================================================================
// 2. VIEW QUẢN LÝ LOẠI TỔN THƯƠNG (Injury Types)
// =============================================================================
class AdminInjuryTypesView extends StatelessWidget {
  const AdminInjuryTypesView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final allTypes = viewModel.supportedInjuryTypes;
    final paginatedTypes = viewModel.paginatedInjuryTypes;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 16 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Quản lý nhóm loại tổn thương',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D2B6B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cấu hình các loại tổn thương mô hình YOLO nhận diện và ngưỡng tin cậy áp dụng (5 nhóm / trang)',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paginatedTypes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final t = paginatedTypes[index];
              final severity = t.defaultSeverity;

              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: severity.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: severity.borderColor),
                          ),
                          child: Icon(severity.icon, color: severity.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    t.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0D2B6B),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: severity.backgroundColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: severity.borderColor),
                                    ),
                                    child: Text(
                                      severity.label,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: severity.color),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(t.description, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Switch(
                          value: t.isAiDetectionEnabled,
                          activeTrackColor: const Color(0xFF2563EB),
                          onChanged: (_) => viewModel.toggleInjuryTypeAiDetection(t.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),

                    // Thông tin số lượt quét và trạng thái nhận diện AI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              t.isAiDetectionEnabled ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                              size: 16,
                              color: t.isAiDetectionEnabled ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t.isAiDetectionEnabled ? 'Mô hình YOLO đang nhận diện nhóm này' : 'Tạm dừng nhận diện AI',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: t.isAiDetectionEnabled ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Đã quét: ${t.totalScansRecorded} lượt',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2. MỨC ĐỘ NGHIÊM TRỌNG Y TẾ MẶC ĐỊNH
                    Row(
                      children: [
                        const Text(
                          'Mức độ y tế mặc định:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ...RuleSeverityLevel.values.map((sev) {
                          final isSelected = t.defaultSeverity == sev;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => viewModel.updateInjuryTypeSeverity(t.id, sev),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isSelected ? sev.backgroundColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? sev.color : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      sev.icon,
                                      size: 13,
                                      color: isSelected ? sev.color : const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      sev.label.split(' - ').first,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? sev.color : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          buildAdminPaginationFooter(
            currentPage: viewModel.currentInjuryTypePage,
            totalPages: viewModel.totalInjuryTypePages,
            totalItems: allTypes.length,
            pageSize: AdminManagementViewModel.injuryTypePageSize,
            itemLabel: 'nhóm tổn thương',
            onPageSelected: (page) => viewModel.selectInjuryTypePage(page),
            onPrevious: () => viewModel.goToPreviousInjuryTypePage(),
            onNext: () => viewModel.goToNextInjuryTypePage(),
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }
}


