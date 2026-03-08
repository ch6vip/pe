import 'package:dio/dio.dart';
import 'package:reader_flutter/core/errors/exceptions.dart';
import 'package:reader_flutter/core/logger/logger.dart';
import 'package:reader_flutter/core/network/dio_client.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/models/book_source.dart';
import 'package:reader_flutter/models/chapter.dart';
import 'package:reader_flutter/models/chapter_content.dart';

/// API service using Dio
///
/// Enhanced version with interceptors, retry logic, and better error handling
class ApiServiceV2 {
  ApiServiceV2({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;
  final AppLogger _log = AppLogger();

  /// 搜索书籍
  Future<List<Book>> searchBooks(
    BookSource source,
    String keyword, {
    int page = 1,
  }) async {
    if (source.bookSourceUrl.isEmpty) {
      throw ValidationException('书源URL不能为空');
    }

    if (keyword.trim().isEmpty) {
      return [];
    }

    final searchUrl = source.searchUrl?.trim() ?? '';
    if (searchUrl.isEmpty) {
      throw ValidationException('搜索地址缺失');
    }

    final normalizedPage = page < 1 ? 1 : page;
    final requestUrl = _buildSearchUrl(
      source.bookSourceUrl,
      searchUrl,
      keyword.trim(),
      normalizedPage,
    );

    _log.i('搜索书籍：$keyword (第$normalizedPage页)');

    try {
      final response = await _client.get(requestUrl);

      if (response.statusCode != 200) {
        throw ServerException(
          '搜索书籍失败',
          statusCode: response.statusCode,
        );
      }

      final books = _extractSearchBooks(response.data);
      _log.i('搜索完成，找到${books.length}本书');
      return books;
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('搜索书籍失败', originalError: e);
    }
  }

  /// 获取书籍详情
  Future<Book> getBookDetail(BookSource source, String bookUrl) async {
    if (source.bookSourceUrl.isEmpty) {
      throw ValidationException('书源URL不能为空');
    }

    if (bookUrl.trim().isEmpty) {
      throw ValidationException('书籍详情地址不能为空');
    }

    final requestUrl = _buildFullUrl(source.bookSourceUrl, bookUrl.trim());
    _log.i('获取书籍详情：$requestUrl');

    try {
      final response = await _client.get(requestUrl);

      if (response.statusCode != 200) {
        throw ServerException(
          '获取书籍详情失败',
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final bookData = data['data'] ?? data;
        if (bookData is Map<String, dynamic>) {
          final book = Book.fromJson(bookData);
          _log.i('获取书籍详情成功：${book.name}');
          return book;
        }
      }

      throw ValidationException('书籍详情数据格式错误');
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('获取书籍详情失败', originalError: e);
    }
  }

  /// 获取章节列表
  Future<List<Chapter>> getChapters(BookSource source, String tocUrl) async {
    if (source.bookSourceUrl.isEmpty) {
      throw ValidationException('书源URL不能为空');
    }

    if (tocUrl.trim().isEmpty) {
      throw ValidationException('目录地址不能为空');
    }

    final requestUrl = _buildFullUrl(source.bookSourceUrl, tocUrl.trim());
    _log.i('获取章节列表：$requestUrl');

    try {
      final response = await _client.get(requestUrl);

      if (response.statusCode != 200) {
        throw ServerException(
          '获取章节列表失败',
          statusCode: response.statusCode,
        );
      }

      final body = response.data as Map<String, dynamic>;
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
        final summary = _getResponseSummary(body);
        _log.e('章节列表解析失败，响应结构: $summary');
        _log.d('完整响应数据(仅Debug模式): $body');
        throw ValidationException('章节列表数据格式错误');
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
            _log.w('章节${i + 1}数据格式错误，跳过: ${item.runtimeType}');
          }
        } catch (e) {
          failedCount++;
          _log.e('章节${i + 1}解析失败，跳过', error: e);
        }
      }

      if (chapters.isEmpty) {
        throw ValidationException('章节列表解析失败');
      }

      if (failedCount > 0) {
        _log.w('章节列表解析完成，成功${chapters.length}章，失败$failedCount章');
      } else {
        _log.i('获取章节列表成功，共${chapters.length}章');
      }

      return chapters;
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('获取章节列表失败', originalError: e);
    }
  }

  /// 获取章节内容
  Future<ChapterContent> getContent(
    BookSource source,
    String contentUrl,
  ) async {
    if (source.bookSourceUrl.isEmpty) {
      throw ValidationException('书源URL不能为空');
    }

    if (contentUrl.trim().isEmpty) {
      throw ValidationException('正文地址不能为空');
    }

    final requestUrl = _buildFullUrl(source.bookSourceUrl, contentUrl.trim());
    _log.i('获取章节内容：$requestUrl');

    try {
      final response = await _client.get(requestUrl);

      if (response.statusCode != 200) {
        throw ServerException(
          '获取章节内容失败',
          statusCode: response.statusCode,
        );
      }

      final content = ChapterContent.fromJson(response.data as Map<String, dynamic>);
      _log.i('获取章节内容成功');
      return content;
    } on FormatException catch (e) {
      _log.e('章节内容解析失败：${e.message}', error: e);
      throw ValidationException('章节内容解析失败: ${e.message}', originalError: e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('获取章节内容失败', originalError: e);
    }
  }

  /// 获取原始响应（用于调试）
  Future<Response> fetchRaw(String url) async {
    if (url.trim().isEmpty) {
      throw ValidationException('URL 不能为空');
    }

    try {
      return await _client.get(url.trim());
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('获取原始响应失败', originalError: e);
    }
  }

  // ==================== 辅助方法 ====================

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

  List<Book> _extractSearchBooks(Map<String, dynamic> body) {
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
  }

  /// 释放资源
  void dispose() {
    _client.dispose();
  }
}
