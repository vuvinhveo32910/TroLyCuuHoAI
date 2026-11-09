import 'package:flutter/material.dart';

import '../models/document_models.dart';
import 'user_navigation_viewmodel.dart';
import 'first_aid_viewmodel.dart';

mixin KhoTaiLieuViewModel on DieuHuongCoSoViewModel, HuongDanSoCuuViewModel {
  // Trạng thái tìm kiếm, lọc danh mục và phân trang trên Màn hình 7: Kho tài liệu y tế
  final TextEditingController documentSearchController =
      TextEditingController();
  String _documentSearchQuery = '';
  String get documentSearchQuery => _documentSearchQuery;

  String _selectedDocumentCategoryId = 'all';
  String get selectedDocumentCategoryId => _selectedDocumentCategoryId;

  int _currentDocumentPage = 1;
  int get currentDocumentPage => _currentDocumentPage;

  // Danh sách các tệp mẫu có sẵn trên thiết bị để người dùng chọn nhanh khi bấm "+ Thêm tài liệu"
  final List<Map<String, String>> sampleDeviceFiles = const [
    {
      'fileName': 'so_tay_so_cuu_gia_dinh_2026.pdf',
      'fileExtension': 'PDF',
      'fileSize': '2.4 MB',
      'localFilePath': 'storage/medical_docs/so_tay_so_cuu_gia_dinh_2026.pdf',
    },
    {
      'fileName': 'quy_trinh_xu_ly_bong_nhiet.docx',
      'fileExtension': 'DOCX',
      'fileSize': '850 KB',
      'localFilePath': 'storage/medical_docs/quy_trinh_xu_ly_bong_nhiet.docx',
    },
    {
      'fileName': 'huong_dan_cam_mau_vet_cat.pdf',
      'fileExtension': 'PDF',
      'fileSize': '1.6 MB',
      'localFilePath':
          'storage/medical_docs/huong_dan_cam_mau_vet_cat.pdf',
    },
    {
      'fileName': 'bang_kiem_dung_cu_y_te_ca_nhan.txt',
      'fileExtension': 'TXT',
      'fileSize': '120 KB',
      'localFilePath': 'storage/medical_docs/bang_kiem_dung_cu_y_te_ca_nhan.txt',
    },
  ];

  // Danh sách 6 danh mục bên trái và trong Dropdown của Màn hình 7: "Kho tài liệu y tế"
  final List<MedicalDocumentCategoryModel> documentCategories = const [
    MedicalDocumentCategoryModel(
      id: 'all',
      sidebarLabel: 'Tất cả (24)',
      dropdownLabel: 'Tất cả danh mục',
      icon: Icons.folder_copy_outlined,
    ),
    MedicalDocumentCategoryModel(
      id: 'basic_first_aid',
      sidebarLabel: 'Sơ cứu cơ bản',
      dropdownLabel: 'Sơ cứu cơ bản',
      icon: Icons.fact_check_outlined,
    ),
    MedicalDocumentCategoryModel(
      id: 'wound',
      sidebarLabel: 'Vết thương (6)',
      dropdownLabel: 'Vết thương',
      icon: Icons.assignment_outlined,
    ),
    MedicalDocumentCategoryModel(
      id: 'burn',
      sidebarLabel: 'Bỏng',
      dropdownLabel: 'Bỏng',
      icon: Icons.local_hospital_outlined,
    ),
    MedicalDocumentCategoryModel(
      id: 'foreign_body',
      sidebarLabel: 'Dị vật',
      dropdownLabel: 'Dị vật',
      icon: Icons.medication_outlined,
    ),
    MedicalDocumentCategoryModel(
      id: 'other',
      sidebarLabel: 'Khác',
      dropdownLabel: 'Khác',
      icon: Icons.person_outline_rounded,
    ),
  ];

  // Danh sách tài liệu y tế được lưu trữ cục bộ trên thiết bị (Có thể Thêm, Mở, Tìm kiếm, Phân loại, Sửa, Xóa)
  final List<MedicalDocumentModel> _medicalDocuments = [
    // --- TRANG 1 (Khớp 100% với ảnh thiết kế Kho tài liệu y tế) ---
    const MedicalDocumentModel(
      id: 'doc_1',
      title: 'Hướng dẫn sơ cứu cơ bản',
      categoryId: 'basic_first_aid',
      categoryLabel: 'Sơ cứu cơ bản',
      dateAdded: '12/10/2025',
      pageGroup: 1,
      fileName: 'huong_dan_so_cuu_co_ban.pdf',
      fileExtension: 'PDF',
      fileSize: '1.8 MB',
      localFilePath: 'storage/medical_docs/huong_dan_so_cuu_co_ban.pdf',
      summary: 'Tài liệu tổng hợp quy trình đánh giá hiện trường, kiểm tra phản ứng của nạn nhân và các nguyên tắc sơ cứu ban đầu an toàn được lưu trữ cục bộ trên thiết bị.',
      contentPoints: [
        '1. Đảm bảo an toàn cho bản thân và nạn nhân trước khi tiếp cận hiện trường.',
        '2. Kiểm tra sự tỉnh táo, đường thở và nhịp thở của người bị nạn.',
        '3. Rửa tay sạch hoặc đeo găng tay y tế trước khi tiếp xúc với vết thương hở.',
        '4. Chuyển cấp cứu ngay nếu nạn nhân bất tỉnh, khó thở hoặc chảy máu không cầm.',
      ],
      relatedGuideTopicId: 'abrasion',
      externalUrl: 'https://redcross.org.vn/so-cap-cuu',
    ),
    const MedicalDocumentModel(
      id: 'doc_2',
      title: 'Xử lý vết thương ngoài da',
      categoryId: 'wound',
      categoryLabel: 'Vết thương',
      dateAdded: '10/10/2025',
      pageGroup: 1,
      fileName: 'xu_ly_vet_thuong_ngoai_da.pdf',
      fileExtension: 'PDF',
      fileSize: '1.4 MB',
      localFilePath: 'storage/medical_docs/xu_ly_vet_thuong_ngoai_da.pdf',
      summary: 'Quy trình chuẩn làm sạch, sát khuẩn và băng bó các vết trầy xước, vết cắt hoặc vết rách nông ngoài da giúp ngăn ngừa nhiễm trùng.',
      contentPoints: [
        '1. Dùng gạc vô trùng ấn nhẹ trực tiếp lên vết thương để cầm máu ban đầu.',
        '2. Rửa vết thương dưới vòi nước sạch hoặc nước muối sinh lý NaCl 0.9%.',
        '3. Thoa dung dịch sát khuẩn nhẹ (Povidone-Iodine) xung quanh vùng tổn thương.',
        '4. Che phủ bằng băng gạc vô trùng và thay băng hàng ngày hoặc khi bị ướt.',
      ],
      relatedGuideTopicId: 'cut_laceration',
      externalUrl: 'https://kcb.vn/huong-dan-so-cuu',
    ),
    const MedicalDocumentModel(
      id: 'doc_3',
      title: 'Sơ cứu bỏng',
      categoryId: 'burn',
      categoryLabel: 'Bỏng',
      dateAdded: '08/10/2025',
      pageGroup: 1,
      fileName: 'so_cuu_bong_nhiet.pdf',
      fileExtension: 'PDF',
      fileSize: '1.1 MB',
      localFilePath:
          'storage/medical_docs/so_cuu_bong_nhiet.pdf',
      summary: 'Hướng dẫn làm mát vùng da bị bỏng nhiệt đúng cách, giảm tổn thương mô sâu và các điều tuyệt đối tránh khi sơ cứu bỏng.',
      contentPoints: [
        '1. Đưa vùng da bị bỏng dưới dòng nước mát sạch chảy nhẹ trong 15 – 20 phút.',
        '2. Tháo bỏ sớm nhẫn, vòng tay, đồng hồ trước khi vùng bỏng bị sưng nề.',
        '3. Tuyệt đối không chọc vỡ bóng nước, không bôi kem đánh răng, mỡ trăn hay nước mắm.',
        '4. Che phủ nhẹ nhàng bằng gạc vô trùng không dính và theo dõi dấu hiệu nhiễm trùng.',
      ],
      relatedGuideTopicId: 'burn',
      externalUrl: 'https://www.who.int/emergencies/first-aid',
    ),
    const MedicalDocumentModel(
      id: 'doc_4',
      title: 'Nhận biết và xử lý dị vật',
      categoryId: 'foreign_body',
      categoryLabel: 'Dị vật',
      dateAdded: '05/10/2025',
      pageGroup: 1,
      fileName: 'nhan_biet_va_xu_ly_di_vat.docx',
      fileExtension: 'DOCX',
      fileSize: '920 KB',
      localFilePath: 'storage/medical_docs/nhan_biet_va_xu_ly_di_vat.docx',
      summary: 'Cách phân biệt dị vật nông trên bề mặt da và dị vật đâm sâu để xử lý an toàn, tránh làm tổn thương mạch máu và dây thần kinh.',
      contentPoints: [
        '1. Quan sát kỹ vị trí, kích thước và độ sâu của dị vật trên da.',
        '2. Với dằm nhỏ nằm nông: Dùng nhíp đã khử trùng cồn gắp nhẹ theo chiều dị vật đâm vào.',
        '3. Với dị vật lớn hoặc đâm sâu: Tuyệt đối không tự rút ra, hãy chèn gạc cố định xung quanh.',
        '4. Đưa người bệnh đến cơ sở y tế gần nhất nếu dị vật sâu hoặc có nguy cơ uốn ván.',
      ],
      relatedGuideTopicId: 'foreign_body',
    ),
    const MedicalDocumentModel(
      id: 'doc_5',
      title: 'Các dấu hiệu cảnh báo nguy hiểm',
      categoryId: 'other',
      categoryLabel: 'Khác',
      dateAdded: '03/10/2025',
      pageGroup: 1,
      fileName: 'cac_dau_hieu_canh_bao_nguy_hiem.pdf',
      fileExtension: 'PDF',
      fileSize: '1.5 MB',
      localFilePath: 'storage/medical_docs/cac_dau_hieu_canh_bao_nguy_hiem.pdf',
      summary: 'Danh mục các triệu chứng cảnh báo đỏ (Red Flags) sau chấn thương hoặc ngộ độc đòi hỏi phải chuyển viện cấp cứu ngay lập tức.',
      contentPoints: [
        '1. Vết thương chảy máu thành tia hoặc không cầm máu sau 15 phút ấn trực tiếp.',
        '2. Vùng tổn thương sưng nóng đỏ đau tăng nhanh, chảy dịch mủ hoặc kèm sốt cao.',
        '3. Nạn nhân có biểu hiện hoa mắt, chóng mặt, vã mồ hôi lạnh, thở gấp hoặc lơ mơ.',
        '4. Bỏng diện rộng, bỏng vùng mặt/cổ/bàn tay hoặc nghi ngờ ngộ độc hóa chất.',
      ],
      relatedGuideTopicId: 'cut_laceration',
    ),

    // --- TRANG 2 ---
    const MedicalDocumentModel(
      id: 'doc_6',
      title: 'Cầm máu vết cắt và vết rách sâu',
      categoryId: 'wound',
      categoryLabel: 'Vết thương',
      dateAdded: '01/10/2025',
      pageGroup: 2,
      fileName: 'cam_mau_vet_cat_sau.pdf',
      fileExtension: 'PDF',
      fileSize: '1.3 MB',
      localFilePath:
          'storage/medical_docs/cam_mau_vet_cat_sau.pdf',
      summary: 'Kỹ thuật băng ép trực tiếp và kê cao chi bị thương nhằm kiểm soát chảy máu hiệu quả trước khi đến cơ sở y tế.',
      contentPoints: [
        '1. Đặt lớp gạc dày vô trùng trực tiếp lên miệng vết cắt và ấn giữ liên tục.',
        '2. Nếu máu thấm ướt lớp gạc đầu tiên, đặt chồng thêm lớp gạc mới lên trên, không tháo lớp cũ.',
        '3. Kê cao vùng tay hoặc chân bị thương cao hơn mức tim nếu không nghi ngờ gãy xương.',
      ],
      relatedGuideTopicId: 'cut_laceration',
    ),
    const MedicalDocumentModel(
      id: 'doc_7',
      title: 'Chăm sóc vết bầm tím phần mềm',
      categoryId: 'wound',
      categoryLabel: 'Vết thương',
      dateAdded: '28/09/2025',
      pageGroup: 2,
      fileName: 'cham_soc_vet_bam_tim.docx',
      fileExtension: 'DOCX',
      fileSize: '780 KB',
      localFilePath: 'storage/medical_docs/cham_soc_vet_bam_tim.docx',
      summary: 'Hướng dẫn áp dụng quy tắc chườm lạnh trong 24 giờ đầu và chườm ấm sau 48 giờ để giảm sưng đau và tan máu bầm.',
      contentPoints: [
        '1. Chườm lạnh bằng túi đá bọc khăn sạch 15 – 20 phút mỗi lần trong 24 giờ đầu.',
        '2. Tuyệt đối không xoa bóp dầu nóng ngay sau khi mới va đập.',
        '3. Sau 48 giờ, có thể chườm ấm nhẹ để tăng tuần hoàn giúp tan vết bầm.',
      ],
      relatedGuideTopicId: 'bruise',
    ),
    const MedicalDocumentModel(
      id: 'doc_8',
      title: 'Vệ sinh và thay băng vết thương trầy xước hàng ngày',
      categoryId: 'wound',
      categoryLabel: 'Vết thương',
      dateAdded: '25/09/2025',
      pageGroup: 2,
      fileName: 've_sinh_thay_bang_vet_tray_xuoc.pdf',
      fileExtension: 'PDF',
      fileSize: '1.6 MB',
      localFilePath: 'storage/medical_docs/ve_sinh_thay_bang_vet_tray_xuoc.pdf',
      summary: 'Quy trình rửa sạch vết xước bằng nước muối sinh lý và bôi thuốc mỡ kháng sinh thúc đẩy lành da.',
      contentPoints: [
        '1. Rửa tay thật sạch bằng xà phòng trước khi chạm vào vết thương.',
        '2. Làm sạch nhẹ nhàng bằng dung dịch nước muối sinh lý 0.9%, tránh chà xát mạnh.',
        '3. Thoa một lớp mỏng thuốc mỡ giữ ẩm vết thương và băng gạc thoáng khí.',
      ],
      relatedGuideTopicId: 'abrasion',
    ),

    // --- TRANG 3 ---
    const MedicalDocumentModel(
      id: 'doc_9',
      title: 'Danh mục dụng cụ trong hộp sơ cứu gia đình',
      categoryId: 'basic_first_aid',
      categoryLabel: 'Sơ cứu cơ bản',
      dateAdded: '20/09/2025',
      pageGroup: 3,
      fileName: 'danh_muc_hop_so_cuu_gia_dinh.txt',
      fileExtension: 'TXT',
      fileSize: '95 KB',
      localFilePath: 'storage/medical_docs/danh_muc_hop_so_cuu_gia_dinh.txt',
      summary: 'Danh sách các vật tư y tế thiết yếu cần chuẩn bị sẵn trong tủ thuốc và túi sơ cứu cá nhân.',
      contentPoints: [
        '1. Băng gạc vô trùng các kích cỡ, băng cuộn y tế và băng cá nhân.',
        '2. Nước muối sinh lý NaCl 0.9% và dung dịch sát khuẩn Povidone-Iodine.',
        '3. Nhíp y tế, kéo đầu tù, găng tay y tế sạch và nhiệt kế.',
      ],
      relatedGuideTopicId: 'abrasion',
    ),
    const MedicalDocumentModel(
      id: 'doc_10',
      title: 'Phòng ngừa nhiễm trùng vết thương hở',
      categoryId: 'wound',
      categoryLabel: 'Vết thương',
      dateAdded: '15/09/2025',
      pageGroup: 3,
      fileName: 'phong_ngua_nhiem_trung_vet_thuong.pdf',
      fileExtension: 'PDF',
      fileSize: '1.2 MB',
      localFilePath: 'storage/medical_docs/phong_ngua_nhiem_trung_vet_thuong.pdf',
      summary: 'Hướng dẫn theo dõi quá trình lành thương và nhận biết sớm các biểu hiện nhiễm khuẩn ngoài da.',
      contentPoints: [
        '1. Giữ vết thương luôn khô ráo, sạch sẽ và thay băng đúng định kỳ.',
        '2. Không tự ý rắc bột kháng sinh hoặc đắp lá cây lên vết thương hở.',
        '3. Đi khám bác sĩ nếu vết thương sưng tấy, tấy đỏ lan rộng hoặc chảy dịch vàng.',
      ],
      relatedGuideTopicId: 'abrasion',
    ),
  ];

  List<MedicalDocumentModel> get allMedicalDocuments =>
      List.unmodifiable(_medicalDocuments);

  /// Lấy nhãn hiển thị trên cột danh mục bên trái (Cập nhật số lượng động khi người dùng thêm/xóa tài liệu)
  String getDocumentCategorySidebarLabel(
    MedicalDocumentCategoryModel category,
  ) {
    final userAddedCount = _medicalDocuments.where((d) => d.isUserAdded).length;
    if (category.id == 'all') {
      final totalCount = 24 + userAddedCount;
      return 'Tất cả ($totalCount)';
    }
    if (category.id == 'wound') {
      final userAddedWound = _medicalDocuments
          .where((d) => d.isUserAdded && d.categoryId == 'wound')
          .length;
      return 'Vết thương (${6 + userAddedWound})';
    }
    return category.sidebarLabel;
  }

  /// Lấy nhãn tên danh mục từ `categoryId`
  String getCategoryLabelById(String categoryId) {
    for (final cat in documentCategories) {
      if (cat.id == categoryId && cat.id != 'all') {
        return cat.dropdownLabel;
      }
    }
    return 'Sơ cứu cơ bản';
  }

  /// Lấy danh sách tài liệu hiển thị trên bảng dựa theo Bộ lọc danh mục, Từ khóa tìm kiếm và Phân trang
  static const int documentPageSize = 5;

  /// Danh sách tài liệu sau khi lọc theo Danh mục và Từ khóa tìm kiếm
  List<MedicalDocumentModel> get allFilteredMedicalDocuments {
    final query = _documentSearchQuery.trim().toLowerCase();
    return _medicalDocuments.where((doc) {
      final matchesCategory =
          _selectedDocumentCategoryId == 'all' ||
          doc.categoryId == _selectedDocumentCategoryId;
      final matchesQuery =
          query.isEmpty ||
          doc.title.toLowerCase().contains(query) ||
          doc.categoryLabel.toLowerCase().contains(query) ||
          doc.fileName.toLowerCase().contains(query) ||
          doc.dateAdded.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  int get totalDocumentPages {
    final total = (allFilteredMedicalDocuments.length / documentPageSize).ceil();
    return total < 1 ? 1 : total;
  }

  /// Lấy danh sách tài liệu hiển thị trên bảng dựa theo Phân trang chuẩn 5 tài liệu / trang
  List<MedicalDocumentModel> get filteredMedicalDocuments {
    final matched = allFilteredMedicalDocuments;
    final startIndex = (_currentDocumentPage - 1) * documentPageSize;
    if (startIndex >= matched.length) return [];
    final endIndex = (startIndex + documentPageSize > matched.length)
        ? matched.length
        : startIndex + documentPageSize;
    return matched.sublist(startIndex, endIndex);
  }

  // =========================================================================
  // LOGIC QUẢN LÝ KHO TÀI LIỆU Y TẾ CỤC BỘ TRÊN THIẾT BỊ (MÀN HÌNH 7)
  // 1. Thêm tài liệu | 2. Mở tài liệu | 3. Tìm kiếm | 4. Phân loại | 5. Quản lý | 6. Lưu cục bộ
  // =========================================================================

  /// 1. Thêm tài liệu mới từ tệp lưu trữ cục bộ trên thiết bị
  void addLocalMedicalDocument({
    required String title,
    required String categoryId,
    required String fileName,
    required String fileExtension,
    required String fileSize,
    required String localFilePath,
    required String summary,
    List<String>? contentPoints,
  }) {
    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final categoryLabel = getCategoryLabelById(categoryId);

    String? mappedGuideTopicId;
    if (categoryId == 'burn') {
      mappedGuideTopicId = 'burn';
    } else if (categoryId == 'wound') {
      mappedGuideTopicId = 'cut_laceration';
    } else if (categoryId == 'foreign_body') {
      mappedGuideTopicId = 'foreign_body';
    } else if (categoryId == 'other') {
      mappedGuideTopicId = 'abrasion';
    } else {
      mappedGuideTopicId = 'abrasion';
    }

    final newDoc = MedicalDocumentModel(
      id: 'local_doc_${now.microsecondsSinceEpoch}',
      title: title.trim(),
      categoryId: categoryId,
      categoryLabel: categoryLabel,
      dateAdded: formattedDate,
      pageGroup: 1,
      fileName: fileName.trim(),
      fileExtension: fileExtension.toUpperCase(),
      fileSize: fileSize,
      localFilePath: localFilePath.trim(),
      isUserAdded: true,
      summary: summary.trim().isEmpty
          ? 'Tài liệu y tế được người dùng thêm và lưu trữ cục bộ trên thiết bị.'
          : summary.trim(),
      contentPoints: (contentPoints != null && contentPoints.isNotEmpty)
          ? contentPoints
          : const [
              '1. Tệp tài liệu đã được lưu trữ trong bộ nhớ cục bộ của thiết bị.',
              '2. Có thể tra cứu nhanh ngoại tuyến (Offline) bất cứ lúc nào.',
              '3. Tuân thủ hướng dẫn sơ cứu an toàn và liên hệ y tế khi cần thiết.',
            ],
      relatedGuideTopicId: mappedGuideTopicId,
    );

    // Chèn lên đầu danh sách để hiển thị ngay ở đầu bảng Trang 1
    _medicalDocuments.insert(0, newDoc);
    _currentDocumentPage = 1;
    notifyListeners();
  }

  /// 2. Cập nhật / Phân loại lại tài liệu y tế (Quản lý tài liệu)
  void updateMedicalDocument({
    required String id,
    required String newTitle,
    required String newCategoryId,
    required String newSummary,
  }) {
    final index = _medicalDocuments.indexWhere((doc) => doc.id == id);
    if (index == -1) return;

    final current = _medicalDocuments[index];
    final updatedCategoryLabel = getCategoryLabelById(newCategoryId);

    _medicalDocuments[index] = current.copyWith(
      title: newTitle.trim().isEmpty ? current.title : newTitle.trim(),
      categoryId: newCategoryId,
      categoryLabel: updatedCategoryLabel,
      summary: newSummary.trim().isEmpty ? current.summary : newSummary.trim(),
    );
    notifyListeners();
  }

  /// 3. Xóa tài liệu khỏi danh sách quản lý trên thiết bị
  void deleteMedicalDocument(String id) {
    _medicalDocuments.removeWhere((doc) => doc.id == id);
    notifyListeners();
  }

  /// 4. Tìm kiếm tài liệu y tế theo từ khóa
  void updateDocumentSearchQuery(String query) {
    _documentSearchQuery = query;
    _currentDocumentPage = 1;
    notifyListeners();
  }

  /// 5. Phân loại / Lọc danh mục tài liệu (đồng bộ cả menu dọc bên trái và Dropdown phía trên)
  void selectDocumentCategory(String categoryId) {
    if (_selectedDocumentCategoryId == categoryId) return;
    _selectedDocumentCategoryId = categoryId;
    _currentDocumentPage = 1;
    notifyListeners();
  }

  /// 6. Chuyển trang trên thanh phân trang (1, 2, 3) của Kho tài liệu y tế
  void selectDocumentPage(int page) {
    if (page < 1 || page > totalDocumentPages) return;
    if (_currentDocumentPage == page) return;
    _currentDocumentPage = page;
    notifyListeners();
  }

  void goToPreviousDocumentPage() {
    if (_currentDocumentPage > 1) {
      _currentDocumentPage--;
      notifyListeners();
    }
  }

  void goToNextDocumentPage() {
    if (_currentDocumentPage < totalDocumentPages) {
      _currentDocumentPage++;
      notifyListeners();
    }
  }
}
