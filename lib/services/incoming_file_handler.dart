import 'dart:async';

import 'package:flutter/services.dart';

/// Listens for incoming .myholiday files via the platform MethodChannel.
/// Handles both cold-start (initial intent) and warm-start (new intent while
/// app is running).
class IncomingFileHandler {
  static const _channel = MethodChannel('com.bradymd.my_holidays/share');

  static final _controller = StreamController<String>.broadcast();

  /// Stream of incoming file paths.
  static Stream<String> get incomingFiles => _controller.stream;

  /// Call once at app startup to register the method call handler and
  /// check for an initial file (cold start).
  static Future<void> init() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openFile') {
        final path = call.arguments as String?;
        if (path != null && path.isNotEmpty) {
          _controller.add(path);
        }
      }
    });

    // Check for a file passed on cold start
    try {
      final initialFile = await _channel.invokeMethod<String>('getInitialFile');
      if (initialFile != null && initialFile.isNotEmpty) {
        _controller.add(initialFile);
      }
    } on MissingPluginException {
      // No native handler yet (e.g. desktop) — ignore
    }
  }
}
