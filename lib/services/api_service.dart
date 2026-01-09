import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/models/book_source.dart';
import 'package:reader_flutter/models/chapter.dart';
import 'package:reader_flutter/models/chapter_content.dart';
import 'package:reader_flutter/services/app_log_service.dart';

/// API 请求异常
///
/// 用于封装 API 调用过程中的错误信息
class ApiException implements Exception {
  /// 错误消息
  final String message;

  /// HTTP 状态码（如果有）
  final int? statusCode;

  /// 原始异常（如果有）
  final Object? originalError;

  const ApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (状态码: $statusCode)' : ''}';
}

/// API 服务类
///
/// 负责与后端 API 进行通信，提供书籍搜索、详情、章节列表和章节内容的获取功能
class ApiService {
  /// HTTP 请求超时时间
  static const Duration _requestTimeout = Duration(seconds: 15);

  /// HTTP 客户端（可注入用于测试）
  final http.Client _client;

  /// 日志服务
  final AppLogService _logService = AppLogService();

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // ==================== 公共方法 ====================

  /// 获取原始响应（供调试与解析器使用）
  Future<http.Response> fetchRaw(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw const ApiException('URL 不能为空');
    }
    try {
      return await _getWithTimeout(Uri.parse(trimmed));
    } catch (e, stackTrace) {
      _logService.error(
        '获取原始响应失败：$trimmed',
        error: e,
        stackTrace: stackTrace,
        tag: 'ApiService',
      );
      if (e is ApiException) rethrow;
      throw ApiException('获取原始响应失败', originalError: e);
    }
  }

  /// 搜索书籍
  ///
  /// [source] - 书源
  /// [keyword] - 搜索关键词
  /// [page] - 页码（从 1 开始）
  ///
  /// Returns: 匹配的书籍列表
  ///
  /// Throws:
  /// - [ApiException] 当搜索请求失败时
  Future<List<Book>> searchBooks(
    BookSource source,
    String keyword, {
    int page = 1,
  }) async {
    _ensureSource(source);

    if (keyword.trim().isEmpty) {
      _logService.debug('搜索关键词为空，返回空结果', tag: 'ApiService');
      return [];
    }

    final searchUrl = source.searchUrl?.trim() ?? '';
    if (searchUrl.isEmpty) {
      _logService.error('书源未配置搜索地址', tag: 'ApiService');
      throw const ApiException('搜索地址缺失');
    }

    final normalizedPage = page < 1 ? 1 : page;
    final requestUrl = _buildSearchUrl(
      source.bookSourceUrl,
      searchUrl,
      keyword.trim(),
      normalizedPage,
    );

    _logService.info('搜索书籍：$keyword (第$normalizedPage页)', tag: 'ApiService');

    try {
      final response = await _getWithTimeout(Uri.parse(requestUrl));

      if (response.statusCode != 200) {
        _logService.error(
          '搜索书籍失败，状态码：${response.statusCode}',
          tag: 'ApiService',
        );
        throw ApiException('搜索书籍失败', statusCode: response.statusCode);
      }

      if (!_isLikelyJson(response)) {
        throw const ApiException('搜索解析未集成，请配置 JSON 接口或接入解析引擎');
      }

      final books = _extractSearchBooks(response);
      _logService.info('搜索完成，找到${books.length}本书', tag: 'ApiService');
      return books;
    } catch (e, stackTrace) {
      _logService.error(
        '搜索书籍失败：$keyword',
        error: e,
        stackTrace: stackTrace,
        tag: 'ApiService',
      );
      if (e is ApiException) rethrow;
      throw ApiException('搜索书籍失败', originalError: e);
    }
  }

  /// 获取书籍详情
  ///
  /// [source] - 书源
  /// [bookUrl] - 详情页 URL（可为相对路径）
  ///
  /// Returns: 书籍详情
  ///
  /// Throws:
  /// - [ApiException] 当请求失败或数据格式错误时
  Future<Book> getBookDetail(BookSource source, String bookUrl) async {
    _ensureSource(source);

    if (bookUrl.trim().isEmpty) {
      _logService.error('书籍详情地址为空', tag: 'ApiService');
      throw const ApiException('书籍详情地址不能为空');
    }

    final requestUrl = _buildFullUrl(source.bookSourceUrl, bookUrl.trim());
    _logService.info('获取书籍详情：$requestUrl', tag: 'ApiService');

    try {
      final response = await _getWithTimeout(Uri.parse(requestUrl));

      if (response.statusCode != 200) {
        _logService.error(
          '获取书籍详情失败，状态码：${response.statusCode}',
          tag: 'ApiService',
        );
        throw ApiException('获取书籍详情失败', statusCode: response.statusCode);
      }

      if (!_isLikelyJson(response)) {
        throw const ApiException('书籍详情解析未集成，请配置 JSON 接口或接入解析引擎');
      }

      final body = _decodeResponse(response);
      final data = body['data'] ?? body;
      if (data is Map<String, dynamic>) {
        final book = Book.fromJson(data);
        _logService.info('获取书籍详情成功：${book.name}', tag: 'ApiService');
        return book;
      }

      throw const ApiException('书籍详情数据格式错误');
    } catch (e, stackTrace) {
      _logService.error(
        '获取书籍详情失败：$bookUrl',
        error: e,
        stackTrace: stackTrace,
        tag: 'ApiService',
      );
      if (e is ApiException) rethrow;
      throw ApiException('获取书籍详情失败', originalError: e);
    }
  }

  /// 获取书籍的章节列表
  ///
  /// [source] - 书源
  /// [tocUrl] - 目录页 URL（可为相对路径）
  ///
  /// Returns: 章节列表
  ///
  /// Throws:
  /// - [ApiException] 当请求失败或数据格式错误时
  Future<List<Chapter>> getChapters(BookSource source, String tocUrl) async {
    _ensureSource(source);

    if (tocUrl.trim().isEmpty) {
      _logService.error('目录地址为空', tag: 'ApiService');
      throw const ApiException('目录地址不能为空');
    }

    final requestUrl = _buildFullUrl(source.bookSourceUrl, tocUrl.trim());
    _logService.info('获取章节列表：$requestUrl', tag: 'ApiService');

    try {
      final response = await _getWithTimeout(Uri.parse(requestUrl));

      if (response.statusCode != 200) {
        _logService.error(
          '获取章节列表失败，状态码：${response.statusCode}',
          tag: 'ApiService',
        );
        throw ApiException('获取章节列表失败', statusCode: response.statusCode);
      }

      if (!_isLikelyJson(response)) {
        throw const ApiException('目录解析未集成，请配置 JSON 接口或接入解析引擎');
      }

      final body = _decodeResponse(response);
      dynamic data = body['data'];

      List<dynamic>? itemList;

      if (data is Map<String, dynamic>) {
        itemList = (data['item_data_list'] ??
            data['item_list'] ??
            data['chapter_list'] ??
            data['chapters'] ??
            data['list']) as List<dynamic>?;
      } else if (data is List) {
        itemList = data;
      }

      itemList ??= (body['item_data_list'] ??
          body['item_list'] ??
          body['chapter_list'] ??
          body['chapters'] ??
          body['list']) as List<dynamic>?;

      if (itemList == null) {
        final responseSummary = _getResponseSummary(body);
        _logService.error('章节列表解析失败，响应结构: $responseSummary', tag: 'ApiService');
        _logService.debug('完整响应数据(仅Debug模式): $body', tag: 'ApiService');
        throw const ApiException('章节列表数据格式错误');
      }

      final chapters = <Chapter>[];
      int failedCount = 0;

      for (int i = 0; i < itemList.length; i++) {
        try {
          final item = itemList[i];
          if (item is Map<String, dynamic>) {
            final chapter = Chapter.fromJson(item);
            chapters.add(chapter);
          } else {
            failedCount++;
            _logService.warning(
              '章节${i + 1}数据格式错误，跳过: ${item.runtimeType}',
              tag: 'ApiService',
            );
          }
        } catch (e, stackTrace) {
          failedCount++;
          _logService.error(
            '章节${i + 1}解析失败，跳过',
            error: e,
            stackTrace: stackTrace,
            tag: 'ApiService',
          );
        }
      }

      if (chapters.isEmpty) {
        _logService.error('所有章节解析均失败', tag: 'ApiService');
        throw const ApiException('章节列表解析失败');
      }

      if (failedCount > 0) {
        _logService.warning(
          '章节列表解析完成，成功${chapters.length}章，失败$failedCount章',
          tag: 'ApiService',
        );
      } else {
        _logService.info('获取章节列表成功，共${chapters.length}章', tag: 'ApiService');
      }

      return chapters;
    } catch (e, stackTrace) {
      _logService.error(
        '获取章节列表失败：$tocUrl',
        error: e,
        stackTrace: stackTrace,
        tag: 'ApiService',
      );
      if (e is ApiException) rethrow;
      throw ApiException('获取章节列表失败', originalError: e);
    }
  }

  /// 获取章节内容
  ///
  /// [source] - 书源
  /// [contentUrl] - 正文页 URL（可为相对路径）
  ///
  /// Returns: 章节内容
  ///
  /// Throws:
  /// - [ApiException] 当请求失败或数据格式错误时
  Future<ChapterContent> getContent(
    BookSource source,
    String contentUrl,
  ) async {
    _ensureSource(source);

    if (contentUrl.trim().isEmpty) {
      _logService.error('正文地址为空', tag: 'ApiService');
      throw const ApiException('正文地址不能为空');
    }

    final requestUrl = _buildFullUrl(source.bookSourceUrl, contentUrl.trim());
    _logService.info('获取章节内容：$requestUrl', tag: 'ApiService');

    try {
      final response = await _getWithTimeout(Uri.parse(requestUrl));

      if (response.statusCode != 200) {
        _logService.error(
          '获取章节内容失败，状态码：${response.statusCode}',
          tag: 'ApiService',
        );
        throw ApiException('获取章节内容失败', statusCode: response.statusCode);
      }

      if (!_isLikelyJson(response)) {
        throw const ApiException('正文解析未集成，请配置 JSON 接口或接入解析引擎');
      }

      final body = _decodeResponse(response);
      final content = ChapterContent.fromJson(body);
      _logService.info('获取章节内容成功', tag: 'ApiService');
      return content;
    } on FormatException catch (e) {
      _logService.error('章节内容解析失败：${e.message}', error: e, tag: 'ApiService');
      throw ApiException('章节内容解析失败: ${e.message}', originalError: e);
    } catch (e, stackTrace) {
      _logService.error(
        '获取章节内容失败：$contentUrl',
        error: e,
        stackTrace: stackTrace,
        tag: 'ApiService',
      );
      if (e is ApiException) rethrow;
      throw ApiException('获取章节内容失败', originalError: e);
    }
  }

  // ==================== 私有辅助方法 ====================

  void _ensureSource(BookSource source) {
    if (source.bookSourceUrl.trim().isEmpty) {
      throw const ApiException('Source is required');
    }
  }

  String _buildSearchUrl(
    String baseUrl,
    String searchUrl,
    String keyword,
    int page,
  ) {
    final encodedKeyword = Uri.encodeComponent(keyword);
    final normalizedPage = page < 1 ? 1 : page;
    final url = searchUrl
        .replaceAll('{key}', encodedKeyword)
        .replaceAll('{keyword}', encodedKeyword)
        .replaceAll('{page}', normalizedPage.toString());
    return _buildFullUrl(baseUrl, url);
  }

  String _buildFullUrl(String baseUrl, String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final baseUri = Uri.parse(baseUrl);
    return baseUri.resolve(url).toString();
  }

  bool _isLikelyJson(http.Response response) {
    final contentType = response.headers['content-type'];
    if (contentType != null && contentType.contains('application/json')) {
      return true;
    }
    final trimmed = utf8.decode(response.bodyBytes).trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }

  /// 获取响应数据的摘要信息
  ///
  /// 避免在生产日志中打印完整的JSON响应体
  String _getResponseSummary(Map<String, dynamic> body) {
    final summary = <String, dynamic>{};

    if (body.containsKey('code')) summary['code'] = body['code'];
    if (body.containsKey('message')) summary['message'] = body['message'];
    if (body.containsKey('data')) {
      final data = body['data'];
      if (data is Map) {
        summary['data_type'] = 'Map';
        summary['data_keys'] = data.keys.toList();
        for (final key in data.keys) {
          final value = data[key];
          if (value is List) {
            summary['${key}_length'] = value.length;
          }
        }
      } else if (data is List) {
        summary['data_type'] = 'List';
        summary['data_length'] = data.length;
      } else {
        summary['data_type'] = data.runtimeType.toString();
      }
    }

    return summary.toString();
  }

  /// 带超时的 GET 请求，包含简单的重试机制和重定向跟随
  Future<http.Response> _getWithTimeout(Uri uri, {int retries = 2}) async {
    int attempts = 0;
    while (true) {
      try {
        final response = await _client.get(uri).timeout(_requestTimeout);

        if (response.statusCode == 301 || response.statusCode == 302) {
          final location = response.headers['location'];
          if (location != null) {
            final redirectUri = Uri.parse(location);
            if (!redirectUri.hasScheme) {
              return await _getWithTimeout(
                uri.replace(
                  path: redirectUri.path,
                  queryParameters: redirectUri.queryParameters.isEmpty
                      ? uri.queryParameters
                      : redirectUri.queryParameters,
                ),
                retries: retries,
              );
            }
            return await _getWithTimeout(redirectUri, retries: retries);
          }
        }

        return response;
      } catch (e) {
        attempts++;
        if (attempts > retries) {
          _logService.error('网络请求失败（重试超时）：$uri', error: e, tag: 'ApiService');
          throw ApiException('网络请求失败: $uri', originalError: e);
        }
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
  }

  /// 解码 HTTP 响应体
  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      return json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (e) {
      _logService.error('响应解析失败', error: e, tag: 'ApiService');
      throw ApiException('响应解析失败', originalError: e);
    }
  }

  /// 从搜索API响应中提取书籍列表
  ///
  /// 搜索API返回格式：
  /// ```json
  /// {
  ///   "code": 0,
  ///   "message": "SUCCESS",
  ///   "search_tabs": [
  ///     {
  ///       "tab_type": 3,
  ///       "data": [
  ///         {
  ///           "book_data": [
  ///             {
  ///               "book_id": "123456",
  ///               "book_name": "书名",
  ///               "author": "作者",
  ///               "thumb_url": "封面URL",
  ///               "abstract": "简介"
  ///             }
  ///           ]
  ///         }
  ///       ]
  ///     }
  ///   ]
  /// }
  /// ```
  List<Book> _extractSearchBooks(http.Response response) {
    if (response.statusCode != 200) {
      return [];
    }

    try {
      final body = _decodeResponse(response);

      if (body['code'] != 0) {
        return [];
      }

      final searchTabs = body['search_tabs'];
      if (searchTabs == null || searchTabs is! List) {
        return [];
      }

      for (final tab in searchTabs) {
        if (tab is! Map<String, dynamic>) continue;

        final tabData = tab['data'];
        if (tabData == null || tabData is! List) continue;

        for (final item in tabData) {
          if (item is! Map<String, dynamic>) continue;

          final bookData = item['book_data'];
          if (bookData == null || bookData is! List) continue;

          return bookData
              .whereType<Map<String, dynamic>>()
              .map((book) => Book.fromSearchData(book))
              .toList();
        }
      }

      return [];
    } catch (e) {
      _logService.warning('搜索结果解析失败 - $e', tag: 'ApiService');
      return [];
    }
  }

  /// 释放资源
  void dispose() {
    _client.close();
  }
}
