import 'dart:ui';

import 'package:flutter/material.dart';

/// Cho phép nhấn giữ và kéo (drag to scroll) bằng cả Chuột máy tính (Mouse),
/// Cảm ứng (Touch), Trackpad và Bút cảm ứng trên Flutter Web & Desktop.
class AppCustomScrollBehavior extends MaterialScrollBehavior {
  const AppCustomScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
