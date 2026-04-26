import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void info(String message) {
    debugPrint('ℹ️ $message');
  }

  static void warn(String message) {
    debugPrint('⚠️ $message');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('❌ $message');
    if (error != null) {
      debugPrint('   Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('   StackTrace: $stackTrace');
    }
  }
}
