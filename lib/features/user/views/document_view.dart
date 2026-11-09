// File: lib/views/userview/kho_tai_lieu_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/url_launcher_helper.dart';
import '../models/document_models.dart';
import '../viewmodels/user_viewmodel.dart';
import 'widgets/user_painters.dart';

class KhoTaiLieuView extends StatelessWidget {
  const KhoTaiLieuView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 36,
        vertical: isMobile ? 16 : 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Hàng Tiêu đề + Nút "+ Thêm tài liệu"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (!isMobile) ...[
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
                    ],
                    Expanded(
                      child: Text(
                        isMobile ? 'Tài liệu lưu trữ' : 'Kho tài liệu y tế',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D2B6B),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    _showAddLocalDocumentDialog(context, viewModel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 14 : 20,
                    vertical: isMobile ? 11 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: Text(
                  'Thêm tài liệu',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 22),

          // 2. Thanh tìm kiếm + Dropdown lọc danh mục
          _buildDocumentsSearchAndDropdownRow(context, viewModel),
          SizedBox(height: isMobile ? 14 : 22),

          // 3. Khu vực chính: Danh mục + Danh sách tài liệu
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideContent = constraints.maxWidth >= 680;

              if (isWideContent) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 200,
                      child: _buildDocumentCategorySubMenu(
                        context,
                        viewModel,
                        isVertical: true,
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: _buildMedicalDocumentsTableCard(
                        context,
                        viewModel,
                        isMobile: false,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDocumentCategorySubMenu(
                      context,
                      viewModel,
                      isVertical: false,
                    ),
                    const SizedBox(height: 14),
                    _buildMedicalDocumentsTableCard(
                      context,
                      viewModel,
                      isMobile: isMobile,
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 18),

          // 4. Thanh phân trang (5 tài liệu / trang)
          _buildDocumentsPaginationBar(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildDocumentsSearchAndDropdownRow(
    BuildContext context,
    UserViewModel viewModel,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;

        final searchBox = Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD8E3F2), width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: TextField(
            controller: viewModel.documentSearchController,
            onChanged: (value) =>
                context.read<UserViewModel>().updateDocumentSearchQuery(value),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              icon: Icon(
                Icons.search_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              hintText: 'Tìm kiếm tài liệu...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );

        final categoryDropdown = Container(
          height: 46,
          width: isCompact ? double.infinity : 210,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD8E3F2), width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: viewModel.selectedDocumentCategoryId,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF475569),
                size: 22,
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(10),
              items: viewModel.documentCategories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat.id,
                  child: Text(
                    cat.dropdownLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (selectedId) {
                if (selectedId != null) {
                  context.read<UserViewModel>().selectDocumentCategory(
                    selectedId,
                  );
                }
              },
            ),
          ),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [searchBox, const SizedBox(height: 10), categoryDropdown],
          );
        }

        return Row(
          children: [
            Expanded(child: searchBox),
            const SizedBox(width: 14),
            categoryDropdown,
          ],
        );
      },
    );
  }

  Widget _buildDocumentCategorySubMenu(
    BuildContext context,
    UserViewModel viewModel, {
    required bool isVertical,
  }) {
    if (!isVertical) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: viewModel.documentCategories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildSingleDocumentCategoryItem(context, viewModel, cat),
            );
          }).toList(),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: viewModel.documentCategories.map((cat) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _buildSingleDocumentCategoryItem(context, viewModel, cat),
        );
      }).toList(),
    );
  }

  Widget _buildSingleDocumentCategoryItem(
    BuildContext context,
    UserViewModel viewModel,
    MedicalDocumentCategoryModel category,
  ) {
    final isSelected = viewModel.selectedDocumentCategoryId == category.id;
    final displayLabel = viewModel.getDocumentCategorySidebarLabel(category);

    return Material(
      color: isSelected ? const Color(0xFFE8F1FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () =>
            context.read<UserViewModel>().selectDocumentCategory(category.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CustomPaint(
                  painter: DocumentSubCategoryIconPainter(
                    categoryId: category.id,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  displayLabel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalDocumentsTableCard(
    BuildContext context,
    UserViewModel viewModel, {
    required bool isMobile,
  }) {
    final docs = viewModel.filteredMedicalDocuments;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050D2B6B),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile) ...[
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: const [
                  Expanded(
                    flex: 52,
                    child: Text(
                      'Tên tài liệu',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 28,
                    child: Text(
                      'Danh mục',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 20,
                    child: Text(
                      'Ngày thêm',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE8EEF5)),
          ],
          if (docs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 42, horizontal: 20),
              child: Center(
                child: Text(
                  'Không tìm thấy tài liệu y tế phù hợp.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ...List.generate(docs.length, (index) {
              final doc = docs[index];
              final isLast = index == docs.length - 1;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSingleMedicalDocumentRow(
                    context,
                    viewModel,
                    doc,
                    isMobile: isMobile,
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSingleMedicalDocumentRow(
    BuildContext context,
    UserViewModel viewModel,
    MedicalDocumentModel doc, {
    required bool isMobile,
  }) {
    final isHighlightedBadge = doc.categoryId == 'basic_first_aid';

    if (isMobile) {
      return Material(
        color: Colors.white,
        child: InkWell(
          onTap: () =>
              _showOpenAndManageDocumentDialog(context, viewModel, doc),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF2FE),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const CustomPaint(
                    painter: MedicalDocumentRowIconPainter(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D2B6B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${doc.categoryLabel} • ${doc.dateAdded}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _showOpenAndManageDocumentDialog(context, viewModel, doc),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 52,
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF2FE),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const CustomPaint(
                        painter: MedicalDocumentRowIconPainter(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D2B6B),
                              height: 1.3,
                            ),
                          ),
                          if (doc.isUserAdded) ...[
                            const SizedBox(height: 3),
                            Text(
                              '${doc.fileName} (${doc.fileSize})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 28,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isHighlightedBadge ? 10 : 0,
                      vertical: isHighlightedBadge ? 5 : 0,
                    ),
                    decoration: isHighlightedBadge
                        ? BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          )
                        : null,
                    child: Text(
                      doc.categoryLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 20,
                child: Text(
                  doc.dateAdded,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddLocalDocumentDialog(
    BuildContext context,
    UserViewModel viewModel,
  ) {
    final titleController = TextEditingController();
    final fileNameController = TextEditingController(
      text: viewModel.sampleDeviceFiles.first['fileName'],
    );
    final localPathController = TextEditingController(
      text: viewModel.sampleDeviceFiles.first['localFilePath'],
    );
    final summaryController = TextEditingController();

    String selectedCategoryId = 'basic_first_aid';
    String selectedExtension =
        viewModel.sampleDeviceFiles.first['fileExtension']!;
    String selectedFileSize = viewModel.sampleDeviceFiles.first['fileSize']!;

    final selectableCategories = viewModel.documentCategories
        .where((c) => c.id != 'all')
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.upload_file_rounded,
                              color: Color(0xFF2563EB),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thêm tài liệu y tế vào thiết bị',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0D2B6B),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Lưu trữ, phân loại và mở tệp tài liệu cục bộ',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),
                      const Text(
                        '1. Chọn tệp trên thiết bị:',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D2B6B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: viewModel.sampleDeviceFiles.map((fileInfo) {
                          final isCurrentFile =
                              fileNameController.text == fileInfo['fileName'];
                          return ActionChip(
                            backgroundColor: isCurrentFile
                                ? const Color(0xFFE8F1FF)
                                : const Color(0xFFF8FAFC),
                            side: BorderSide(
                              color: isCurrentFile
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE2E8F0),
                            ),
                            avatar: Icon(
                              Icons.insert_drive_file_outlined,
                              size: 16,
                              color: isCurrentFile
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF64748B),
                            ),
                            label: Text(
                              fileInfo['fileName']!,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isCurrentFile
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isCurrentFile
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF334155),
                              ),
                            ),
                            onPressed: () {
                              setModalState(() {
                                fileNameController.text = fileInfo['fileName']!;
                                localPathController.text =
                                    fileInfo['localFilePath']!;
                                selectedExtension = fileInfo['fileExtension']!;
                                selectedFileSize = fileInfo['fileSize']!;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '2. Tên tài liệu y tế (*):',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D2B6B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'Nhập tên tài liệu (ví dụ: Sổ tay sơ cứu gia đình)',
                          hintStyle: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF94A3B8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '3. Phân loại danh mục:',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D2B6B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCategoryId,
                            isExpanded: true,
                            items: selectableCategories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat.id,
                                child: Text(cat.dropdownLabel),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedCategoryId = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '4. Tóm tắt nội dung tài liệu:',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D2B6B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: summaryController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText:
                              'Mô tả ngắn gọn nội dung tệp tài liệu y tế...',
                          hintStyle: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF94A3B8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              final enteredTitle = titleController.text.trim();
                              final finalTitle = enteredTitle.isNotEmpty
                                  ? enteredTitle
                                  : fileNameController.text
                                        .replaceAll('.pdf', '')
                                        .replaceAll('.docx', '')
                                        .replaceAll('.txt', '')
                                        .replaceAll('_', ' ');

                              viewModel.addLocalMedicalDocument(
                                title: finalTitle,
                                categoryId: selectedCategoryId,
                                fileName: fileNameController.text,
                                fileExtension: selectedExtension,
                                fileSize: selectedFileSize,
                                localFilePath: localPathController.text,
                                summary: summaryController.text,
                              );
                              Navigator.of(dialogContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.save_outlined, size: 18),
                            label: const Text(
                              'Lưu tài liệu',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOpenAndManageDocumentDialog(
    BuildContext context,
    UserViewModel viewModel,
    MedicalDocumentModel doc,
  ) {
    bool isEditing = false;
    final editTitleController = TextEditingController(text: doc.title);
    final editSummaryController = TextEditingController(text: doc.summary);
    String editCategoryId = doc.categoryId;

    final selectableCategories = viewModel.documentCategories
        .where((c) => c.id != 'all')
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF2FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(9),
                            child: const CustomPaint(
                              painter: MedicalDocumentRowIconPainter(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing
                                      ? 'Quản lý & Phân loại tài liệu'
                                      : doc.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0D2B6B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F1FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        viewModel.getCategoryLabelById(
                                          editCategoryId,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Ngày thêm: ${doc.dateAdded}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isEditing) ...[
                        const Text(
                          'Tên tài liệu:',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D2B6B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: editTitleController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Phân loại danh mục:',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D2B6B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: editCategoryId,
                              isExpanded: true,
                              items: selectableCategories.map((cat) {
                                return DropdownMenuItem<String>(
                                  value: cat.id,
                                  child: Text(cat.dropdownLabel),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    editCategoryId = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tóm tắt nội dung:',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D2B6B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: editSummaryController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          doc.summary,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...doc.contentPoints.map(
                          (point) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              point,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF1E293B),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (doc.externalUrl != null && doc.externalUrl!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () => UrlLauncherHelper.launchWebUrl(context, doc.externalUrl),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link_rounded, color: Color(0xFF2563EB), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tài liệu tham chiếu trực tuyến (Click để mở web):',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                                      ),
                                      Text(
                                        doc.externalUrl!,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF2563EB),
                                          decoration: TextDecoration.underline,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.open_in_new_rounded, color: Color(0xFF2563EB), size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (doc.externalUrl != null && doc.externalUrl!.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () => UrlLauncherHelper.launchWebUrl(context, doc.externalUrl),
                              icon: const Icon(Icons.open_in_browser_rounded, size: 17),
                              label: const Text('Mở trên Web'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () {
                              viewModel.deleteMedicalDocument(doc.id);
                              Navigator.of(dialogContext).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                            ),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Xóa',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              if (isEditing) {
                                viewModel.updateMedicalDocument(
                                  id: doc.id,
                                  newTitle: editTitleController.text,
                                  newCategoryId: editCategoryId,
                                  newSummary: editSummaryController.text,
                                );
                                Navigator.of(dialogContext).pop();
                              } else {
                                setModalState(() {
                                  isEditing = true;
                                });
                              }
                            },
                            icon: Icon(
                              isEditing
                                  ? Icons.check_rounded
                                  : Icons.edit_outlined,
                              size: 17,
                            ),
                            label: Text(isEditing ? 'Lưu' : 'Sửa'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Đóng'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentsPaginationBar(
    BuildContext context,
    UserViewModel viewModel,
  ) {
    final totalItems = viewModel.allFilteredMedicalDocuments.length;
    final totalPages = viewModel.totalDocumentPages;
    final currentPage = viewModel.currentDocumentPage;
    const pageSize = 5;

    if (totalItems == 0) return const SizedBox.shrink();

    final startItem = (currentPage - 1) * pageSize + 1;
    final endItem = (currentPage * pageSize > totalItems)
        ? totalItems
        : currentPage * pageSize;
    final infoText =
        'Hiển thị $startItem - $endItem trên tổng số $totalItems tài liệu (5 tài liệu / trang)';

    final paginationControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPaginationArrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: currentPage > 1
              ? () =>
                  context.read<UserViewModel>().goToPreviousDocumentPage()
              : () {},
        ),
        const SizedBox(width: 6),
        ...List.generate(totalPages, (i) => i + 1).map((page) {
          final isSelected = currentPage == page;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: isSelected ? const Color(0xFF2563EB) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () =>
                    context.read<UserViewModel>().selectDocumentPage(page),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    '$page',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 6),
        _buildPaginationArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: currentPage < totalPages
              ? () => context.read<UserViewModel>().goToNextDocumentPage()
              : () {},
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                infoText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              paginationControls,
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              infoText,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            paginationControls,
          ],
        );
      },
    );
  }

  Widget _buildPaginationArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Icon(icon, size: 19, color: const Color(0xFF64748B)),
        ),
      ),
    );
  }
}
