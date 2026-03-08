import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/models/book_source.dart';
import 'package:reader_flutter/core/logger/logger.dart';
import 'package:reader_flutter/core/errors/exceptions.dart';

/// 统一的本地存储管理
///
/// 封装 SharedPreferences，提供类型安全的数据访问
class Preferences {
  static const String _bookshelfKey = 'bookshelf';
  static const String _readingProgressKey = 'reading_progress';
  static const String _settingsKey = 'settings';
  static const String _lastSyncTimeKey = 'last_sync_time';

  static final AppLogger _log = AppLogger();

  /// 获取 SharedPreferences 实例
  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // ==================== 书架管理 ====================

  /// 保存书架书籍列表
  static Future<void> setBookshelf(List<Book> books) async {
    try {
      final prefs = await _prefs;
      final json = jsonEncode(books.map((b) => b.toJson()).toList());
      await prefs.setString(_bookshelfKey, json);
      _log.d('书架已保存，共 ${books.length} 本书');
    } catch (e, stack) {
      _log.e('保存书架失败', error: e, stackTrace: stack);
      throw StorageException('保存书架失败', originalError: e);
    }
  }

  /// 获取书架书籍列表
  static Future<List<Book>> getBookshelf() async {
    try {
      final prefs = await _prefs;
      final json = prefs.getString(_bookshelfKey);
      if (json == null || json.isEmpty) {
        return [];
      }
      final List<dynamic> list = jsonDecode(json);
      return list
          .whereType<Map<String, dynamic>>()
          .map((item) => Book.fromJson(item))
          .toList();
    } on FormatException catch (e) {
      _log.e('书架数据解析失败', error: e);
      throw ParsingException('书架数据格式错误', originalError: e);
    } catch (e) {
      _log.e('获取书架失败', error: e);
      throw StorageException('获取书架失败', originalError: e);
    }
  }

  /// 添加书籍到书架
  static Future<void> addBookToBookshelf(Book book) async {
    final books = await getBookshelf();
    // 避免重复（基于 ID）
    if (books.any((b) => b.id == book.id)) {
      _log.w('书籍已存在于书架：${book.name}');
      return;
    }
    books.insert(0, book); // 添加到开头
    await setBookshelf(books);
    _log.i('书籍已添加到书架：${book.name}');
  }

  /// 从书架移除书籍
  static Future<void> removeBookFromBookshelf(String bookId) async {
    final books = await getBookshelf();
    final initialLength = books.length;
    books.removeWhere((b) => b.id == bookId);
    if (books.length < initialLength) {
      await setBookshelf(books);
      _log.i('书籍已从书架移除：$bookId');
    }
  }

  /// 更新书架中的书籍信息
  static Future<void> updateBookInBookshelf(Book updatedBook) async {
    final books = await getBookshelf();
    final index = books.indexWhere((b) => b.id == updatedBook.id);
    if (index >= 0) {
      books[index] = updatedBook;
      await setBookshelf(books);
      _log.d('书架书籍已更新：${updatedBook.name}');
    }
  }

  // ==================== 阅读进度 ====================

  /// 保存阅读进度
  static Future<void> setReadingProgress(
    String bookId,
    String chapterTitle,
    int position,
  ) async {
    try {
      final prefs = await _prefs;
      final progress = {
        'bookId': bookId,
        'chapterTitle': chapterTitle,
        'position': position,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(
        '$_readingProgressKey.$bookId',
        jsonEncode(progress),
      );
      _log.v('阅读进度已保存：$bookId - $chapterTitle');
    } catch (e) {
      _log.e('保存阅读进度失败', error: e);
    }
  }

  /// 获取阅读进度
  static Future<Map<String, dynamic>?> getReadingProgress(String bookId) async {
    try {
      final prefs = await _prefs;
      final json = prefs.getString('$_readingProgressKey.$bookId');
      if (json == null) return null;
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      _log.e('获取阅读进度失败', error: e);
      return null;
    }
  }

  // ==================== 设置管理 ====================

  /// 保存设置
  static Future<void> setSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_settingsKey, jsonEncode(settings));
      _log.d('设置已保存');
    } catch (e) {
      _log.e('保存设置失败', error: e);
    }
  }

  /// 获取设置
  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final prefs = await _prefs;
      final json = prefs.getString(_settingsKey);
      if (json == null) {
        return const {
          'fontSize': 16.0,
          'lineHeight': 1.6,
          'theme': 'light',
        };
      }
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      _log.e('获取设置失败', error: e);
      return const {
        'fontSize': 16.0,
        'lineHeight': 1.6,
        'theme': 'light',
      };
    }
  }

  // ==================== 书源管理（已由 SourceManagerService 处理，这里仅作示例）====================

  /// 保存书源列表
  static Future<void> setSources(List<BookSource> sources) async {
    try {
      final prefs = await _prefs;
      final json = jsonEncode(sources.map((s) => s.toJson()).toList());
      await prefs.setString('book_sources', json);
      _log.d('书源已保存，共 ${sources.length} 个');
    } catch (e) {
      _log.e('保存书源失败', error: e);
      throw StorageException('保存书源失败', originalError: e);
    }
  }

  /// 获取书源列表
  static Future<List<BookSource>> getSources() async {
    try {
      final prefs = await _prefs;
      final json = prefs.getString('book_sources');
      if (json == null) {
        return [BookSource.createDemoSource()];
      }
      final List<dynamic> list = jsonDecode(json);
      return list
          .whereType<Map<String, dynamic>>()
          .map((item) => BookSource.fromJson(item))
          .toList();
    } catch (e) {
      _log.e('获取书源失败', error: e);
      return [BookSource.createDemoSource()];
    }
  }

  /// 获取书源最后更新时间（时间戳）
  static Future<int?> getSourcesLastUpdateTime() async {
    final prefs = await _prefs;
    return prefs.getInt(_lastSyncTimeKey);
  }

  /// 设置书源最后更新时间
  static Future<void> setSourcesLastUpdateTime(int timestamp) async {
    final prefs = await _prefs;
    await prefs.setInt(_lastSyncTimeKey, timestamp);
  }

  // ==================== 工具方法 ====================

  /// 清除所有数据
  static Future<void> clearAll() async {
    try {
      final prefs = await _prefs;
      await prefs.clear();
      _log.i('所有本地数据已清除');
    } catch (e) {
      _log.e('清除数据失败', error: e);
    }
  }

  /// 获取最后同步时间
  static Future<int?> getLastSyncTime() async {
    final prefs = await _prefs;
    return prefs.getInt(_lastSyncTimeKey);
  }

  /// 设置最后同步时间
  static Future<void> setLastSyncTime(int timestamp) async {
    final prefs = await _prefs;
    await prefs.setInt(_lastSyncTimeKey, timestamp);
  }

  /// 检查特定键是否存在
  static Future<bool> containsKey(String key) async {
    final prefs = await _prefs;
    return prefs.containsKey(key);
  }

  /// 移除特定键
  static Future<void> removeKey(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }
}
