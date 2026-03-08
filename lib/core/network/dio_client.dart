import 'package:dio/dio.dart';
import 'package:reader_flutter/core/constants/app_constants.dart';
import 'package:reader_flutter/core/logger/logger.dart';

/// Dio HTTP 客户端封装
///
/// 提供统一的网络请求配置、拦截器、错误处理和重试机制
class DioClient {
  final Dio _dio;

  /// 创建 Dio 客户端实例
  ///
  /// [baseUrl] - 基础 URL（可选）
  /// [interceptors] - 自定义拦截器（可选）
  DioClient({
    String? baseUrl,
    List<Interceptor>? interceptors,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? '',
            connectTimeout: AppConstants.timeout,
            receiveTimeout: AppConstants.timeout,
            sendTimeout: AppConstants.timeout,
            headers: AppConstants.defaultHeaders,
            responseType: ResponseType.json,
            followRedirects: true,
            validateStatus: (status) => status != null && status < 500,
          ),
        ) {
    // 添加默认拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.d(
            '→ ${options.method} ${options.uri}',
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.d(
            '← ${response.statusCode} ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.e(
            '✗ ${error.type} ${error.requestOptions.uri}',
            error: error.message,
          );
          return handler.next(error);
        },
      ),
    );

    // 添加自定义拦截器
    if (interceptors != null) {
      _dio.interceptors.addAll(interceptors);
    }
  }

  /// 获取 Dio 实例（用于高级操作）
  Dio get dio => _dio;

  /// GET 请求
  ///
  /// [path] - 请求路径（相对于 baseUrl）
  /// [queryParameters] - 查询参数
  /// [options] - 请求选项
  /// [data] - 请求体（用于带参数的 GET）
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    dynamic data,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        data: data,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST 请求
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT 请求
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE 请求
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 处理 Dio 异常并转换为应用异常
  AppException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          '请求超时',
          error: e.message,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = _extractErrorMessage(e.response);
        return ServerException(
          message ?? '服务器错误',
          statusCode: statusCode,
          error: e.message,
        );

      case DioExceptionType.cancel:
        return NetworkException(
          '请求被取消',
          error: e.message,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          '网络连接失败',
          error: e.message,
        );

      default:
        return NetworkException(
          '网络请求失败',
          error: e.message,
        );
    }
  }

  /// 从响应中提取错误消息
  String? _extractErrorMessage(Response? response) {
    if (response?.data is Map) {
      final data = response!.data as Map;
      if (data.containsKey('message')) {
        return data['message']?.toString();
      }
      if (data.containsKey('error')) {
        return data['error']?.toString();
      }
    }
    return response?.statusMessage;
  }

  /// 释放资源
  void dispose() {
    _dio.close();
  }
}
