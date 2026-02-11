import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 应用日志服务
///
/// 收集和管理应用运行时的日志信息
/// 包括调试信息、警告和错误
class AppLogService {
  /// 单例模式
  static final AppLogService _instance = AppLogService._internal();
  factory AppLogService() => _instance;
  AppLogService._internal();

  /// 日志条目列表
  final List<LogEntry> _logs = [];

  /// 日志流控制器，用于通知UI更新
  final _logController = StreamController<List<LogEntry>>.broadcast();

  /// 日志流
  Stream<List<LogEntry>> get logStream => _logController.stream;

  /// 最大日志条数
  static const int _maxLogs = 500;

  /// 获取所有日志
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// 添加调试日志
  void debug(String message, {String? tag}) {
    _addLog(LogEntry(
      level: LogLevel.debug,
      message: message,
      tag: tag ?? 'Debug',
      timestamp: DateTime.now(),
    ));
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  /// 添加信息日志
  void info(String message, {String? tag}) {
    _addLog(LogEntry(
      level: LogLevel.info,
      message: message,
      tag: tag ?? 'Info',
      timestamp: DateTime.now(),
    ));
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  /// 添加警告日志
  void warning(String message, {String? tag}) {
    _addLog(LogEntry(
      level: LogLevel.warning,
      message: message,
      tag: tag ?? 'Warning',
      timestamp: DateTime.now(),
    ));
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  /// 添加错误日志
  void error(String message,
      {Object? error, StackTrace? stackTrace, String? tag}) {
    final buffer = StringBuffer(message);
    if (error != null) {
      buffer.write(': $error');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }

    _addLog(LogEntry(
      level: LogLevel.error,
      message: buffer.toString(),
      tag: tag ?? 'Error',
      timestamp: DateTime.now(),
    ));
    if (kDebugMode) {
      debugPrint('[$tag] $buffer');
    }
  }

  /// 添加日志条目
  void _addLog(LogEntry entry) {
    _logs.add(entry);

    // 限制日志数量
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // 通知监听者
    _logController.add(List.from(_logs));
  }

  /// 清空所有日志
  void clear() {
    _logs.clear();
    _logController.add([]);
    if (kDebugMode) {
      debugPrint('AppLogService: 日志已清空');
    }
  }

  /// 根据级别筛选日志
  ///
  /// 返回指定日志级别的所有日志条目
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// 根据标签筛选日志
  ///
  /// 返回指定标签的所有日志条目，不区分大小写
  List<LogEntry> getLogsByTag(String tag) {
    return _logs.where((log) => log.tag.toLowerCase() == tag.toLowerCase()).toList();
  }

  /// 导出日志为文本
  String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== 应用日志导出 ===');
    buffer.writeln('导出时间: ${DateTime.now()}');
    buffer.writeln('总日志数: ${_logs.length}');
    buffer.writeln('');

    for (final log in _logs) {
      buffer.writeln(
          '[${log.timestamp}] [${log.level.displayName}] [${log.tag}]');
      buffer.writeln('  ${log.message}');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// 释放资源
  void dispose() {
    _logController.close();
  }
}

/// 日志级别
enum LogLevel {
  debug('调试', Icons.bug_report_outlined, Colors.grey),
  info('信息', Icons.info_outline, Colors.blue),
  warning('警告', Icons.warning_outlined, Colors.orange),
  error('错误', Icons.error_outline, Colors.red);

  final String displayName;
  final IconData icon;
  final Color color;

  const LogLevel(this.displayName, this.icon, this.color);
}

/// 日志条目
class LogEntry {
  final LogLevel level;
  final String message;
  final String tag;
  final DateTime timestamp;

  const LogEntry({
    required this.level,
    required this.message,
    required this.tag,
    required this.timestamp,
  });

  @override
  String toString() {
    return '[$timestamp] [$level] [$tag] $message';
  }
}
