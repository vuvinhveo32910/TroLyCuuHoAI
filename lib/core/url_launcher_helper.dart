import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper tiện ích hỗ trợ mở đường dẫn web (URL) trên trình duyệt mặc định của hệ thống
class UrlLauncherHelper {
  /// Mở đường dẫn web (URL) trên trình duyệt mặc định (Chrome, Edge, Safari, ...)
  static Future<bool> launchWebUrl(
    BuildContext context,
    String? rawUrl, {
    String? fallbackTitle,
  }) async {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Đường dẫn liên kết (URL) đang trống hoặc chưa được cấu hình.')),
              ],
            ),
            backgroundColor: Color(0xFFD97706),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    String formatted = rawUrl.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'https://$formatted';
    }

    final uri = Uri.tryParse(formatted);
    if (uri == null || !uri.hasScheme) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Đường dẫn không hợp lệ: $rawUrl')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Thử lại với platformDefault nếu externalApplication thất bại
        final bool retry = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!retry && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Không thể mở đường dẫn: $formatted')),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return retry;
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Lỗi khi mở liên kết web: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}
