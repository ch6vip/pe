import 'package:logger/logger.dart' as logger;
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

class AppLogger {
  static final logger.Logger _logger = logger.Logger(
    printer: _CustomPrinter(),
    level: AppConstants.enableDebugLog ? logger.Level.debug : logger.Level.info,
  );

  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (AppConstants.enableDebugLog) {
      _logger.d(message, error, stackTrace);
    }
  }

  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error, stackTrace);
  }

  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error, stackTrace);
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error, stackTrace);
  }

  static void v(String message, [dynamic error, StackTrace? stackTrace]) {
    if (AppConstants.enableDebugLog) {
      _logger.v(message, error, stackTrace);
    }
  }

  static void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.wtf(message, error, stackTrace);
  }
}

/// 自定义打印机，输出更简洁的日志格式
class _CustomPrinter extends logger.Printer {
  @override
  List<String> log(logger.LogEvent event) {
    final timestamp = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
    final message = event.message;

    String level;
    switch (event.level) {
      case logger.Level.verbose:
        level = '🔹';
        break;
      case logger.Level.debug:
        level = '🐛';
        break;
      case logger.Level.info:
        level = 'ℹ️';
        break;
      case logger.Level.warning:
        level = '⚠️';
        break;
      case logger.Level.error:
        level = '❌';
        break;
      case logger.Level.wtf:
        level = '💥';
        break;
      default:
        level = '📝';
    }

    final buffer = StringBuffer()
      ..write('[$timestamp] ')
      ..write(level)
      ..write(' ')
      ..write(message);

    if (event.error != null) {
      buffer..write('\n  Error: ${event.error}');
    }
    if (event.stackTrace != null) {
      buffer..write('\n  Stack: ${event.stackTrace}');
    }

    return [buffer.toString()];
  }
}
