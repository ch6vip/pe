import 'package:logger/logger.dart' as logger;
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

class AppLogger {
  static final logger.Logger _logger = logger.Logger(
    printer: _CustomPrinter(),
    level: AppConstants.enableDebugLog ? logger.Level.debug : logger.Level.info,
  );

  static void d(String message) {
    if (AppConstants.enableDebugLog) {
      _logger.d(message);
    }
  }

  static void i(String message) {
    _logger.i(message);
  }

  static void w(String message) {
    _logger.w(message);
  }

  static void e(String message) {
    _logger.e(message);
  }

  static void v(String message) {
    if (AppConstants.enableDebugLog) {
      _logger.v(message);
    }
  }

  static void wtf(String message) {
    _logger.wtf(message);
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
