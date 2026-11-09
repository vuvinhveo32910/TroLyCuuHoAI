import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Thanh phân trang chuẩn phong cách Kho tài liệu y tế dành cho trang Quản trị (Admin)
Widget buildAdminPaginationFooter({
  required int currentPage,
  required int totalPages,
  required int totalItems,
  required int pageSize,
  required String itemLabel,
  required ValueChanged<int> onPageSelected,
  required VoidCallback onPrevious,
  required VoidCallback onNext,
  bool isMobile = false,
}) {
  if (totalItems == 0) return const SizedBox.shrink();

  final startItem = (currentPage - 1) * pageSize + 1;
  final endItem = math.min(currentPage * pageSize, totalItems);
  final infoText = 'Hiển thị $startItem - $endItem trên tổng số $totalItems $itemLabel';

  final paginationControls = Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Nút Trước (<)
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: currentPage > 1 ? onPrevious : null,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: currentPage > 1 ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: currentPage > 1 ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
        ),
      ),
      const SizedBox(width: 6),

      // Các nút số trang (1, 2, 3...)
      ...List.generate(totalPages, (index) {
        final page = index + 1;
        final isSelected = page == currentPage;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Material(
            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onPageSelected(page),
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  '$page',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
      const SizedBox(width: 6),

      // Nút Sau (>)
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: currentPage < totalPages ? onNext : null,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: currentPage < totalPages ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: currentPage < totalPages ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
        ),
      ),
    ],
  );

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x060D2B6B),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: isMobile
        ? Column(
            children: [
              Text(
                infoText,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              paginationControls,
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.table_rows_rounded, size: 17, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Text(
                    infoText,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              paginationControls,
            ],
          ),
  );
}

