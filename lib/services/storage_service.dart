import 'dart:convert';
import 'package:reader_flutter/models/book.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 存储异常
///
/// 用于封装本地存储操作中的错误信息
class StorageException implements Exception {
  /// 错误消息
  final String message;

  /// 原始异常（如果有）
  final Object? originalError;

  const StorageException(this.message, {this.originalError});

  @override
  String toString() => 'StorageException: $message';
}

/// 排序方式枚举
enum SortOrder {
  /// 按最近阅读时间排序
  byReadTime('byReadTime'),

  /// 按添加时间排序
  byAddTime('byAddTime');

  /// 存储使用的字符串值
  final String value;

  const SortOrder(this.value);

  /// 从字符串解析排序方式
  static SortOrder fromString(String? value) {
    return SortOrder.values.firstWhere(
      (order) => order.value == value,
      orElse: () => SortOrder.byReadTime,
    );
  }
}

/// 本地存储服务
///
/// 负责管理书架数据和用户偏好设置的本地持久化存储
class StorageService {
  // ==================== 存储键常量 ====================

  /// 书架数据存储键
  static const String _bookshelfKey = 'bookshelf';

  /// 排序方式存储键
  static const String _sortOrderKey = 'sortOrder';

  /// 阅读设置存储键
  static const String _readingSettingsKey = 'readingSettings';

  /// SharedPreferences 实例缓存
  SharedPreferences? _prefsCache;

  /// 获取 SharedPreferences 实例（带缓存）
  Future<SharedPreferences> get _prefs async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!;
  }

  // ==================== 书架管理 ====================

  /// 获取书架中的所有书籍
  ///
  /// Returns: 书籍列表，如果书架为空则返回空列表
  ///
  /// Throws:
  /// - [StorageException] 当读取或解析数据失败时
  Future<List<Book>> getBookshelf() async {
    try {
      final prefs = await _prefs;
      final List<String>? bookshelfJson = prefs.getStringList(_bookshelfKey);

      if (bookshelfJson == null || bookshelfJson.isEmpty) {
        return [];
      }

      return bookshelfJson
          .map((bookJson) {
            try {
              return Book.fromJson(
                  json.decode(bookJson) as Map<String, dynamic>);
            } catch (e) {
              // 跳过解析失败的书籍，保持健壮性
              return null;
            }
          })
          .whereType<Book>()
          .toList();
    } catch (e) {
      throw StorageException('读取书架数据失败', originalError: e);
    }
  }

  /// 保存书架数据
  ///
  /// [books] - 要保存的书籍列表
  ///
  /// Throws:
  /// - [StorageException] 当保存数据失败时
  Future<void> saveBookshelf(List<Book> books) async {
    try {
      final prefs = await _prefs;
      final List<String> bookshelfJson =
          books.map((book) => json.encode(book.toJson())).toList();
      await prefs.setStringList(_bookshelfKey, bookshelfJson);
    } catch (e) {
      throw StorageException('保存书架数据失败', originalError: e);
    }
  }

  /// 添加书籍到书架
  ///
  /// [book] - 要添加的书籍
  ///
  /// 如果书籍已存在（根据 ID 判断），则不会重复添加
  ///
  /// Returns: 是否成功添加（false 表示书籍已存在）
  ///
  /// Throws:
  /// - [StorageException] 当存储操作失败时
  Future<bool> addBookToShelf(Book book) async {
    try {
      final List<Book> bookshelf = await getBookshelf();

      // 检查是否已存在
      if (bookshelf.any((b) => b.id == book.id)) {
        return false;
      }

      // 创建带有添加时间的新书籍
      final bookToAdd = book.copyWith(
        addTime: DateTime.now().millisecondsSinceEpoch,
      );

      bookshelf.add(bookToAdd);
      await saveBookshelf(bookshelf);
      return true;
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('添加书籍失败', originalError: e);
    }
  }

  /// 从书架移除书籍
  ///
  /// [bookId] - 要移除的书籍 ID
  ///
  /// Returns: 是否成功移除（false 表示书籍不存在）
  ///
  /// Throws:
  /// - [StorageException] 当存储操作失败时
  Future<bool> removeBookFromShelf(String bookId) async {
    if (bookId.isEmpty) {
      return false;
    }

    try {
      final List<Book> bookshelf = await getBookshelf();
      final originalLength = bookshelf.length;

      bookshelf.removeWhere((book) => book.id == bookId);

      if (bookshelf.length == originalLength) {
        return false; // 书籍不存在
      }

      await saveBookshelf(bookshelf);
      return true;
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('移除书籍失败', originalError: e);
    }
  }

  /// 检查书籍是否在书架中
  ///
  /// [bookId] - 书籍 ID
  ///
  /// Returns: 书籍是否存在于书架中
  Future<bool> isBookInShelf(String bookId) async {
    if (bookId.isEmpty) {
      return false;
    }

    try {
      final bookshelf = await getBookshelf();
      return bookshelf.any((book) => book.id == bookId);
    } catch (e) {
      return false;
    }
  }

  /// 更新书架中的书籍信息
  ///
  /// [updatedBook] - 更新后的书籍
  ///
  /// Returns: 是否成功更新（false 表示书籍不存在）
  Future<bool> updateBookInShelf(Book updatedBook) async {
    try {
      final List<Book> bookshelf = await getBookshelf();
      final index = bookshelf.indexWhere((b) => b.id == updatedBook.id);

      if (index == -1) {
        return false;
      }

      bookshelf[index] = updatedBook;
      await saveBookshelf(bookshelf);
      return true;
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('更新书籍失败', originalError: e);
    }
  }

  /// 更新书籍的阅读进度
  ///
  /// [bookId] - 书籍 ID
  /// [chapterTitle] - 当前章节标题
  ///
  /// Returns: 是否成功更新
  Future<bool> updateReadingProgress(String bookId, String chapterTitle) async {
    try {
      final List<Book> bookshelf = await getBookshelf();
      final index = bookshelf.indexWhere((b) => b.id == bookId);

      if (index == -1) {
        return false;
      }

      final updatedBook = bookshelf[index].copyWith(
        lastReadTime: DateTime.now().millisecondsSinceEpoch,
        lastReadChapterTitle: chapterTitle,
      );

      bookshelf[index] = updatedBook;
      await saveBookshelf(bookshelf);
      return true;
    } catch (e) {
      // 阅读进度更新失败不应中断阅读体验
      return false;
    }
  }

  // ==================== 用户偏好设置 ====================

  /// 获取排序方式
  ///
  /// Returns: 当前的排序方式，默认为按阅读时间排序
  Future<SortOrder> getSortOrder() async {
    try {
      final prefs = await _prefs;
      final value = prefs.getString(_sortOrderKey);
      return SortOrder.fromString(value);
    } catch (e) {
      return SortOrder.byReadTime;
    }
  }

  /// 获取排序方式（字符串格式，兼容旧代码）
  Future<String> getSortOrderString() async {
    final order = await getSortOrder();
    return order.value;
  }

  /// 保存排序方式
  ///
  /// [order] - 排序方式
  Future<void> saveSortOrder(SortOrder order) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_sortOrderKey, order.value);
    } catch (e) {
      throw StorageException('保存排序设置失败', originalError: e);
    }
  }

  /// 保存排序方式（字符串格式，兼容旧代码）
  Future<void> saveSortOrderString(String order) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_sortOrderKey, order);
    } catch (e) {
      throw StorageException('保存排序设置失败', originalError: e);
    }
  }

  // ==================== 阅读设置 ====================

  /// 获取阅读设置
  ///
  /// Returns: 阅读设置 Map，包含字号、行距、主题等
  Future<Map<String, dynamic>> getReadingSettings() async {
    try {
      final prefs = await _prefs;
      final settingsJson = prefs.getString(_readingSettingsKey);

      if (settingsJson == null || settingsJson.isEmpty) {
        return _defaultReadingSettings;
      }

      return json.decode(settingsJson) as Map<String, dynamic>;
    } catch (e) {
      return _defaultReadingSettings;
    }
  }

  /// 保存阅读设置
  ///
  /// [settings] - 阅读设置 Map
  Future<void> saveReadingSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_readingSettingsKey, json.encode(settings));
    } catch (e) {
      throw StorageException('保存阅读设置失败', originalError: e);
    }
  }

  /// 默认阅读设置
  static const Map<String, dynamic> _defaultReadingSettings = {
    'fontSize': 18.0,
    'lineHeight': 1.8,
    'themeIndex': 0,
  };

  // ==================== 工具方法 ====================

  /// 清除所有数据（用于调试/重置）
  Future<void> clearAll() async {
    try {
      final prefs = await _prefs;
      await prefs.clear();
      _prefsCache = null;
    } catch (e) {
      throw StorageException('清除数据失败', originalError: e);
    }
  }
}
