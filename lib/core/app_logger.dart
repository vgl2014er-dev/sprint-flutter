import 'dart:developer' as developer;

/// Centralized logging helper for runtime diagnostics.
class AppLogger {
  static void info(String message, {String name = _defaultName}) {
    developer.log(message, name: name, level: 800);
  }

  static void warning(
    String message, {
    String name = _defaultName,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    String name = _defaultName,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static const String _defaultName = 'sprint.app';
}
