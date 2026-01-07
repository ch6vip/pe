import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/models/chapter.dart';
import 'package:reader_flutter/models/chapter_content.dart';
import 'package:reader_flutter/services/api_service.dart';
import 'package:reader_flutter/services/storage_service.dart';

/// 阅读主题配置
class _ReaderTheme {
  final Color backgroundColor;
  final Color fontColor;

  const _ReaderTheme({
    required this.backgroundColor,
    required this.fontColor,
  });
}

/// 阅读器页面
///
/// 提供沉浸式阅读体验，支持章节切换、字号调整、主题切换等功能
class ReaderScreen extends StatefulWidget {
  /// 要阅读的书籍
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  // ==================== 状态变量 ====================

  /// 章节列表
  List<Chapter> _chapters = [];

  /// 当前章节内容
  ChapterContent? _currentContent;

  /// 当前章节索引
  int _currentChapterIndex = 0;

  /// 是否正在加载
  bool _isLoading = true;

  /// 错误信息
  String? _errorMessage;

  // ==================== 阅读设置 ====================

  /// 字号
  double _fontSize = 18.0;

  /// 行高
  double _lineHeight = 1.8;

  /// 当前主题索引
  int _themeIndex = 0;

  /// 是否显示 UI 控件
  bool _isUiVisible = true;

  /// 可用主题列表
  static const List<_ReaderTheme> _themes = [
    _ReaderTheme(
      backgroundColor: Colors.white,
      fontColor: Color(0xDD000000), // Colors.black87
    ),
    _ReaderTheme(
      backgroundColor: Color(0xFFF5F5DC), // 米黄色
      fontColor: Color(0xDD000000),
    ),
    _ReaderTheme(
      backgroundColor: Color(0xFFE0F2F1), // 淡青色
      fontColor: Color(0xDD000000),
    ),
    _ReaderTheme(
      backgroundColor: Color(0xFF333333), // 深色
      fontColor: Color(0xFF9E9E9E),
    ),
  ];

  /// 当前主题
  _ReaderTheme get _currentTheme => _themes[_themeIndex];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ==================== 数据加载 ====================

  /// 加载初始数据
  Future<void> _loadInitialData() async {
    try {
      final chapters = await _apiService.getChapterList(widget.book.id);

      if (chapters.isEmpty) {
        setState(() {
          _errorMessage = '未能加载到章节列表';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _chapters = chapters;
      });

      // 查找上次阅读位置
      final initialIndex = await _findLastReadChapterIndex(chapters);
      await _loadChapterContent(initialIndex);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '加载章节列表失败，请检查网络连接';
        _isLoading = false;
      });
    }
  }

  /// 查找上次阅读的章节索引
  Future<int> _findLastReadChapterIndex(List<Chapter> chapters) async {
    try {
      final bookshelf = await _storageService.getBookshelf();
      final savedBook = bookshelf.firstWhere(
        (b) => b.id == widget.book.id,
        orElse: () => widget.book,
      );

      if (savedBook.lastReadChapterTitle != null) {
        final savedIndex = chapters.indexWhere(
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

  /// 加载章节内容
  Future<void> _loadChapterContent(int index) async {
    if (index < 0 || index >= _chapters.length) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final content =
          await _apiService.getChapterContent(_chapters[index].itemId);

      if (!mounted) return;

      setState(() {
        _currentContent = content;
        _currentChapterIndex = index;
        _isLoading = false;
      });

      // 滚动到顶部
      _scrollController.jumpTo(0);

      // 保存阅读进度
      _saveProgress(index);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '加载章节内容失败';
        _isLoading = false;
      });
    }
  }

  /// 保存阅读进度
  Future<void> _saveProgress(int chapterIndex) async {
    try {
      await _storageService.updateReadingProgress(
        widget.book.id,
        _chapters[chapterIndex].title,
      );
    } catch (e) {
      // 保存进度失败不应影响阅读体验
    }
  }

  // ==================== 章节导航 ====================

  /// 前往上一章
  void _goToPreviousChapter() {
    if (_currentChapterIndex > 0) {
      _loadChapterContent(_currentChapterIndex - 1);
    }
  }

  /// 前往下一章
  void _goToNextChapter() {
    if (_currentChapterIndex < _chapters.length - 1) {
      _loadChapterContent(_currentChapterIndex + 1);
    }
  }

  /// 是否有上一章
  bool get _hasPreviousChapter => _currentChapterIndex > 0;

  /// 是否有下一章
  bool get _hasNextChapter => _currentChapterIndex < _chapters.length - 1;

  // ==================== UI 构建 ====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _themeIndex == 3
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _currentTheme.backgroundColor,
        appBar: _buildAppBar(),
        body: GestureDetector(
          onTap: _toggleUiVisibility,
          child: _buildBody(),
        ),
        bottomNavigationBar: _buildBottomBar(),
        endDrawer: _buildChapterDrawer(),
      ),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget? _buildAppBar() {
    if (!_isUiVisible) return null;

    return AppBar(
      title: Text(
        _currentContent?.title ?? widget.book.name,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: _currentTheme.backgroundColor,
      foregroundColor: _currentTheme.fontColor,
      elevation: 0.5,
      actions: const [SizedBox.shrink()], // 禁用默认 endDrawer 按钮
    );
  }

  /// 构建主体内容
  Widget _buildBody() {
    if (_isLoading && _currentContent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_currentContent == null) {
      return Center(
        child: Text(
          '没有内容',
          style: TextStyle(color: _currentTheme.fontColor),
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: _isUiVisible ? 20.0 : MediaQuery.of(context).padding.top + 20.0,
        bottom:
            _isUiVisible ? 20.0 : MediaQuery.of(context).padding.bottom + 20.0,
      ),
      child: Text(
        _currentContent!.content,
        style: TextStyle(
          fontSize: _fontSize,
          height: _lineHeight,
          color: _currentTheme.fontColor,
        ),
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: _currentTheme.fontColor.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: _currentTheme.fontColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadChapterContent(_currentChapterIndex),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建底部导航栏
  Widget? _buildBottomBar() {
    if (!_isUiVisible) return null;

    return BottomAppBar(
      color: _currentTheme.backgroundColor,
      elevation: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 上一章
          IconButton(
            icon: Icon(Icons.arrow_back, color: _currentTheme.fontColor),
            onPressed: _hasPreviousChapter ? _goToPreviousChapter : null,
            tooltip: '上一章',
          ),
          // 目录
          IconButton(
            icon: Icon(Icons.list, color: _currentTheme.fontColor),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            tooltip: '目录',
          ),
          // 设置
          IconButton(
            icon: Icon(Icons.settings, color: _currentTheme.fontColor),
            onPressed: _showSettingsPanel,
            tooltip: '设置',
          ),
          // 下一章
          IconButton(
            icon: Icon(Icons.arrow_forward, color: _currentTheme.fontColor),
            onPressed: _hasNextChapter ? _goToNextChapter : null,
            tooltip: '下一章',
          ),
        ],
      ),
    );
  }

  /// 构建章节目录抽屉
  Widget _buildChapterDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '目录 (${_chapters.length}章)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            // 章节列表
            Expanded(
              child: _chapters.isEmpty
                  ? const Center(child: Text('暂无章节'))
                  : ListView.builder(
                      itemCount: _chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = _chapters[index];
                        final isCurrent = index == _currentChapterIndex;

                        return ListTile(
                          title: Text(
                            chapter.title,
                            style: TextStyle(
                              color: isCurrent
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _loadChapterContent(index);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 交互处理 ====================

  /// 切换 UI 可见性
  void _toggleUiVisibility() {
    setState(() {
      _isUiVisible = !_isUiVisible;
    });
  }

  /// 显示设置面板
  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _currentTheme.backgroundColor,
      builder: (context) => _SettingsPanel(
        fontSize: _fontSize,
        lineHeight: _lineHeight,
        themeIndex: _themeIndex,
        themes: _themes,
        fontColor: _currentTheme.fontColor,
        onFontSizeChanged: (value) {
          setState(() {
            _fontSize = value;
          });
        },
        onLineHeightChanged: (value) {
          setState(() {
            _lineHeight = value;
          });
        },
        onThemeChanged: (index) {
          setState(() {
            _themeIndex = index;
          });
        },
      ),
    );
  }
}

/// 设置面板组件
class _SettingsPanel extends StatefulWidget {
  final double fontSize;
  final double lineHeight;
  final int themeIndex;
  final List<_ReaderTheme> themes;
  final Color fontColor;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onLineHeightChanged;
  final ValueChanged<int> onThemeChanged;

  const _SettingsPanel({
    required this.fontSize,
    required this.lineHeight,
    required this.themeIndex,
    required this.themes,
    required this.fontColor,
    required this.onFontSizeChanged,
    required this.onLineHeightChanged,
    required this.onThemeChanged,
  });

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  late double _fontSize;
  late double _lineHeight;
  late int _themeIndex;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.fontSize;
    _lineHeight = widget.lineHeight;
    _themeIndex = widget.themeIndex;
  }

  Color get _fontColor => widget.themes[_themeIndex].fontColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 字号控制
          _buildFontSizeControl(),
          const SizedBox(height: 20),
          // 行距控制
          _buildLineHeightControl(),
          const SizedBox(height: 20),
          // 主题选择
          _buildThemeControl(),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// 构建字号控制
  Widget _buildFontSizeControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('字号', style: TextStyle(color: _fontColor)),
        Row(
          children: [
            _buildControlButton(
              label: 'A-',
              onPressed: () {
                final newValue = (_fontSize - 1).clamp(12.0, 30.0);
                setState(() => _fontSize = newValue);
                widget.onFontSizeChanged(newValue);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _fontSize.toInt().toString(),
                style: TextStyle(color: _fontColor),
              ),
            ),
            _buildControlButton(
              label: 'A+',
              onPressed: () {
                final newValue = (_fontSize + 1).clamp(12.0, 30.0);
                setState(() => _fontSize = newValue);
                widget.onFontSizeChanged(newValue);
              },
            ),
          ],
        ),
      ],
    );
  }

  /// 构建行距控制
  Widget _buildLineHeightControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('行距', style: TextStyle(color: _fontColor)),
        Row(
          children: [
            _buildControlButton(
              icon: Icons.format_line_spacing,
              onPressed: () {
                final newValue = (_lineHeight - 0.1).clamp(1.2, 2.5);
                setState(() => _lineHeight = newValue);
                widget.onLineHeightChanged(newValue);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _lineHeight.toStringAsFixed(1),
                style: TextStyle(color: _fontColor),
              ),
            ),
            _buildControlButton(
              icon: Icons.format_line_spacing,
              onPressed: () {
                final newValue = (_lineHeight + 0.1).clamp(1.2, 2.5);
                setState(() => _lineHeight = newValue);
                widget.onLineHeightChanged(newValue);
              },
            ),
          ],
        ),
      ],
    );
  }

  /// 构建主题选择
  Widget _buildThemeControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('主题', style: TextStyle(color: _fontColor)),
        Row(
          children: List.generate(widget.themes.length, (index) {
            final theme = widget.themes[index];
            final isSelected = index == _themeIndex;

            return GestureDetector(
              onTap: () {
                setState(() => _themeIndex = index);
                widget.onThemeChanged(index);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade400,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 18, color: Colors.blue)
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  /// 构建控制按钮
  Widget _buildControlButton({
    String? label,
    IconData? icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: _fontColor.withAlpha(128)),
        minimumSize: const Size(44, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: onPressed,
      child: icon != null
          ? Icon(icon, color: _fontColor, size: 20)
          : Text(label!, style: TextStyle(color: _fontColor)),
    );
  }
}
