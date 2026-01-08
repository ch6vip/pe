import 'package:flutter/material.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/models/chapter.dart';
import 'package:reader_flutter/models/chapter_content.dart';
import 'package:reader_flutter/services/api_service.dart';
import 'package:reader_flutter/services/storage_service.dart';

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
  final Book book;

  ReaderController({
    required this.book,
    ApiService? apiService,
    StorageService? storageService,
  }) : _apiService = apiService ?? ApiService(),
       _storageService = storageService ?? StorageService();

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
      notifyListeners();

      // 1. 加载章节列表
      _chapters = await _apiService.getChapterList(book.id);

      if (_chapters.isEmpty) {
        _errorMessage = '未能加载到章节列表';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. 查找上次阅读位置
      final initialIndex = await _findLastReadChapterIndex();
      _currentChapterIndex = initialIndex;

      // 3. 加载当前章节内容
      await loadChapterContent(initialIndex);
    } catch (e) {
      _errorMessage = '加载失败: $e';
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

    _isLoading = true;
    _errorMessage = null;
    _currentChapterIndex = index;
    notifyListeners();

    try {
      final chapter = _chapters[index];
      ChapterContent? content;

      // 1. 尝试从缓存获取
      content = await _storageService.getChapterContent(chapter.itemId);

      if (content != null) {
        _currentContent = content;
        _isLoading = false;
        notifyListeners();

        // 即使有缓存，也可以在后台静默更新（可选，视需求而定）
        // 这里我们选择信任缓存，仅在缓存不存在时请求网络
      } else {
        // 2. 缓存未命中，请求网络
        content = await _apiService.getChapterContent(chapter.itemId);
        _currentContent = content;

        // 保存到缓存
        await _storageService.saveChapterContent(chapter.itemId, content);

        _isLoading = false;
        notifyListeners();
      }

      // 3. 保存阅读进度
      _saveProgress(index);

      // 4. 预加载下一章
      _preloadNextChapter(index);
    } catch (e) {
      _errorMessage = '加载章节内容失败';
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

    try {
      // 延迟一点执行，避免抢占当前章节渲染资源
      await Future.delayed(const Duration(seconds: 1));

      final content = await _apiService.getChapterContent(nextChapter.itemId);
      await _storageService.saveChapterContent(nextChapter.itemId, content);
      debugPrint('预加载成功: ${nextChapter.title}');
    } catch (e) {
      // 预加载失败不干扰用户，仅记录日志
      debugPrint('预加载失败: $e');
    }
  }

  /// 保存阅读进度
  Future<void> _saveProgress(int chapterIndex) async {
    try {
      await _storageService.updateReadingProgress(
        book.id,
        _chapters[chapterIndex].title,
      );
    } catch (e) {
      // 保存进度失败不应影响阅读体验
    }
  }

  /// 前往上一章
  void goToPreviousChapter() {
    if (_currentChapterIndex > 0) {
      loadChapterContent(_currentChapterIndex - 1);
    }
  }

  /// 前往下一章
  void goToNextChapter() {
    if (_currentChapterIndex < _chapters.length - 1) {
      loadChapterContent(_currentChapterIndex + 1);
    }
  }

  /// 是否有上一章
  bool get hasPreviousChapter => _currentChapterIndex > 0;

  /// 是否有下一章
  bool get hasNextChapter => _currentChapterIndex < _chapters.length - 1;
}
