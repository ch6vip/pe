import 'package:flutter/material.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/models/book_source.dart';
import 'package:reader_flutter/models/chapter.dart';
import 'package:reader_flutter/models/chapter_content.dart';
import 'package:reader_flutter/services/api_service.dart';
import 'package:reader_flutter/services/storage_service.dart';
import 'package:reader_flutter/services/app_log_service.dart';
import 'package:reader_flutter/services/source_manager_service.dart';

/// 阅读器控制器
///
/// 负责管理阅读器的业务逻辑，包括：
/// - 章节列表加载
/// - 章节内容加载（支持缓存优先）
/// - 预加载下一章
/// - 阅读进度管理
class ReaderController extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;
  final AppLogService _logService;
  final SourceManagerService _sourceManagerService;
  final Book book;

  ReaderController({
    required this.book,
    required SourceManagerService sourceManagerService,
    ApiService? apiService,
    StorageService? storageService,
    AppLogService? logService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService(),
        _logService = logService ?? AppLogService(),
        _sourceManagerService = sourceManagerService;

  // ==================== 状态变量 ====================

  /// 章节列表
  List<Chapter> _chapters = [];
  List<Chapter> get chapters => _chapters;

  /// 当前章节内容
  ChapterContent? _currentContent;
  ChapterContent? get currentContent => _currentContent;

  /// 当前章节索引
  int _currentChapterIndex = 0;
  int get currentChapterIndex => _currentChapterIndex;

  /// 是否正在加载
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// 错误信息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ==================== 核心逻辑 ====================

  /// 初始化控制器
  Future<void> initialize() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _logService.info('开始初始化阅读器', tag: 'ReaderController');
      _logService.debug(
        '书籍ID: ${book.id}, 书名: ${book.name}',
        tag: 'ReaderController',
      );

      final source = _resolveBookSource();
      if (source == null) {
        _errorMessage = '书源已失效';
        _logService.error(
          '未找到书源：${_getBookSourceKey()}',
          tag: 'ReaderController',
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 1. 加载章节列表
      try {
        final tocUrl = _getBookTocUrl();
        if (tocUrl.isEmpty) {
          _errorMessage = '书籍目录地址缺失，无法加载章节';
          _logService.error('目录地址为空：${book.id}', tag: 'ReaderController');
          _isLoading = false;
          notifyListeners();
          return;
        }

        _chapters = await _apiService.getChapters(source, tocUrl);
        _logService.info(
          '成功加载章节列表，共${_chapters.length}章',
          tag: 'ReaderController',
        );
      } catch (e, stackTrace) {
        _logService.error(
          '加载章节列表失败',
          error: e,
          stackTrace: stackTrace,
          tag: 'ReaderController',
        );

        // 根据错误类型提供更友好的错误信息
        if (e is ApiException) {
          _errorMessage = _getApiErrorMessage(e);
        } else {
          _errorMessage = '加载章节列表失败，请检查网络连接后重试';
        }

        _isLoading = false;
        notifyListeners();
        return;
      }

      if (_chapters.isEmpty) {
        _errorMessage = '该书籍暂无章节内容';
        _logService.error('章节列表为空', tag: 'ReaderController');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. 查找上次阅读位置
      final initialIndex = await _findLastReadChapterIndex();
      _currentChapterIndex = initialIndex;
      _logService.info(
        '找到上次阅读位置：第${initialIndex + 1}章',
        tag: 'ReaderController',
      );

      // 3. 加载当前章节内容
      await loadChapterContent(initialIndex);
      _logService.info('阅读器初始化完成', tag: 'ReaderController');
    } catch (e, stackTrace) {
      _errorMessage = '初始化失败，请重试';
      _logService.error(
        '阅读器初始化失败',
        error: e,
        stackTrace: stackTrace,
        tag: 'ReaderController',
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 查找上次阅读的章节索引
  Future<int> _findLastReadChapterIndex() async {
    try {
      final bookshelf = await _storageService.getBookshelf();
      final savedBook = bookshelf.firstWhere(
        (b) => b.id == book.id,
        orElse: () => book,
      );

      if (savedBook.lastReadChapterTitle != null) {
        final savedIndex = _chapters.indexWhere(
          (c) => c.title == savedBook.lastReadChapterTitle,
        );
        if (savedIndex != -1) {
          return savedIndex;
        }
      }
    } catch (e) {
      // 忽略错误，默认从第一章开始
    }
    return 0;
  }

  /// 加载指定章节内容
  ///
  /// 策略：缓存优先 -> 网络请求 -> 预加载下一章
  Future<void> loadChapterContent(int index) async {
    if (index < 0 || index >= _chapters.length) return;

    final chapter = _chapters[index];
    _logService.info('开始加载章节：${chapter.title}', tag: 'ReaderController');

    _isLoading = true;
    _errorMessage = null;
    _currentChapterIndex = index;
    notifyListeners();

    final source = _resolveBookSource();
    if (source == null) {
      _errorMessage = '书源已失效';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      ChapterContent? content;

      // 1. 尝试从缓存获取
      content = await _storageService.getChapterContent(chapter.itemId);

      if (content != null) {
        _currentContent = content;
        _logService.debug('从缓存加载章节内容', tag: 'ReaderController');
        _isLoading = false;
        notifyListeners();

        // 即使有缓存，也可以在后台静默更新（可选，视需求而定）
        // 这里我们选择信任缓存，仅在缓存不存在时请求网络
      } else {
        // 2. 缓存未命中，请求网络
        _logService.debug('缓存未命中，从网络请求', tag: 'ReaderController');

        try {
          content = await _apiService.getContent(source, chapter.itemId);
          _currentContent = content;

          // 保存到缓存
          await _storageService.saveChapterContent(chapter.itemId, content);
          _logService.debug('章节内容已保存到缓存', tag: 'ReaderController');
        } catch (e, stackTrace) {
          _logService.error(
            '从网络加载章节失败：${chapter.title}',
            error: e,
            stackTrace: stackTrace,
            tag: 'ReaderController',
          );

          // 根据错误类型提供更友好的错误信息
          if (e is ApiException) {
            _errorMessage = _getApiErrorMessage(e);
          } else {
            _errorMessage = '加载章节失败，请检查网络连接';
          }

          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      _isLoading = false;
      notifyListeners();

      // 3. 保存阅读进度
      await _saveProgress(index);

      // 4. 预加载下一章
      _preloadNextChapter(index);
      _logService.info('章节加载完成：${chapter.title}', tag: 'ReaderController');
    } catch (e, stackTrace) {
      _errorMessage = '加载章节时发生未知错误';
      _logService.error(
        '加载章节失败：${chapter.title}',
        error: e,
        stackTrace: stackTrace,
        tag: 'ReaderController',
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 预加载下一章
  Future<void> _preloadNextChapter(int currentIndex) async {
    if (currentIndex >= _chapters.length - 1) return;

    final nextChapter = _chapters[currentIndex + 1];

    // 检查缓存是否存在，避免重复请求
    final hasCache = await _storageService.hasChapterContent(
      nextChapter.itemId,
    );
    if (hasCache) return;

    final source = _resolveBookSource();
    if (source == null) return;

    try {
      // 延迟一点执行，避免抢占当前章节渲染资源
      await Future.delayed(const Duration(seconds: 1));

      final content = await _apiService.getContent(source, nextChapter.itemId);
      await _storageService.saveChapterContent(nextChapter.itemId, content);
      _logService.debug('预加载成功: ${nextChapter.title}', tag: 'ReaderController');
    } catch (e) {
      // 预加载失败不干扰用户，仅记录日志
      _logService.warning(
        '预加载失败: ${nextChapter.title}: $e',
        tag: 'ReaderController',
      );
    }
  }

  /// 保存阅读进度
  Future<void> _saveProgress(int chapterIndex) async {
    try {
      final chapterTitle = _chapters[chapterIndex].title;
      await _storageService.updateReadingProgress(book.id, chapterTitle);
      _logService.debug('阅读进度已保存：$chapterTitle', tag: 'ReaderController');
    } catch (e) {
      // 保存进度失败不应影响阅读体验
      _logService.warning('保存阅读进度失败: $e', tag: 'ReaderController');
    }
  }

  /// 前往上一章
  void goToPreviousChapter() {
    if (_currentChapterIndex > 0) {
      _logService.debug('用户点击上一章', tag: 'ReaderController');
      loadChapterContent(_currentChapterIndex - 1);
    } else {
      _logService.debug('已经是第一章，无法前往上一章', tag: 'ReaderController');
    }
  }

  /// 前往下一章
  void goToNextChapter() {
    if (_currentChapterIndex < _chapters.length - 1) {
      _logService.debug('用户点击下一章', tag: 'ReaderController');
      loadChapterContent(_currentChapterIndex + 1);
    } else {
      _logService.debug('已经是最后一章，无法前往下一章', tag: 'ReaderController');
    }
  }

  /// 是否有上一章
  bool get hasPreviousChapter => _currentChapterIndex > 0;

  /// 是否有下一章
  bool get hasNextChapter => _currentChapterIndex < _chapters.length - 1;

  /// 重试加载
  Future<void> retry() async {
    _logService.info('用户点击重试', tag: 'ReaderController');
    await initialize();
  }

  BookSource? _resolveBookSource() {
    final sourceUrl = _getBookSourceKey();
    if (sourceUrl.isEmpty) return null;
    return _sourceManagerService.getSourceByUrl(sourceUrl);
  }

  String _getBookSourceKey() {
    final sourceUrl = book.bookSourceUrl?.trim();
    if (sourceUrl == null || sourceUrl.isEmpty) {
      return '';
    }
    return sourceUrl;
  }

  String _getBookTocUrl() {
    final tocUrl = book.efficientTocUrl.trim();
    if (tocUrl.isEmpty) {
      return '';
    }
    return tocUrl;
  }

  /// 获取用户友好的 API 错误信息
  String _getApiErrorMessage(ApiException e) {
    final message = e.message.toLowerCase();

    if (message.contains('网络') ||
        message.contains('network') ||
        e.statusCode != null) {
      return '网络连接失败，请检查网络后重试';
    } else if (message.contains('解析') || message.contains('parse')) {
      return '数据格式错误，请稍后重试';
    } else if (message.contains('超时') || message.contains('timeout')) {
      return '请求超时，请稍后重试';
    } else if (message.contains('章节列表') || message.contains('chapter')) {
      return '获取章节列表失败，请重试';
    } else if (message.contains('章节内容') || message.contains('content')) {
      return '获取章节内容失败，请重试';
    } else {
      return '加载失败，请重试';
    }
  }
}
