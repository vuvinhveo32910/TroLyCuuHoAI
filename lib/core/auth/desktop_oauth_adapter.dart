// File: lib/core/auth/desktop_oauth_adapter.dart
export 'desktop_oauth_adapter_stub.dart'
    if (dart.library.io) 'desktop_oauth_adapter_io.dart'
    if (dart.library.js_interop) 'desktop_oauth_adapter_web.dart';
