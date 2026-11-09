// File: lib/views/userview/lich_su_phan_tich_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/history_models.dart';
import '../viewmodels/user_viewmodel.dart';

class LichSuPhanTichView extends StatelessWidget {
  const LichSuPhanTichView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();
    final allHistoryItems = viewModel.filteredAnalysisHistoryItems;
    final historyItems = viewModel.paginatedAnalysisHistoryItems;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 16 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile) ...[
            Row(
              children: [
                IconButton(
                  onPressed: () =>
                      context.read<UserViewModel>().navigateBack(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF0D2B6B),
                    size: 22,
                  ),
                  tooltip: 'Quay lại',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    hoverColor: const Color(0xFFE2E8F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Lịch sử phân tích',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D2B6B),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          _buildFilterRow(context, viewModel),
          const SizedBox(height: 18),
          if (allHistoryItems.isEmpty)
            _buildEmptyState(context, viewModel)
          else ...[
            Column(
              children: List.generate(historyItems.length, (index) {
                final item = historyItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHistoryItemCard(
                    context,
                    viewModel,
                    item,
                    isMobile: isMobile,
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            _buildHistoryPaginationBar(context, viewModel, isMobile: isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, UserViewModel viewModel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 620;

        final dateFilterBox = _buildDateRangeFilterButton(context, viewModel);
        final resultDropdownBox = _buildResultTypeDropdown(context, viewModel);

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              dateFilterBox,
              const SizedBox(height: 10),
              resultDropdownBox,
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 5, child: dateFilterBox),
            const SizedBox(width: 16),
            Expanded(flex: 5, child: resultDropdownBox),
          ],
        );
      },
    );
  }

  Widget _buildDateRangeFilterButton(
    BuildContext context,
    UserViewModel viewModel,
  ) {
    final hasDateFilter =
        viewModel.historyFromDate != null || viewModel.historyToDate != null;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final pickedRange = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDateRange:
              viewModel.historyFromDate != null &&
                  viewModel.historyToDate != null
              ? DateTimeRange(
                  start: viewModel.historyFromDate!,
                  end: viewModel.historyToDate!,
                )
              : null,
          helpText: 'Chọn khoảng thời gian phân tích',
          cancelText: 'Hủy',
          confirmText: 'Áp dụng',
        );
        if (pickedRange != null) {
          viewModel.setHistoryDateRange(pickedRange);
        }
      },
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD8E2EE), width: 1),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_outlined,
              size: 19,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                viewModel.formattedDateRangeLabel,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: hasDateFilter ? FontWeight.w600 : FontWeight.w500,
                  color: hasDateFilter
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF475569),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasDateFilter)
              InkWell(
                onTap: () => viewModel.clearHistoryDateRange(),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTypeDropdown(
    BuildContext context,
    UserViewModel viewModel,
  ) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8E2EE), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 19,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: viewModel.selectedHistoryResultFilter,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF475569),
                  size: 22,
                ),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155),
                ),
                items: viewModel.historyResultFilterOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) => viewModel.setHistoryResultFilter(value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItemCard(
    BuildContext context,
    UserViewModel viewModel,
    AnalysisHistoryItemModel item, {
    bool isMobile = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => viewModel.onHistoryItemTapped(item),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EEF5), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060D2B6B),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildWoundThumbnail(item),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayTitle,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMobile
                          ? '${item.locationLabel} • ${item.timestamp}'
                          : item.locationLabel,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                Text(
                  item.timestamp,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWoundThumbnail(AnalysisHistoryItemModel item) {
    if (item.rawImageBytes != null && item.rawImageBytes!.isNotEmpty) {
      return Container(
        width: 60,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          item.rawImageBytes!,
          fit: BoxFit.cover,
          cacheWidth: 160,
          cacheHeight: 160,
        ),
      );
    }

    final isClear = item.confidencePercent == null;

    return Container(
      width: 60,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.baseSkinColor,
            Color.lerp(item.baseSkinColor, const Color(0xFFB57B62), 0.35)!,
          ],
        ),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: isClear ? 14 : 26,
            height: isClear ? 14 : 20,
            decoration: BoxDecoration(
              color: item.woundAccentColor.withValues(
                alpha: isClear ? 0.25 : 0.42,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          if (!isClear)
            Container(
              width: 13,
              height: 7,
              decoration: BoxDecoration(
                color: item.woundAccentColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, UserViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.history_toggle_off_outlined,
            size: 42,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 10),
          const Text(
            'Không tìm thấy bản ghi lịch sử phù hợp với bộ lọc.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              viewModel.clearHistoryDateRange();
              viewModel.setHistoryResultFilter('Tất cả kết quả');
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Đặt lại bộ lọc'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPaginationBar(
    BuildContext context,
    UserViewModel viewModel, {
    bool isMobile = false,
  }) {
    final totalItems = viewModel.filteredAnalysisHistoryItems.length;
    final totalPages = viewModel.totalHistoryPages;
    final currentPage = viewModel.currentHistoryPage;
    final pageSize = 5;

    if (totalItems == 0) return const SizedBox.shrink();

    final startItem = (currentPage - 1) * pageSize + 1;
    final endItem = (currentPage * pageSize > totalItems) ? totalItems : currentPage * pageSize;
    final infoText = 'Hiển thị $startItem - $endItem trên tổng số $totalItems ca phân tích (5 ca / trang)';

    final paginationControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: currentPage > 1 ? () => viewModel.goToPreviousHistoryPage() : null,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: currentPage > 1 ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        ...List.generate(totalPages, (i) {
          final pageNum = i + 1;
          final isSelected = pageNum == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: isSelected ? const Color(0xFF2563EB) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => viewModel.selectHistoryPage(pageNum),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 6),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: currentPage < totalPages ? () => viewModel.goToNextHistoryPage() : null,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: currentPage < totalPages ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: [
          Text(infoText, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          paginationControls,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(infoText, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        paginationControls,
      ],
    );
  }
}
