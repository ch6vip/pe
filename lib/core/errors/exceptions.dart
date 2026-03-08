import 'package:flutter/foundation.dart';

/// 应用异常基类
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('${runtimeType.toString()}')
      ..write(code != null ? ' ($code)' : '')
      ..write(': $message');
    if (originalError != null) {
      buffer..write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }
}

/// 网络相关异常
class NetworkException extends AppException {
  NetworkException(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: 'NETWORK_ERROR',
          originalError: error,
          stackTrace: stackTrace,
        );
}

/// 服务器异常
class ServerException extends AppException {
  final int? statusCode;

  ServerException(
    String message, {
    this.statusCode,
    dynamic error,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: 'SERVER_ERROR',
          originalError: error,
          stackTrace: stackTrace,
        );

  @override
  String toString() {
    final base = super.toString();
    return statusCode != null ? '$base (HTTP $statusCode)' : base;
  }
}

/// 缓存异常
class CacheException extends AppException {
  CacheException(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: 'CACHE_ERROR',
          originalError: error,
          stackTrace: stackTrace,
        );
}

/// 规则解析异常
class RuleParseException extends AppException {
  RuleParseException(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: 'RULE_PARSE_ERROR',
          originalError: error,
          stackTrace: stackTrace,
        );
}

/// 数据验证异常
class ValidationException extends AppException {
  final Map<String, dynamic>? details;

  ValidationException(
    String message, {
    this.details,
    dynamic error,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: 'VALIDATION_ERROR',
          originalError: error,
          stackTrace: stackTrace,
        );
}

/// 存储异常
class StorageException extends AppException {
  StorageException(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: 'STORAGE_ERROR',
          originalError: error,
          stackTrace: stackTrace,
        );
}

/// 权限异常
class PermissionException extends AppException {
  PermissionException(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: 'PERMISSION_ERROR',
          originalError: error,
          stackTrace: stackTrace,
        );
}

/// 未找到异常
class NotFoundException extends AppException {
  NotFoundException(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: 'NOT_FOUND',
          originalError: error,
          stackTrace: stackTrace,
        );
}

/// 解析异常 (HTML/JSON)
class ParsingException extends AppException {
  ParsingException(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: 'PARSING_ERROR',
          originalError: error,
          stackTrace: stackTrace,
        );
}

/// 功能未实现异常
class UnimplementedException extends AppException {
  UnimplementedException(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: 'UNIMPLEMENTED',
          originalError: error,
          stackTrace: stackTrace,
        );
}
