// File: lib/views/userview/chatbox_ai_view.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/url_launcher_helper.dart';
import '../../../core/feedback/ai_feedback_model.dart';
import '../../../core/feedback/ai_feedback_service.dart';
import '../models/chat_models.dart';
import '../viewmodels/user_viewmodel.dart';
import 'widgets/user_painters.dart';

class ChatBoxAiView extends StatelessWidget {
  const ChatBoxAiView({super.key});

  /// Hộp thoại chọn chuyển đổi Model AI (Google Gemini hoặc MedGemma Server)
  void _showModelSelectorDialog(BuildContext context, UserViewModel viewModel) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hub_rounded, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Chọn mô hình AI',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      tooltip: 'Đóng',
                    ),
                  ],
                ),
                const Divider(height: 24),
                ...viewModel.availableChatModels.map((model) {
                  final selected = viewModel.selectedChatModelId == model.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        viewModel.switchChatModel(model.id);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã chọn mô hình: ${model.name}'),
                            backgroundColor: model.brandColor,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected
                              ? model.brandColor.withValues(alpha: 0.06)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? model.brandColor
                                : const Color(0xFFE2E8F0),
                            width: selected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(model.icon, color: model.brandColor, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    model.name,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: model.brandColor,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: model.tagColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      model.tagLabel,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: model.tagColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    model.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    model.provider,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: selected
                                  ? model.brandColor
                                  : const Color(0xFF94A3B8),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Nút chọn Model AI xuất hiện ở Header giống các app ChatGPT/Gemini
  Widget _buildModelSelectorButton(
    BuildContext context,
    UserViewModel viewModel, {
    bool isMobile = false,
  }) {
    final currentModel = viewModel.currentChatModel;

    return InkWell(
      onTap: viewModel.isAiThinking
          ? null
          : () => _showModelSelectorDialog(context, viewModel),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: isMobile ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: currentModel.brandColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: currentModel.brandColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentModel.icon,
              size: isMobile ? 15 : 17,
              color: currentModel.brandColor,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isMobile ? 120 : 160),
              child: Text(
                currentModel.shortName,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0D2B6B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: isMobile ? 16 : 18,
              color: const Color(0xFF475569),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog(BuildContext context, UserViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFDC2626),
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'Xóa cuộc trò chuyện',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn làm mới và xóa toàn bộ các tin nhắn trong cuộc trò chuyện này không?',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              viewModel.clearChatHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Đã sao chép nội dung sơ cứu vào bộ nhớ tạm!'),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();
    final screenSize = MediaQuery.sizeOf(context);
    final isMobile = screenSize.width < 768;
    final totalItems =
        viewModel.chatMessages.length + (viewModel.isAiThinking ? 1 : 0);

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mobile Header
            Row(
              children: [
                IconButton(
                  onPressed: () => context.read<UserViewModel>().navigateBack(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF0D2B6B),
                    size: 20,
                  ),
                  tooltip: 'Quay lại',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ChatBox AI',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D2B6B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildModelSelectorButton(context, viewModel, isMobile: true),
                if (viewModel.chatMessages.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    tooltip: 'Xóa hội thoại',
                    onPressed: () => _showClearChatDialog(context, viewModel),
                  ),
                ],
              ],
            ),
            const Divider(height: 16),
            _buildActiveHealthProfileBanner(context, viewModel, isMobile: true),
            Expanded(
              child: viewModel.chatMessages.isEmpty
                  ? _buildEmptyChatWelcomeState(
                      context,
                      viewModel,
                      isMobile: true,
                    )
                  : ListView.separated(
                      controller: viewModel.chatScrollController,
                      padding: const EdgeInsets.only(top: 4, bottom: 12),
                      itemCount: totalItems,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        if (index == viewModel.chatMessages.length) {
                          return _buildAiThinkingRow(viewModel, isMobile: true);
                        }
                        final message = viewModel.chatMessages[index];
                        return message.isUser
                            ? _buildUserChatMessageRow(message, isMobile: true)
                            : _buildAiChatMessageRow(
                                context,
                                message,
                                isMobile: true,
                              );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            if (viewModel.selectedChatModelId == 'medgemma')
              _buildMedGemmaStatus(viewModel),
            _buildChatBottomInputBar(context, viewModel, isMobile: true),
          ],
        ),
      );
    }

    // =========================================================================
    // GIAO DIỆN PC / DESKTOP
    // =========================================================================
    final double fixedChatViewportHeight = math.max(
      540.0,
      screenSize.height - 135,
    );

    return SizedBox(
      height: fixedChatViewportHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.read<UserViewModel>().navigateBack(),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ChatBox AI Sơ Cứu Y Tế',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D2B6B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (screenSize.width >= 960) ...[
                        const SizedBox(height: 2),
                        const Text(
                          'Hỏi đáp nhanh và nhận hướng dẫn sơ cứu tức thời cho các tổn thương ngoài da',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF475569),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Nút chuyển đổi Model AI phong cách ChatGPT / Gemini
                Flexible(
                  child: _buildModelSelectorButton(
                    context,
                    viewModel,
                    isMobile: screenSize.width < 960,
                  ),
                ),
                if (viewModel.chatMessages.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showClearChatDialog(context, viewModel),
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    tooltip: 'Xóa cuộc trò chuyện',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      hoverColor: const Color(0xFFFECACA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            _buildActiveHealthProfileBanner(context, viewModel, isMobile: false),
            Expanded(
              child: viewModel.chatMessages.isEmpty
                  ? _buildEmptyChatWelcomeState(context, viewModel)
                  : Scrollbar(
                      controller: viewModel.chatScrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: viewModel.chatScrollController,
                        padding: const EdgeInsets.only(
                          top: 4,
                          bottom: 16,
                          right: 8,
                        ),
                        itemCount: totalItems,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          if (index == viewModel.chatMessages.length) {
                            return _buildAiThinkingRow(
                              viewModel,
                              isMobile: false,
                            );
                          }
                          final message = viewModel.chatMessages[index];
                          return message.isUser
                              ? _buildUserChatMessageRow(message)
                              : _buildAiChatMessageRow(context, message);
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            if (viewModel.selectedChatModelId == 'medgemma')
              _buildMedGemmaStatus(viewModel),
            _buildChatBottomInputBar(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildMedGemmaStatus(UserViewModel vm) {
    final state = switch (vm.chatModelState) {
      'ready' => 'MedGemma sẵn sàng',
      'loading' => 'Đang nạp MedGemma trên máy chủ…',
      'generating' => 'MedGemma đang xử lý câu hỏi…',
      'not_loaded' => 'MedGemma chưa nạp',
      'error' => 'Không nạp được MedGemma; kiểm tra bộ nhớ trên máy chủ',
      'offline' => 'Chưa kết nối được máy chủ MedGemma',
      _ => 'Kiểm tra kết nối MedGemma',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(
            '$state · ${vm.chatReferenceCount} mục tham khảo',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          IconButton(
            onPressed: vm.refreshChatStatus,
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Kiểm tra kết nối',
            visualDensity: VisualDensity.compact,
          ),
          if ({'not_loaded', 'error'}.contains(vm.chatModelState))
            TextButton(
              onPressed: vm.isAiThinking ? null : vm.loadChatModel,
              child: const Text('Thử nạp model'),
            ),
        ],
      ),
    );
  }

    Widget _buildActiveHealthProfileBanner(
    BuildContext context,
    UserViewModel viewModel, {
    bool isMobile = false,
  }) {
    final user = viewModel.currentUser;
    if (user == null || !user.hasHealthData) return const SizedBox.shrink();

    final tags = <String>[];
    if (user.bloodTypeSummary != null) tags.add('Nhóm máu: ${user.bloodTypeSummary}');
    if (user.hasHemophilia) tags.add('Máu khó đông (Hemophilia)');
    if (user.hasDiabetes) tags.add('Tiểu đường');
    if (user.hasCardiovascular) tags.add('Tim mạch');
    if (user.allergies.isNotEmpty) tags.add('Dị ứng: ${user.allergies.join(", ")}');

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hồ sơ sức khỏe ẩn danh đã kích hoạt: ${tags.join(" • ")}',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF166534),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'AI đang cá nhân hóa các câu trả lời dựa trên hồ sơ: ${tags.join(" • ")}. Thông tin hoàn toàn ẩn danh và không lưu trữ PII.',
                  ),
                  duration: const Duration(seconds: 4),
                  backgroundColor: const Color(0xFF166534),
                ),
              );
            },
            child: const Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatWelcomeState(
    BuildContext context,
    UserViewModel viewModel, {
    bool isMobile = false,
  }) {
    final currentModel = viewModel.currentChatModel;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isMobile ? 52 : 64,
              height: isMobile ? 52 : 64,
              decoration: BoxDecoration(
                color: currentModel.brandColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: currentModel.brandColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: currentModel.brandColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                currentModel.icon,
                color: currentModel.brandColor,
                size: isMobile ? 26 : 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Trợ Lý Cứu Hộ Y Tế 24/7',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D2B6B),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: BoxConstraints(maxWidth: isMobile ? 320 : 540),
              child: Text(
                'Mô hình đang hoạt động: ${currentModel.name}.\nBạn có thể mô tả chi tiết vết thương, hỏi về cách cầm máu, rửa vết thương, hoặc bấm nút chuyển mô hình phía trên để đổi sang MedGemma / Gemini.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: viewModel.quickSuggestedQuestions.map((question) {
                return ActionChip(
                  backgroundColor: const Color(0xFFF8FAFC),
                  side: const BorderSide(color: Color(0xFFDBEAFE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  label: Text(
                    question,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 12.5,
                      fontWeight: FontWeight.w600,
                      color: currentModel.brandColor,
                    ),
                  ),
                  onPressed: () =>
                      context.read<UserViewModel>().sendChatMessage(question),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiThinkingRow(UserViewModel viewModel, {bool isMobile = false}) {
    final currentModel = viewModel.currentChatModel;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isMobile ? 34 : 40,
          height: isMobile ? 34 : 40,
          decoration: BoxDecoration(
            color: currentModel.brandColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: currentModel.brandColor.withValues(alpha: 0.35),
              width: 2.0,
            ),
          ),
          padding: EdgeInsets.all(isMobile ? 7 : 8.5),
          child: const CustomPaint(painter: AiShieldBadgePainter()),
        ),
        SizedBox(width: isMobile ? 10 : 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: currentModel.brandColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${currentModel.shortName} đang phân tích và chuẩn bị câu trả lời...',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserChatMessageRow(
    ChatMessageModel message, {
    bool isMobile = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: isMobile ? 280 : 520),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 18,
                  vertical: isMobile ? 11 : 13,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x142563EB),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  message.messageText,
                  style: TextStyle(
                    fontSize: isMobile ? 13.5 : 14.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  message.timestamp,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: const CustomPaint(painter: ChatUserPortraitAvatarPainter()),
          ),
        ],
      ],
    );
  }

  Widget _buildAiChatMessageRow(
    BuildContext context,
    ChatMessageModel message, {
    bool isMobile = false,
  }) {
    final isMedGemma =
        message.modelSource != null && message.modelSource != 'gemini';
    final sourceName = switch (message.modelSource) {
      'medgemma' => 'MedGemma 1.5 4B',
      'sqlite' => 'Tài liệu SQLite',
      'app' => 'Phản hồi nhanh của ứng dụng',
      _ => 'Gemini Flash Latest',
    };
    final modelColor = isMedGemma
        ? const Color(0xFF7C3AED)
        : const Color(0xFF2563EB);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isMobile ? 34 : 40,
          height: isMobile ? 34 : 40,
          decoration: BoxDecoration(
            color: modelColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: modelColor.withValues(alpha: 0.35),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: modelColor.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(isMobile ? 7 : 8.5),
          child: const CustomPaint(painter: AiShieldBadgePainter()),
        ),
        SizedBox(width: isMobile ? 10 : 12),
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: isMobile ? 310 : 600),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 18,
              vertical: isMobile ? 14 : 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag mô hình nguồn
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: modelColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: modelColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMedGemma
                                ? Icons.health_and_safety_rounded
                                : Icons.auto_awesome,
                            size: 12,
                            color: modelColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sourceName,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: modelColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (message.notice.isNotEmpty) ...[
                  Text(
                    message.notice,
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _buildFormattedMessageContent(message.messageText, isMobile),
                if (message.evidenceLabel.isNotEmpty ||
                    message.elapsedSeconds != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    [
                      message.evidenceLabel,
                      if (message.elapsedSeconds != null)
                        '${message.elapsedSeconds!.toStringAsFixed(2)} giây',
                    ].where((text) => text.isNotEmpty).join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
                ...message.citations.map(
                  (citation) => TextButton.icon(
                    onPressed: () => UrlLauncherHelper.launchWebUrl(
                      context,
                      citation.url.toString(),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: Text(
                      '${citation.title}${citation.pages.isEmpty ? '' : ' · trang ${citation.pages}'}',
                    ),
                  ),
                ),
                if (message.guideOptions.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: message.guideOptions
                        .map(
                          (guide) => ActionChip(
                            label: Text(guide.title),
                            onPressed: () =>
                                context.read<UserViewModel>().sendChatMessage(
                                  message.originalQuestion,
                                  guide.id,
                                ),
                          ),
                        )
                        .toList(),
                  ),

                if (message.numberedSteps.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...List.generate(message.numberedSteps.length, (index) {
                    final stepNumber = index + 1;
                    final stepContent = message.numberedSteps[index];
                    final isLastStep =
                        index == message.numberedSteps.length - 1;

                    return Padding(
                      padding: EdgeInsets.only(bottom: isLastStep ? 0 : 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: modelColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$stepNumber',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: modelColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              stepContent,
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF1E293B),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      message.timestamp,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Đánh giá câu trả lời hữu ích',
                          child: InkWell(
                            onTap: () {
                              AiFeedbackService.instance.submitFeedback(
                                AiFeedbackModel(
                                  id: 'fb_chat_${DateTime.now().millisecondsSinceEpoch}',
                                  timestamp: DateTime.now(),
                                  userDisplayName: context.read<UserViewModel>().currentUserName,
                                  sourceModel: message.modelSource == 'medgemma'
                                      ? AiSourceModel.medgemma
                                      : AiSourceModel.gemini,
                                  feedbackType: AiFeedbackType.helpful,
                                  issueCategory: 'Tư vấn sơ cứu hữu ích',
                                  userComment: 'Người dùng đánh giá hài lòng với câu trả lời của AI.',
                                  detectedWoundSummary: message.messageText.length > 60
                                      ? '${message.messageText.substring(0, 60)}...'
                                      : message.messageText,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cảm ơn bạn đã đánh giá hữu ích cho câu trả lời của AI!'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              child: Icon(Icons.thumb_up_alt_outlined, size: 14, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Báo cáo câu trả lời không chính xác / nghi ngờ về /admin',
                          child: InkWell(
                            onTap: () => _showChatFeedbackDialog(context, message),
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              child: Icon(Icons.thumb_down_alt_outlined, size: 14, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () =>
                              _copyToClipboard(context, message.messageText),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                  size: 13,
                                  color: Color(0xFF64748B),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Sao chép',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Trình phân tích và định dạng nội dung Markdown thông minh
  Widget _buildFormattedMessageContent(String text, bool isMobile) {
    final lines = text.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // 1. Tiêu đề ### hoặc ##
      if (line.startsWith('###') || line.startsWith('##')) {
        final headingText = line.replaceAll(RegExp(r'^#+\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              headingText,
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D2B6B),
              ),
            ),
          ),
        );
        continue;
      }

      // 2. Cảnh báo nguy hiểm ⚠️ hoặc khẩn cấp 🚨
      if (line.startsWith('⚠️') ||
          line.startsWith('🚨') ||
          line.startsWith('🔴')) {
        final isEmergency = line.startsWith('🚨') || line.startsWith('🔴');
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEmergency
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEmergency
                    ? const Color(0xFFFECACA)
                    : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmergency ? '🚨' : '⚠️',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRichTextWithBold(
                    line.replaceFirst(RegExp(r'^(⚠️|🚨|🔴)\s*'), ''),
                    fontSize: isMobile ? 12.5 : 13.5,
                    defaultColor: isEmergency
                        ? const Color(0xFF991B1B)
                        : const Color(0xFF92400E),
                    boldColor: isEmergency
                        ? const Color(0xFF7F1D1D)
                        : const Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 3. Danh sách gạch đầu dòng (•, -, *)
      if (line.startsWith('•') ||
          line.startsWith('- ') ||
          line.startsWith('* ')) {
        final bulletText = line.replaceFirst(RegExp(r'^(•|\-|\*)\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                Expanded(
                  child: _buildRichTextWithBold(
                    bulletText,
                    fontSize: isMobile ? 13 : 14,
                    defaultColor: const Color(0xFF1E293B),
                    boldColor: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 4. Đoạn văn bản thông thường
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _buildRichTextWithBold(
            line,
            fontSize: isMobile ? 13 : 14,
            defaultColor: const Color(0xFF1E293B),
            boldColor: const Color(0xFF0F172A),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichTextWithBold(
    String text, {
    required double fontSize,
    required Color defaultColor,
    required Color boldColor,
  }) {
    final List<TextSpan> spans = [];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isBold = i % 2 == 1;
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? boldColor : defaultColor,
            height: 1.45,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildChatBottomInputBar(
    BuildContext context,
    UserViewModel viewModel, {
    bool isMobile = false,
  }) {
    final bool isThinking = viewModel.isAiThinking;
    final currentModel = viewModel.currentChatModel;

    return Container(
      height: isMobile ? 48 : 54,
      padding: EdgeInsets.only(left: isMobile ? 16 : 20, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080D2B6B),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: viewModel.chatInputController,
              enabled: !isThinking,
              onChanged: (value) =>
                  context.read<UserViewModel>().updateChatInput(value),
              onSubmitted: isThinking
                  ? null
                  : (value) =>
                        context.read<UserViewModel>().sendChatMessage(value),
              style: TextStyle(
                fontSize: isMobile ? 13.5 : 14.5,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: isThinking
                    ? '${currentModel.shortName} đang suy nghĩ câu trả lời...'
                    : 'Hỏi ${currentModel.shortName} về vết thương (Enter để gửi)...',
                hintStyle: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: isThinking
                ? const Color(0xFF94A3B8)
                : currentModel.brandColor,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isThinking
                  ? null
                  : () => context.read<UserViewModel>().sendChatMessage(),
              child: SizedBox(
                width: isMobile ? 36 : 40,
                height: isMobile ? 36 : 40,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 8.5 : 10),
                  child: isThinking
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const CustomPaint(painter: PaperPlaneSendIconPainter()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hộp thoại báo cáo câu trả lời AI Chat không chính xác về /admin
  void _showChatFeedbackDialog(BuildContext context, ChatMessageModel message) {
    final commentCtrl = TextEditingController(
      text: 'Lời khuyên sơ cứu của AI chưa phù hợp hoặc thiếu chính xác.',
    );
    String selectedCategory = 'Lời khuyên sơ cứu chưa chính xác';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.report_problem_rounded, color: Color(0xFFDC2626), size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Báo Cáo Phản Hồi AI Về /admin',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0D2B6B)),
                          ),
                        ),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Báo cáo của bạn sẽ được gửi đến ban quản trị /admin để giúp cải thiện và tinh chỉnh mô hình tốt hơn trong tương lai.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const Divider(height: 20),
                    const Text(
                      'Vấn đề gặp phải:',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        'Lời khuyên sơ cứu chưa chính xác',
                        'Chống chỉ định hoặc thiếu an toàn',
                        'Thông tin mơ hồ, không thực tế',
                        'Lý do khác',
                      ].map((cat) {
                        final isSel = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : const Color(0xFF334155))),
                          selected: isSel,
                          selectedColor: const Color(0xFFDC2626),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedCategory = cat);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mô tả chi tiết sai sót:',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: commentCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Nhập chi tiết điều AI nói chưa đúng chuẩn y tế...',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            final commentText = commentCtrl.text.trim();
                            AiFeedbackService.instance.submitFeedback(
                              AiFeedbackModel(
                                id: 'fb_chat_${DateTime.now().millisecondsSinceEpoch}',
                                timestamp: DateTime.now(),
                                userDisplayName: context.read<UserViewModel>().currentUserName,
                                sourceModel: message.modelSource == 'medgemma'
                                    ? AiSourceModel.medgemma
                                    : AiSourceModel.gemini,
                                feedbackType: AiFeedbackType.inaccurate,
                                issueCategory: selectedCategory,
                                userComment: commentText.isNotEmpty
                                    ? commentText
                                    : 'Lời khuyên sơ cứu của AI chưa chuẩn xác',
                                detectedWoundSummary: message.messageText.length > 80
                                    ? '${message.messageText.substring(0, 80)}...'
                                    : message.messageText,
                              ),
                            );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã gửi báo cáo ca chẩn đoán nghi ngờ về trang /admin thành công!'),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Gửi phản hồi báo sai'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      ),
    );
  }

}
