import 'package:flutter/foundation.dart';

/// Centralized logging utility.
/// In release builds (kReleaseMode), only errors are emitted (and currently no-op).
/// In debug/profile, logs are printed with simple level prefixes.
class AppLogger {
  static void d(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[D] $message');
    }
  }

  static void i(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[I] $message');
    }
  }

  static void w(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[W] $message');
    }
  }

  static void e(String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[E] $message${error != null ? ' :: $error' : ''}');
      if (stack != null) {
        // ignore: avoid_print
        print(stack);
      }
    }
  }
}
