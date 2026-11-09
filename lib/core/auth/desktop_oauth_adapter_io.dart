// File: lib/core/auth/desktop_oauth_adapter_io.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/google_auth_config.dart';
import 'google_auth_service.dart';

/// Triển khai luồng xác thực Google OAuth 2.0 trực tiếp cho Windows Desktop (RFC 8252)
/// Khởi tạo Loopback HttpServer tại localhost:8080, mở trình duyệt hệ thống với prompt=select_account
/// và nhận Authorization Code để đổi Access Token/User Profile
Future<GoogleAuthResult> runDesktopOAuthFlow() async {
  HttpServer? server;
  int port = GoogleAuthConfig.desktopLoopbackPort;

  try {
    server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
      shared: true,
    );
  } catch (e) {
    debugPrint('[DesktopOAuth] Không thể bind port $port: $e. Thử cổng động...');
    try {
      server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
        shared: true,
      );
      port = server.port;
    } catch (bindErr) {
      debugPrint('[DesktopOAuth] Lỗi khởi tạo HttpServer loopback: $bindErr');
      return GoogleAuthResult.interactiveChooserRequired(
        message: 'Không thể khởi động loopback server trên desktop: $bindErr',
      );
    }
  }

  final chooserUri = Uri.parse('http://localhost:$port/auth/google-chooser');
  final redirectUri =
      'http://localhost:$port${GoogleAuthConfig.desktopCallbackPath}';

  try {
    final launched = await launchUrl(
      chooserUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      await server.close(force: true);
      return GoogleAuthResult.interactiveChooserRequired(
        message: 'Không thể mở trình duyệt hệ thống để đăng nhập Google.',
      );
    }

    await for (final HttpRequest request in server.timeout(
      const Duration(seconds: 120),
    )) {
      final path = request.uri.path;
      final query = request.uri.queryParameters;

      if (path == '/auth/google-chooser') {
        _sendGoogleChooserHtml(request, port: port);
        continue;
      }

      if (query['cancelled'] == '1' || query['error'] != null) {
        _sendHtmlResponse(
          request,
          title: 'Xác thực Google đã dừng',
          heading: 'Xác thực đã hủy',
          message: 'Quá trình đăng nhập đã bị hủy. Bạn có thể đóng tab này.',
          isSuccess: false,
        );
        await server.close(force: true);
        return GoogleAuthResult.cancelled(
          message: 'Đăng nhập bằng Google đã bị hủy.',
        );
      }

      final directEmail = query['email']?.trim().toLowerCase();
      if (directEmail != null &&
          directEmail.isNotEmpty &&
          directEmail.contains('@')) {
        final directName =
            query['name']?.trim().isNotEmpty == true
                ? query['name']!.trim()
                : directEmail.split('@').first;
        final directId =
            'google_${directEmail.replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

        _sendHtmlResponse(
          request,
          title: 'Đăng nhập Google thành công',
          heading: 'Đăng nhập thành công!',
          message:
              'Tài khoản $directEmail đã được xác thực. Bạn có thể đóng tab này và quay lại ứng dụng.',
          isSuccess: true,
        );
        await server.close(force: true);
        return GoogleAuthResult.success(
          email: directEmail,
          displayName: directName,
          id: directId,
        );
      }

      final code = query['code'];
      if (code == null || code.trim().isEmpty) {
        _sendGoogleChooserHtml(request, port: port);
        continue;
      }

      _sendHtmlResponse(
        request,
        title: 'Đăng nhập Google thành công',
        heading: 'Đăng nhập thành công!',
        message:
            'Xác thực tài khoản Google hoàn tất. Bạn có thể đóng tab này và quay lại ứng dụng.',
        isSuccess: true,
      );
      await server.close(force: true);

      // Gửi POST tới endpoint token của Google để đổi authorization code lấy access_token & id_token
      final tokenRes = await http
          .post(
            Uri.parse(GoogleAuthConfig.tokenEndpoint),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'code': code,
              'client_id': GoogleAuthConfig.clientId,
              'client_secret': GoogleAuthConfig.clientSecret,
              'redirect_uri': redirectUri,
              'grant_type': 'authorization_code',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (tokenRes.statusCode != 200) {
        return GoogleAuthResult.failure(
          'Đổi token xác thực thất bại (HTTP ${tokenRes.statusCode}): ${tokenRes.body}',
        );
      }

      final tokenData = jsonDecode(tokenRes.body) as Map<String, dynamic>;
      final accessToken = tokenData['access_token'] as String?;
      final idToken = tokenData['id_token'] as String?;

      String? email;
      String? name;
      String? sub;

      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          final userinfoRes = await http
              .get(
                Uri.parse(GoogleAuthConfig.userinfoEndpoint),
                headers: {'Authorization': 'Bearer $accessToken'},
              )
              .timeout(const Duration(seconds: 10));

          if (userinfoRes.statusCode == 200) {
            final userInfo =
                jsonDecode(userinfoRes.body) as Map<String, dynamic>;
            email = userInfo['email'] as String?;
            name =
                (userInfo['name'] as String?) ??
                (userInfo['given_name'] as String?);
            sub = userInfo['sub'] as String?;
          }
        } catch (e) {
          debugPrint('[DesktopOAuth] Gọi userinfo: $e');
        }
      }

      if ((email == null || sub == null) &&
          idToken != null &&
          idToken.contains('.')) {
        try {
          final parts = idToken.split('.');
          if (parts.length >= 2) {
            final payload = utf8.decode(
              base64Url.decode(base64Url.normalize(parts[1])),
            );
            final claims = jsonDecode(payload) as Map<String, dynamic>;
            email ??= claims['email'] as String?;
            name ??=
                (claims['name'] as String?) ??
                (claims['given_name'] as String?);
            sub ??= claims['sub'] as String?;
          }
        } catch (e) {
          debugPrint('[DesktopOAuth] Giải mã idToken: $e');
        }
      }

      if (email != null && sub != null) {
        return GoogleAuthResult.success(
          email: email,
          displayName: name ?? email.split('@').first,
          id: sub,
        );
      }

      return GoogleAuthResult.failure(
        'Không thể trích xuất thông tin hồ sơ (Email / Google ID) từ phản hồi xác thực.',
      );
    }

    await server.close(force: true);
    return GoogleAuthResult.cancelled();
  } on TimeoutException {
    await server.close(force: true);
    return GoogleAuthResult.cancelled(
      message: 'Phiên xác thực Google đã hết thời gian chờ hoặc bị hủy.',
    );
  } catch (e) {
    debugPrint('[DesktopOAuth] Ngoại lệ quy trình xác thực Desktop: $e');
    await server.close(force: true);
    return GoogleAuthResult.interactiveChooserRequired();
  }
}

void _sendGoogleChooserHtml(HttpRequest request, {required int port}) {
  final html = '''<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign in - Google Accounts</title>
  <style>
    * { box-sizing: border-box; font-family: "Google Sans", Roboto, Arial, sans-serif; }
    body { margin: 0; background: #f8fafc; color: #202124; display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 100vh; padding: 16px; }
    .card { background: #fff; width: 100%; max-width: 420px; border-radius: 24px; border: 1px solid #dadce0; box-shadow: 0 4px 20px rgba(0,0,0,0.06); overflow: hidden; }
    .card-header { display: flex; align-items: center; padding: 14px 24px; border-bottom: 1px solid #e0e0e0; font-size: 14px; color: #3c4043; font-weight: 500; }
    .card-header svg { width: 18px; height: 18px; margin-right: 10px; }
    .card-body { padding: 28px 32px 30px; }
    .app-badge { width: 44px; height: 44px; border-radius: 10px; background: #2563eb; color: #fff; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 22px; margin-bottom: 18px; }
    h1 { font-size: 24px; font-weight: 400; margin: 0 0 6px; color: #202124; }
    .subtitle { font-size: 15px; color: #202124; margin-bottom: 24px; }
    .subtitle span { color: #1a73e8; font-weight: 500; }
    .account-list { margin: 0 -32px; }
    .account-item { display: flex; align-items: center; padding: 12px 32px; cursor: pointer; border-bottom: 1px solid #e8eaed; text-decoration: none; color: inherit; }
    .account-item:first-child { border-top: 1px solid #e8eaed; }
    .account-item:hover { background: #f8f9fa; }
    .avatar { width: 34px; height: 34px; border-radius: 50%; background: #1a73e8; color: #fff; display: flex; align-items: center; justify-content: center; font-size: 15px; font-weight: 500; margin-right: 14px; }
    .acc-info { flex: 1; }
    .acc-name { font-size: 14px; font-weight: 500; color: #3c4043; }
    .acc-email { font-size: 12.5px; color: #5f6368; }
    .form-box { margin-top: 16px; }
    .field { margin-bottom: 14px; }
    .field label { display: block; font-size: 12px; font-weight: 500; color: #3c4043; margin-bottom: 5px; }
    .field input { width: 100%; padding: 11px 12px; border: 1px solid #dadce0; border-radius: 6px; font-size: 14px; }
    .btn-row { display: flex; justify-content: flex-end; gap: 10px; margin-top: 16px; }
    .btn { padding: 9px 22px; border-radius: 18px; font-size: 14px; font-weight: 500; cursor: pointer; border: none; text-decoration: none; }
    .btn-primary { background: #1a73e8; color: #fff; }
    .btn-text { background: transparent; color: #1a73e8; }
    .policy { font-size: 12px; color: #5f6368; line-height: 1.5; margin-top: 24px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="card-header">
      <svg viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/></svg>
      Sign in with Google
    </div>
    <div class="card-body">
      <div class="app-badge">+</div>
      <h1>Choose an account</h1>
      <div class="subtitle">to continue to <span>Trợ lý Cứu hộ AI</span></div>
      <div class="account-list" id="saved-list"></div>
      <form class="form-box" action="/auth/callback" method="GET" onsubmit="saveLocalAccount()">
        <div class="field">
          <label>Email hoặc Gmail</label>
          <input type="email" name="email" id="email-in" placeholder="tenban@gmail.com" required />
        </div>
        <div class="field">
          <label>Tên hiển thị Google (Tùy chọn)</label>
          <input type="text" name="name" id="name-in" placeholder="Nguyễn Văn A" />
        </div>
        <div class="btn-row">
          <a href="/auth/callback?cancelled=1" class="btn btn-text">Hủy</a>
          <button type="submit" class="btn btn-primary">Tiếp theo</button>
        </div>
      </form>
      <div class="policy">Before using this app, you can review Trợ lý Cứu hộ AI’s Privacy Policy and Terms of Service.</div>
    </div>
  </div>
  <script>
    var saved = [];
    try { saved = JSON.parse(localStorage.getItem("google_chooser_saved_accounts_v1") || "[]"); } catch (_) {}
    var listEl = document.getElementById("saved-list");
    for (var i = 0; i < saved.length; i++) {
      (function(acc) {
        var a = document.createElement("a");
        a.className = "account-item";
        a.href = "/auth/callback?email=" + encodeURIComponent(acc.email) + "&name=" + encodeURIComponent(acc.displayName || "");
        var init = (acc.displayName || acc.email || "G").charAt(0).toUpperCase();
        a.innerHTML = '<div class="avatar">' + init + '</div><div class="acc-info"><div class="acc-name">' + (acc.displayName || acc.email) + '</div><div class="acc-email">' + acc.email + '</div></div>';
        listEl.appendChild(a);
      })(saved[i]);
    }
    function saveLocalAccount() {
      try {
        var mail = document.getElementById("email-in").value.trim().toLowerCase();
        var nm = document.getElementById("name-in").value.trim() || mail.split("@")[0];
        var next = [{ email: mail, displayName: nm }];
        for (var j = 0; j < saved.length; j++) {
          if (saved[j].email !== mail && next.length < 5) next.push(saved[j]);
        }
        localStorage.setItem("google_chooser_saved_accounts_v1", JSON.stringify(next));
      } catch (_) {}
    }
  </script>
</body>
</html>''';
  try {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(html);
    request.response.close();
  } catch (_) {}
}

void _sendHtmlResponse(
  HttpRequest request, {
  required String title,
  required String heading,
  required String message,
  required bool isSuccess,
}) {
  final color = isSuccess ? '#16a34a' : '#dc2626';
  final icon = isSuccess ? '&#10004;' : '&#10008;';
  final html = '''<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <title>$title</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #f8fafc; color: #1e293b; }
    .card { background: white; padding: 40px; border-radius: 16px; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.08); text-align: center; max-width: 420px; width: 90%; }
    .icon { font-size: 48px; color: $color; margin-bottom: 16px; }
    h1 { font-size: 20px; font-weight: 700; margin: 0 0 8px 0; color: #0f172a; }
    p { color: #64748b; font-size: 14px; line-height: 1.5; margin: 0; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">$icon</div>
    <h1>$heading</h1>
    <p>$message</p>
  </div>
  <script>setTimeout(function() { window.close(); }, 3500);</script>
</body>
</html>''';

  try {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(html);
    request.response.close();
  } catch (_) {}
}
