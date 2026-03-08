import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reader_flutter/core/errors/exceptions.dart';
import 'package:reader_flutter/core/logger/logger.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/models/book_source.dart';
import 'package:reader_flutter/models/chapter.dart';
import 'package:reader_flutter/models/chapter_content.dart';

/// API service class
///
/// Handles communication with backend API, providing book search, details, chapter list and content retrieval
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// HTTP request timeout
  static const Duration _requestTimeout = Duration(seconds: 15);

  /// HTTP client (injectable for testing)
  final http.Client _client;

  /// Logger
  final AppLogger _log = AppLogger();

  /// Fetch raw response (for debugging and rule verification)
  Future<http.Response> fetchRaw(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw ValidationException('URL cannot be empty');
    }
    try {
      return await _getWithTimeout(Uri.parse(trimmed));
    } catch (e) {
      _log.e('Failed to fetch raw response: $trimmed - $e');
      if (e is AppException) rethrow;
      throw NetworkException('Failed to fetch raw response', error: e);
    }
  }

  /// Search books
  ///
  /// [source] - book source
  /// [keyword] - search keyword
  /// [page] - page number (starting from 1)
  ///
  /// Returns: list of books
  Future<List<Book>> searchBooks(BookSource source, String keyword, {int page = 1}) async {
    if (source.bookSourceUrl.trim().isEmpty) {
      _log.e('Source URL not configured');
      throw ValidationException('Source URL is required');
    }

    final searchUrl = source.searchUrl?.trim() ?? '';
    if (searchUrl.isEmpty) {
      _log.e('Search URL not configured');
      throw ValidationException('Search URL is missing');
    }

    final normalizedPage = page < 1 ? 1 : page;
    final requestUrl = _buildSearchUrl(
      source.bookSourceUrl,
      searchUrl,
      keyword.trim(),
      normalizedPage,
    );

    _log.i('Searching books: $keyword (page $normalizedPage)');

    try {
      final response = await _getWithTimeout(Uri.parse(requestUrl));

      if (response.statusCode != 200) {
        _log.e('Search books failed, status code: ${response.statusCode}');
        throw ServerException(
          'Search books failed',
          statusCode: response.statusCode,
        );
      }

      if (!_isLikelyJson(response)) {
        throw ValidationException('Search parsing not integrated, please configure JSON interface or integrate parsing engine');
      }

      final books = _extractSearchBooks(response);
      _log.i('Search completed, found ${books.length} books');
      return books;
    } catch (e) {
      if (e is AppException) rethrow;
      _log.e('Search books failed: $keyword - $e');
      throw NetworkException('Search books failed', error: e);
    }
  }

  /// Get book detail
  Future<Book> getBookDetail(BookSource source, String bookUrl) async {
    if (source.bookSourceUrl.trim().isEmpty) {
      throw ValidationException('Book source URL is required');
    }

    if (bookUrl.trim().isEmpty) {
      _log.e('Book detail URL is empty');
      throw ValidationException('Book detail URL cannot be empty');
    }

    final requestUrl = _buildFullUrl(source.bookSourceUrl, bookUrl.trim());
    _log.i('Getting book detail: $requestUrl');

    try {
      final response = await _getWithTimeout(Uri.parse(requestUrl));

      if (response.statusCode != 200) {
        _log.e('Get book detail failed, status code: ${response.statusCode}');
        throw ServerException(
          'Get book detail failed',
          statusCode: response.statusCode,
        );
      }

      if (!_isLikelyJson(response)) {
        throw ValidationException('Book detail parsing not integrated, please configure JSON interface or integrate parsing engine');
      }

      final body = _decodeResponse(response);
      final data = body['data'] ?? body;
      if (data is Map<String, dynamic>) {
        final book = Book.fromJson(data);
        _log.i('Got book detail successfully: ${book.name}');
        return book;
      }

      throw ValidationException('Book detail data format error');
    } catch (e) {
      if (e is AppException) rethrow;
      _log.e('Get book detail failed: $bookUrl - $e');
      throw NetworkException('Get book detail failed', error: e);
    }
  }

  /// Get chapter list (TOC)
  Future<List<Chapter>> getChapters(BookSource source, String tocUrl) async {
    if (source.bookSourceUrl.trim().isEmpty) {
      throw ValidationException('Book source URL is required');
    }

    if (tocUrl.trim().isEmpty) {
      _log.e('TOC URL is empty');
      throw ValidationException('TOC URL cannot be empty');
    }

    final requestUrl = _buildFullUrl(source.bookSourceUrl, tocUrl.trim());
    _log.i('Getting chapter list: $requestUrl');

    try {
      final response = await _getWithTimeout(Uri.parse(requestUrl));

      if (response.statusCode != 200) {
        _log.e('Get chapter list failed, status code: ${response.statusCode}');
        throw ServerException(
          'Get chapter list failed',
          statusCode: response.statusCode,
        );
      }

      if (!_isLikelyJson(response)) {
        throw ValidationException('Chapter list parsing not integrated, please configure JSON interface or integrate parsing engine');
      }

      final body = _decodeResponse(response);
      final data = body['data'] ?? body;

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
        _log.e('Chapter list parsing failed, response structure: $responseSummary');
        _log.d('Full response data (debug only): $body');
        throw ValidationException('Chapter list data format error');
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
            _log.w('Chapter ${i+1} data format error, skipping: ${item.runtimeType}');
          }
        } catch (e) {
          failedCount++;
          _log.e('Chapter ${i+1} parsing failed, skipping - $e');
        }
      }

      if (chapters.isEmpty) {
        throw ValidationException('Chapter list parsing failed');
      }

      if (failedCount > 0) {
        _log.w('Chapter list parsing completed: ${chapters.length} success, $failedCount failed');
      } else {
        _log.i('Got chapter list successfully: ${chapters.length} chapters');
      }

      return chapters;
    } catch (e) {
      if (e is AppException) rethrow;
      _log.e('Get chapter list failed: $tocUrl - $e');
      throw NetworkException('Get chapter list failed', error: e);
    }
  }

  /// Get chapter content
  Future<ChapterContent> getContent(BookSource source, String contentUrl) async {
    if (source.bookSourceUrl.trim().isEmpty) {
      throw ValidationException('Book source URL is required');
    }

    if (contentUrl.trim().isEmpty) {
      _log.e('Content URL is empty');
      throw ValidationException('Content URL cannot be empty');
    }

    final requestUrl = _buildFullUrl(source.bookSourceUrl, contentUrl.trim());
    _log.i('Getting chapter content: $requestUrl');

    try {
      final response = await _getWithTimeout(Uri.parse(requestUrl));

      if (response.statusCode != 200) {
        _log.e('Get chapter content failed, status code: ${response.statusCode}');
        throw ServerException(
          'Get chapter content failed',
          statusCode: response.statusCode,
        );
      }

      if (!_isLikelyJson(response)) {
        throw ValidationException('Chapter content parsing not integrated, please configure JSON interface or integrate parsing engine');
      }

      final body = _decodeResponse(response);
      final content = ChapterContent.fromJson(body);
      _log.i('Got chapter content successfully');
      return content;
    } on FormatException catch (e) {
      _log.e('Chapter content parsing failed: ${e.message}');
      throw ValidationException('Chapter content parsing failed: ${e.message}', error: e);
    } catch (e) {
      if (e is AppException) rethrow;
      _log.e('Get chapter content failed: $contentUrl - $e');
      throw NetworkException('Get chapter content failed', error: e);
    }
  }

  // ==================== Private helper methods ====================

  void _ensureSource(BookSource source) {
    if (source.bookSourceUrl.trim().isEmpty) {
      throw ValidationException('Book source URL is required');
    }
  }

  Future<http.Response> _getWithTimeout(Uri uri, {int? timeout}) async {
    int attempts = 0;
    final retries = 3;
    final actualTimeout = timeout ?? _requestTimeout.inMilliseconds;

    while (attempts < retries) {
      attempts++;
      try {
        return await _client.get(uri).timeout(actualTimeout);
      } catch (e) {
        if (attempts >= retries) {
          _log.e('Network request failed (retries exhausted): $uri - $e');
          throw NetworkException('Network request failed: $uri', error: e);
        }
        // Exponential backoff
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
    // Should not reach here
    throw NetworkException('Network request failed: $uri');
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      _log.e('Response parsing failed: $e');
      throw ParsingException('Response parsing failed', error: e);
    }
  }

  bool _isLikelyJson(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    return contentType.contains('application/json') || response.body.trim().startsWith('{') || response.body.trim().startsWith('[');
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

  String _buildSearchUrl(String baseUrl, String searchUrl, String keyword, int page) {
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

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
