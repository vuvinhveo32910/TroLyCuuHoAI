import 'dart:typed_data';

import 'package:flutter/material.dart';

class ChatMessageModel {
  final String id;
  final bool isUser;
  final String messageText;
  final List<String> numberedSteps;
  final String timestamp;
  final String? relatedTopicId;
  final String? modelSource;
  final String evidenceLabel;
  final String notice;
  final List<ChatCitation> citations;
  final List<ChatGuideOption> guideOptions;
  final String? originalQuestion;
  final String? suggestedQuery;
  final double? elapsedSeconds;
  final Uint8List? imageBytes;
  final String? imageName;

  const ChatMessageModel({
    required this.id,
    required this.isUser,
    required this.messageText,
    this.numberedSteps = const [],
    required this.timestamp,
    this.relatedTopicId,
    this.modelSource,
    this.evidenceLabel = '',
    this.notice = '',
    this.citations = const [],
    this.guideOptions = const [],
    this.originalQuestion,
    this.suggestedQuery,
    this.elapsedSeconds,
    this.imageBytes,
    this.imageName,
  });
}

class ChatCitation {
  final String title;
  final String pages;
  final Uri url;
  const ChatCitation({
    required this.title,
    required this.pages,
    required this.url,
  });
}

class ChatGuideOption {
  final int id;
  final String title;
  const ChatGuideOption({required this.id, required this.title});
}

/// Mô hình thông tin định danh cho từng Model AI trong danh sách chọn (Model Switcher)
class ChatModelInfo {
  final String id;
  final String name;
  final String shortName;
  final String description;
  final String provider;
  final IconData icon;
  final Color brandColor;
  final String tagLabel;
  final Color tagColor;
  final bool isBeta;

  const ChatModelInfo({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.provider,
    required this.icon,
    required this.brandColor,
    required this.tagLabel,
    required this.tagColor,
    this.isBeta = false,
  });
}

/// Danh sách 2 model cốt lõi của hệ thống (Gemini & MedGemma Server)
const List<ChatModelInfo> kDefaultChatModels = [
  ChatModelInfo(
    id: 'gemini',
    name: 'Google Gemini 3.8 Flash',
    shortName: 'Gemini 3.8 Flash',
    description: 'Mô hình Flash thế hệ 3.8 mới nhất của Google DeepMind. Tốc độ vượt trội, xử lý suy luận nhiều bước, hỗ trợ tư vấn sơ cứu tổn thương da và chuẩn hóa y tế 24/7.',
    provider: 'Google AI Studio (gemini-3.8-flash)',
    icon: Icons.auto_awesome,
    brandColor: Color(0xFF2563EB),
    tagLabel: 'Bản 3.8 Flash',
    tagColor: Color(0xFF10B981),
    isBeta: false,
  ),
  ChatModelInfo(
    id: 'medgemma',
    name: 'MedGemma 1.5 4B',
    shortName: 'MedGemma (LAN Server)',
    description: 'Chạy trên máy chủ của nhóm, nạp một lần ở chế độ NF4 4-bit. Ưu tiên tra tài liệu SQLite; thiếu nguồn mới sinh câu trả lời.',
    provider: 'Máy chủ nội bộ của nhóm',
    icon: Icons.health_and_safety_rounded,
    brandColor: Color(0xFF7C3AED),
    tagLabel: 'Server LAN (Thử nghiệm)',
    tagColor: Color(0xFF8B5CF6),
    isBeta: true,
  ),
];
