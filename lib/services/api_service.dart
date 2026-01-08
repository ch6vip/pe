import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reader_flutter/models/book.dart';
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
/// 负责与后端 API 进行通信，提供书籍搜索、章节列表和章节内容的获取功能
class ApiService {
  // ==================== API 端点配置 ====================

  /// 快速更新 API（用于首页数据）
  static const String _fastUpdateApi =
      'https://api-lf.fanqiesdk.com/api/novel/channel/homepage/rank/rank_list/v2/?aid=13&limit=10&side_type=15&type=1';

  /// 排行榜 API
  static const String _topListApi =
      'https://fanqienovel.com/api/author/misc/top_book_list/v1/?limit=10&offset=0';

  /// 出版物 API
  static const String _publishedApi =
      'https://fanqienovel.com/api/node/publication/list?page_index=0&page_count=10';

  /// 新 API 基础地址
  static const String _newApiBase = 'http://api.ch6vip.com';

  /// 搜索 API
  static const String _searchApiPath = '$_newApiBase/search';

  /// 章节列表 API
  static const String _chapterListApiPath = '$_newApiBase/catalog';

  /// 章节内容 API
  static const String _chapterContentApiPath = '$_newApiBase/content';

  /// HTTP 请求超时时间
  static const Duration _requestTimeout = Duration(seconds: 15);

  /// HTTP 客户端（可注入用于测试）
  final http.Client _client;

  /// 创建 ApiService 实例
  ///
  /// [client] - 可选的 HTTP 客户端，用于依赖注入和测试
  final AppLogService _logService = AppLogService();

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // ==================== 公共方法 ====================

  /// 获取首页数据
  ///
  /// 并行请求多个排行榜数据，返回包含各榜单书籍列表的 Map
  ///
  /// Returns:
  /// - `featuredBook`: 推荐书籍（取自快速更新榜首位）
  /// - `fastUpdateList`: 快速更新榜单
  /// - `topList`: 巅峰榜单
  /// - `publishedList`: 出版榜单
  ///
  /// Throws:
  /// - [ApiException] 当所有请求都失败时
  Future<Map<String, List<Book>>> fetchHomePageData() async {
    try {
      _logService.info('开始获取首页数据', tag: 'ApiService');
      // 并行请求所有数据源
      final results = await Future.wait([
        _safeGet(_fastUpdateApi),
        _safeGet(_topListApi),
        _safeGet(_publishedApi),
      ], eagerError: false);

      final fastUpdateList = _extractBooks(results[0]);
      final topList = _extractBooks(results[1]);
      final publishedList = _extractBooks(results[2]);

      return {
        'featuredBook': fastUpdateList.isNotEmpty ? [fastUpdateList.first] : [],
        'fastUpdateList': fastUpdateList,
        'topList': topList,
        'publishedList': publishedList,
      };
    } catch (e, stackTrace) {
      _logService.error('获取首页数据失败',
          error: e, stackTrace: stackTrace, tag: 'ApiService');
      throw ApiException('获取首页数据失败', originalError: e);
    }
  }

  /// 搜索书籍
  ///
  /// [query] - 搜索关键词
  /// [page] - 页码（从 1 开始）
  ///
  /// Returns: 匹配的书籍列表
  ///
  /// Throws:
  /// - [ApiException] 当搜索请求失败时
  Future<List<Book>> searchBooks(String query, {int page = 1}) async {
    if (query.trim().isEmpty) {
      _logService.debug('搜索关键词为空，返回空结果', tag: 'ApiService');
      return [];
    }

    _logService.info('搜索书籍：$query (第$page页)', tag: 'ApiService');
    final params = {
      'query': query.trim(),
      'offset': (page > 0 ? page - 1 : 0).toString(),
    };

    final uri = Uri.parse(_searchApiPath).replace(queryParameters: params);

    try {
      final response = await _getWithTimeout(uri);
      final books = _extractSearchBooks(response);
      _logService.info('搜索完成，找到${books.length}本书', tag: 'ApiService');
      return books;
    } catch (e, stackTrace) {
      _logService.error('搜索书籍失败：$query',
          error: e, stackTrace: stackTrace, tag: 'ApiService');
      if (e is ApiException) rethrow;
      throw ApiException('搜索书籍失败', originalError: e);
    }
  }

  /// 获取书籍的章节列表
  ///
  /// [bookId] - 书籍 ID
  ///
  /// Returns: 章节列表
  ///
  /// Throws:
  /// - [ApiException] 当请求失败或数据格式错误时
  Future<List<Chapter>> getChapterList(String bookId) async {
    if (bookId.isEmpty) {
      _logService.error('书籍ID为空', tag: 'ApiService');
      throw const ApiException('书籍 ID 不能为空');
    }

    _logService.info('获取章节列表：$bookId', tag: 'ApiService');
    final uri = Uri.parse(
      _chapterListApiPath,
    ).replace(queryParameters: {'book_id': bookId});

    try {
      final response = await _getWithTimeout(uri);

      if (response.statusCode != 200) {
        _logService.error('获取章节列表失败，状态码：${response.statusCode}',
            tag: 'ApiService');
        throw ApiException('获取章节列表失败', statusCode: response.statusCode);
      }

      final body = _decodeResponse(response);
      dynamic data = body['data'];

      // 尝试从不同的字段中获取章节列表
      List<dynamic>? itemList;

      if (data is Map<String, dynamic>) {
        // 优先使用 item_data_list，因为日志显示这是实际使用的字段名
        itemList = (data['item_data_list'] ??
            data['item_list'] ??
            data['chapter_list'] ??
            data['chapters'] ??
            data['list']) as List<dynamic>?;
      } else if (data is List) {
        itemList = data;
      }

      // 如果 data 为空，尝试直接从 body 获取
      itemList ??= (body['item_data_list'] ??
          body['item_list'] ??
          body['chapter_list'] ??
          body['chapters'] ??
          body['list']) as List<dynamic>?;

      if (itemList == null) {
        // 优化日志：只打印响应摘要，避免刷屏
        final responseSummary = _getResponseSummary(body);
        _logService.error('章节列表解析失败，响应结构: $responseSummary', tag: 'ApiService');
        _logService.debug('完整响应数据(仅Debug模式): $body', tag: 'ApiService');
        throw const ApiException('章节列表数据格式错误');
      }

      // 增强的章节解析，支持单个章节解析失败时的容错处理
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
            _logService.warning('章节${i + 1}数据格式错误，跳过: ${item.runtimeType}',
                tag: 'ApiService');
          }
        } catch (e, stackTrace) {
          failedCount++;
          _logService.error('章节${i + 1}解析失败，跳过',
              error: e, stackTrace: stackTrace, tag: 'ApiService');
        }
      }

      if (chapters.isEmpty) {
        _logService.error('所有章节解析均失败', tag: 'ApiService');
        throw const ApiException('章节列表解析失败');
      }

      if (failedCount > 0) {
        _logService.warning('章节列表解析完成，成功${chapters.length}章，失败$failedCount章',
            tag: 'ApiService');
      } else {
        _logService.info('获取章节列表成功，共${chapters.length}章', tag: 'ApiService');
      }

      return chapters;
    } catch (e, stackTrace) {
      _logService.error('获取章节列表失败：$bookId',
          error: e, stackTrace: stackTrace, tag: 'ApiService');
      if (e is ApiException) rethrow;
      throw ApiException('获取章节列表失败', originalError: e);
    }
  }

  /// 获取章节内容
  ///
  /// [itemId] - 章节 ID
  ///
  /// Returns: 章节内容
  ///
  /// Throws:
  /// - [ApiException] 当请求失败或数据格式错误时
  Future<ChapterContent> getChapterContent(String itemId) async {
    if (itemId.isEmpty) {
      _logService.error('章节ID为空', tag: 'ApiService');
      throw const ApiException('章节 ID 不能为空');
    }

    _logService.info('获取章节内容：$itemId', tag: 'ApiService');
    final uri = Uri.parse(
      _chapterContentApiPath,
    ).replace(queryParameters: {'item_id': itemId});

    try {
      final response = await _getWithTimeout(uri);

      if (response.statusCode != 200) {
        _logService.error('获取章节内容失败，状态码：${response.statusCode}',
            tag: 'ApiService');
        throw ApiException('获取章节内容失败', statusCode: response.statusCode);
      }

      final body = _decodeResponse(response);
      final content = ChapterContent.fromJson(body);
      _logService.info('获取章节内容成功：$itemId', tag: 'ApiService');
      return content;
    } on FormatException catch (e) {
      _logService.error('章节内容解析失败：$itemId - ${e.message}',
          error: e, tag: 'ApiService');
      throw ApiException('章节内容解析失败: ${e.message}', originalError: e);
    } catch (e, stackTrace) {
      _logService.error('获取章节内容失败：$itemId',
          error: e, stackTrace: stackTrace, tag: 'ApiService');
      if (e is ApiException) rethrow;
      throw ApiException('获取章节内容失败', originalError: e);
    }
  }

  // ==================== 私有辅助方法 ====================

  /// 获取响应数据的摘要信息
  ///
  /// 避免在生产日志中打印完整的JSON响应体
  String _getResponseSummary(Map<String, dynamic> body) {
    final summary = <String, dynamic>{};

    // 记录关键字段
    if (body.containsKey('code')) summary['code'] = body['code'];
    if (body.containsKey('message')) summary['message'] = body['message'];
    if (body.containsKey('data')) {
      final data = body['data'];
      if (data is Map) {
        summary['data_type'] = 'Map';
        summary['data_keys'] = data.keys.toList();
        // 记录数组字段的长度
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

  /// 安全的 GET 请求，失败时返回空响应而不是抛出异常
  Future<http.Response?> _safeGet(String url) async {
    try {
      return await _getWithTimeout(Uri.parse(url));
    } catch (e) {
      // 记录错误但不中断其他请求
      _logService.warning('请求失败（忽略）：$url - $e', tag: 'ApiService');
      return null;
    }
  }

  /// 带超时的 GET 请求，包含简单的重试机制和重定向跟随
  Future<http.Response> _getWithTimeout(Uri uri, {int retries = 2}) async {
    int attempts = 0;
    while (true) {
      try {
        final response = await _client.get(uri).timeout(_requestTimeout);

        // 处理 301/302 重定向
        if (response.statusCode == 301 || response.statusCode == 302) {
          final location = response.headers['location'];
          if (location != null) {
            final redirectUri = Uri.parse(location);
            // 如果是相对路径，基于原 URI 构建
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
        // 简单的指数退避
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
      _logService.error('响应解析失败', error: e, tag: 'ApiService');
      throw ApiException('响应解析失败', originalError: e);
    }
  }

  /// 从 API 响应中提取书籍列表
  ///
  /// 支持多种响应格式：
  /// - `{ "data": { "result": [...] } }`
  /// - `{ "data": { "publication_list": [...] } }`
  /// - `{ "data": { "list": [...] } }`
  /// - `{ "data": { "book_list": [...] } }`
  /// - `{ "data": [...] }`
  /// - `{ "book_list": [...] }`
  /// - `{ "list": [...] }`
  List<Book> _extractBooks(http.Response? response) {
    if (response == null || response.statusCode != 200) {
      return [];
    }

    try {
      final body = _decodeResponse(response);
      final dataList = _findBookList(body);

      if (dataList is List) {
        return dataList
            .whereType<Map<String, dynamic>>()
            .map((item) => Book.fromJson(item))
            .toList();
      }

      return [];
    } catch (e) {
      _logService.warning('书籍列表解析失败 - $e', tag: 'ApiService');
      return [];
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

      // 检查响应状态
      if (body['code'] != 0) {
        return [];
      }

      // 获取 search_tabs
      final searchTabs = body['search_tabs'];
      if (searchTabs == null || searchTabs is! List) {
        return [];
      }

      // 遍历所有标签，找到包含书籍数据的标签
      for (final tab in searchTabs) {
        if (tab is! Map<String, dynamic>) continue;

        final tabData = tab['data'];
        if (tabData == null || tabData is! List) continue;

        // 遍历标签数据，找到包含 book_data 的项
        for (final item in tabData) {
          if (item is! Map<String, dynamic>) continue;

          final bookData = item['book_data'];
          if (bookData == null || bookData is! List) continue;

          // 提取书籍列表
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

  /// 从响应体中查找书籍列表
  dynamic _findBookList(Map<String, dynamic> body) {
    // 尝试从 data 字段中提取
    final data = body['data'];
    if (data != null) {
      if (data is Map<String, dynamic>) {
        // 按优先级尝试不同的列表字段
        return data['result'] ??
            data['publication_list'] ??
            data['list'] ??
            data['book_list'];
      }
      if (data is List) {
        return data;
      }
    }

    // 尝试从顶层提取
    return body['book_list'] ?? body['list'];
  }

  /// 释放资源
  void dispose() {
    _client.close();
  }
}
