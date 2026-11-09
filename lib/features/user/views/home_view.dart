// File: lib/views/userview/trang_chu_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/home_models.dart';
import '../viewmodels/user_viewmodel.dart';

class TrangChuView extends StatefulWidget {
  const TrangChuView({super.key});

  @override
  State<TrangChuView> createState() => _TrangChuViewState();
}

class _TrangChuViewState extends State<TrangChuView> {
  final ScrollController _mobileSituationsScrollController = ScrollController();

  @override
  void dispose() {
    _mobileSituationsScrollController.dispose();
    super.dispose();
  }

  void _scrollMobileSituationsBy(double delta) {
    if (!_mobileSituationsScrollController.hasClients) return;
    final position = _mobileSituationsScrollController.position;
    final targetOffset = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _mobileSituationsScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    if (isMobile) {
      return _buildMobileHomeContent(context, viewModel);
    }

    // =========================================================================
    // GIAO DIỆN PC / DESKTOP (GIỮ NGUYÊN 100%)
    // =========================================================================
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroSection(context, viewModel),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFeatureCardsSection(context, viewModel),
              const SizedBox(height: 36),
              _buildCommonSituationsSection(context, viewModel),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // GIAO DIỆN MOBILE (< 768PX) HỖ TRỢ KÉO NGANG MƯỢT MÀ + NÚT TRƯỢT NHANH
  // ===========================================================================

  Widget _buildMobileHomeContent(
    BuildContext context,
    UserViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Banner Hero Mobile
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEBF4FF), Color(0xFFDCEBFE)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 62,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sơ cứu đúng cách\nBảo vệ sức khỏe',
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D2B6B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Thực hiện sơ cứu nhanh chóng,\nhiệu quả với sự hỗ trợ của AI',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => viewModel.onAnalyzeImageNowPressed(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined, size: 16),
                      label: const Text(
                        'Phân tích ảnh ngay',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 38,
                child: _buildMobileHeroMedicalKitIllustration(),
              ),
            ],
          ),
        ),

        // 2. Lưới 5 ô tính năng (3 cột x 2 hàng) & Mục "Tình huống thường gặp"
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMobileFeatureGrid3x2(context, viewModel),
              const SizedBox(height: 22),

              // Tiêu đề "Tình huống thường gặp" kèm 2 nút trượt trái/phải tiện lợi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Tình huống thường gặp',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D2B6B),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHorizontalScrollArrowButton(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Trượt sang trái',
                        onTap: () => _scrollMobileSituationsBy(-220),
                      ),
                      const SizedBox(width: 6),
                      _buildHorizontalScrollArrowButton(
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'Trượt sang phải',
                        onTap: () => _scrollMobileSituationsBy(220),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Danh sách cuộn ngang hỗ trợ cả vuốt cảm ứng, kéo chuột và bấm mũi tên
              SizedBox(
                height: 136,
                child: ListView.separated(
                  controller: _mobileSituationsScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: viewModel.commonSituations.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final situation = viewModel.commonSituations[index];
                    return SizedBox(
                      width: 126,
                      child: _buildMobileSituationCard(context, situation),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalScrollArrowButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD8E3F2), width: 1.2),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
        ),
      ),
    );
  }

  Widget _buildMobileHeroMedicalKitIllustration() {
    return SizedBox(
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 4,
            child: Container(
              width: 100,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0x221E3A8A),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 9,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF1D4ED8),
                    width: 3.5,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ),
              Container(
                width: 92,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x281E3A8A),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 2,
            bottom: 8,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                size: 18,
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFeatureGrid3x2(
    BuildContext context,
    UserViewModel viewModel,
  ) {
    final List<Map<String, dynamic>> mobileItems = [
      {
        'title': 'Phân tích\nảnh AI',
        'icon': Icons.center_focus_strong_outlined,
        'color': const Color(0xFF0D9488),
        'bgColor': const Color(0xFFE6F4F1),
        'onTap': () => viewModel.navigateToAiAnalysis(),
      },
      {
        'title': 'Kiến thức\nsơ cứu',
        'icon': Icons.menu_book_outlined,
        'color': const Color(0xFF2563EB),
        'bgColor': const Color(0xFFEBF2FE),
        'onTap': () => viewModel.navigateToKnowledgeLookup(),
      },
      {
        'title': 'Kho tài liệu\ny tế',
        'icon': Icons.description_outlined,
        'color': const Color(0xFF16A34A),
        'bgColor': const Color(0xFFE8F7EE),
        'onTap': () => viewModel.navigateToMedicalDocuments(),
      },
      {
        'title': 'Lịch sử\nphân tích',
        'icon': Icons.history_outlined,
        'color': const Color(0xFF0D9488),
        'bgColor': const Color(0xFFE6F4F1),
        'onTap': () => viewModel.navigateToAnalysisHistory(),
      },
      {
        'title': 'ChatBox AI\ntrợ giúp',
        'icon': Icons.smart_toy_outlined,
        'color': const Color(0xFF7C3AED),
        'bgColor': const Color(0xFFF2EBFE),
        'onTap': () => viewModel.navigateToChatBoxAi(),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 10;
        final double itemWidth = (constraints.maxWidth - (spacing * 2)) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: mobileItems.map((item) {
            return SizedBox(
              width: itemWidth,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: item['onTap'] as VoidCallback,
                  child: Container(
                    height: 106,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE8EEF5),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x060D2B6B),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: item['bgColor'] as Color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['title'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D2B6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMobileSituationCard(
    BuildContext context,
    CommonSituationModel situation,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.read<UserViewModel>().onSituationCardTapped(situation),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EEF5), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060D2B6B),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10.5),
                ),
                child: SizedBox(
                  height: 82,
                  child: _buildSafeSituationImage(situation),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Center(
                    child: Text(
                      situation.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D2B6B),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CÁC HÀM HIỂN THỊ TRÊN PC (GIỮ NGUYÊN 100%)
  // ===========================================================================

  Widget _buildHeroSection(BuildContext context, UserViewModel viewModel) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEBF4FF), Color(0xFFDCEBFE)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 36),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 820;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: _buildHeroLeftColumn(context)),
                const SizedBox(width: 32),
                Expanded(flex: 5, child: _buildHeroRightIllustration()),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroLeftColumn(context),
                const SizedBox(height: 28),
                Center(child: _buildHeroRightIllustration()),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildHeroLeftColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sơ cứu đúng cách\nBảo vệ sức khỏe\nVì một cộng đồng an toàn hơn',
          style: TextStyle(
            fontSize: 32,
            height: 1.32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D2B6B),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Ứng dụng AI giúp nhận diện tổn thương, cung cấp hướng dẫn\nsơ cứu nhanh chóng và chính xác.',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () =>
                  context.read<UserViewModel>().onAnalyzeImageNowPressed(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Phân tích hình ảnh ngay'),
            ),
            OutlinedButton(
              onPressed: () =>
                  context.read<UserViewModel>().onLookupKnowledgePressed(),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0D2B6B),
                side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Tra cứu kiến thức'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroRightIllustration() {
    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 14,
            child: Container(
              width: 280,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0x221E3A8A),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Positioned(
            right: 28,
            top: 24,
            child: Transform.rotate(
              angle: 0.35,
              child: const Icon(Icons.eco, size: 84, color: Color(0xFF6EE7B7)),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF93C5FD), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140D2B6B),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                size: 46,
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 16,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1D4ED8), width: 6),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
              ),
              Container(
                width: 190,
                height: 145,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x331E3A8A),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 52),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 36,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x190D2B6B),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.healing, color: Color(0xFFD97706), size: 24),
                  SizedBox(width: 6),
                  Text(
                    'AI First-Aid',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCardsSection(
    BuildContext context,
    UserViewModel viewModel,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        int crossAxisCount = 4;
        if (maxWidth < 560) {
          crossAxisCount = 1;
        } else if (maxWidth < 920) {
          crossAxisCount = 2;
        }

        const double spacing = 20;
        final double cardWidth =
            (maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: viewModel.featureCards.map((card) {
            return SizedBox(
              width: cardWidth,
              child: _buildSingleFeatureCard(context, card),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSingleFeatureCard(BuildContext context, FeatureCardModel card) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.read<UserViewModel>().onFeatureCardTapped(card),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEFF4FB), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0D2B6B),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: card.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(card.icon, color: card.iconColor, size: 26),
              ),
              const SizedBox(height: 18),
              Text(
                card.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D2B6B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                card.description,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommonSituationsSection(
    BuildContext context,
    UserViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tình huống thường gặp',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D2B6B),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            int columns = 5;
            if (maxWidth < 500) {
              columns = 1;
            } else if (maxWidth < 760) {
              columns = 2;
            } else if (maxWidth < 1024) {
              columns = 3;
            }

            const double spacing = 16;
            final double itemWidth =
                (maxWidth - (spacing * (columns - 1))) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: viewModel.commonSituations.map((situation) {
                return SizedBox(
                  width: itemWidth,
                  child: _buildSituationCard(context, situation),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSituationCard(
    BuildContext context,
    CommonSituationModel situation,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.read<UserViewModel>().onSituationCardTapped(situation),
        child: Container(
          height: 168,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEFF4FB), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0D2B6B),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10.5),
                ),
                child: SizedBox(
                  height: 100,
                  child: _buildSafeSituationImage(situation),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Center(
                    child: Text(
                      situation.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D2B6B),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafeSituationImage(CommonSituationModel situation) {
    if (situation.imageUrl != null && situation.imageUrl!.isNotEmpty) {
      return Image.network(
        situation.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderWoundGraphic(situation);
        },
      );
    }
    return _buildPlaceholderWoundGraphic(situation);
  }

  Widget _buildPlaceholderWoundGraphic(CommonSituationModel situation) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            situation.baseSkinColor,
            situation.baseSkinColor.withValues(alpha: 0.78),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  situation.woundAccentColor.withValues(alpha: 0.75),
                  situation.woundAccentColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          Icon(
            situation.medicalIcon,
            color: Colors.white.withValues(alpha: 0.9),
            size: 22,
          ),
        ],
      ),
    );
  }
}
