import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/models/chapter.dart';
import 'package:reader_flutter/models/chapter_content.dart';

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
    } catch (e) {
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
      return [];
    }

    final params = {
      'query': query.trim(),
      'offset': (page > 0 ? page - 1 : 0).toString(),
    };

    final uri = Uri.parse(_searchApiPath).replace(queryParameters: params);

    try {
      final response = await _getWithTimeout(uri);
      return _extractBooks(response);
    } catch (e) {
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
      throw const ApiException('书籍 ID 不能为空');
    }

    final uri = Uri.parse(
      _chapterListApiPath,
    ).replace(queryParameters: {'book_id': bookId});

    try {
      final response = await _getWithTimeout(uri);

      if (response.statusCode != 200) {
        throw ApiException('获取章节列表失败', statusCode: response.statusCode);
      }

      final body = _decodeResponse(response);
      final data = body['data'];

      if (data == null || data['item_list'] is! List) {
        throw const ApiException('章节列表数据格式错误');
      }

      final List<dynamic> itemList = data['item_list'] as List<dynamic>;
      return itemList
          .map((item) => Chapter.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
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
      throw const ApiException('章节 ID 不能为空');
    }

    final uri = Uri.parse(
      _chapterContentApiPath,
    ).replace(queryParameters: {'item_id': itemId});

    try {
      final response = await _getWithTimeout(uri);

      if (response.statusCode != 200) {
        throw ApiException('获取章节内容失败', statusCode: response.statusCode);
      }

      final body = _decodeResponse(response);
      return ChapterContent.fromJson(body);
    } on FormatException catch (e) {
      throw ApiException('章节内容解析失败: ${e.message}', originalError: e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('获取章节内容失败', originalError: e);
    }
  }

  // ==================== 私有辅助方法 ====================

  /// 安全的 GET 请求，失败时返回空响应而不是抛出异常
  Future<http.Response?> _safeGet(String url) async {
    try {
      return await _getWithTimeout(Uri.parse(url));
    } catch (e) {
      // 记录错误但不中断其他请求
      return null;
    }
  }

  /// 带超时的 GET 请求，包含简单的重试机制
  Future<http.Response> _getWithTimeout(Uri uri, {int retries = 2}) async {
    int attempts = 0;
    while (true) {
      try {
        return await _client.get(uri).timeout(_requestTimeout);
      } catch (e) {
        attempts++;
        if (attempts > retries) {
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
