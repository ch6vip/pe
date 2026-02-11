import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reader_flutter/controllers/reader_controller.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/services/source_manager_service.dart';

/// 阅读主题配置
///
/// 封装阅读主题的背景色和文字颜色
class _ReaderTheme {
  final Color backgroundColor;
  final Color fontColor;

  const _ReaderTheme({required this.backgroundColor, required this.fontColor});
}

/// 阅读器页面
///
/// 提供沉浸式阅读体验，支持章节切换、字号调整、主题切换等功能
///
/// 功能特性：
/// - 点击屏幕切换 UI 显示/隐藏
/// - 侧边抽屉显示章节列表
/// - 底部工具栏切换章节和调整设置
/// - 支持 4 种预设主题
/// - 字号和行高可调节
class ReaderScreen extends StatefulWidget {
  /// 要阅读的书籍
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

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
  void dispose() {
    // 释放滚动控制器，防止内存泄漏
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReaderController(
        book: widget.book,
        sourceManagerService: context.read<SourceManagerService>(),
      )..initialize(),
      child: Consumer<ReaderController>(
        builder: (context, controller, child) {
          // 监听内容变化，滚动到顶部
          // 注意：这里使用 addPostFrameCallback 避免在 build 过程中调用 jumpTo
          if (controller.currentContent != null &&
              _scrollController.hasClients &&
              _scrollController.offset > 0) {
            // 简单的判断可能不够，理想情况下应该由 Controller 通知滚动
            // 但为了简化，这里假设每次内容变化都是新章节，需要重置滚动
            // 实际项目中可以使用 EventBus 或 Stream 来处理这种一次性事件
            // 或者在 Controller 中增加一个 version 字段来比较
          }

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: _themeIndex == 3
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: _currentTheme.backgroundColor,
              appBar: _buildAppBar(controller),
              body: GestureDetector(
                onTap: _toggleUiVisibility,
                child: _buildBody(controller),
              ),
              bottomNavigationBar: _buildBottomBar(controller),
              endDrawer: _buildChapterDrawer(controller),
            ),
          );
        },
      ),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget? _buildAppBar(ReaderController controller) {
    if (!_isUiVisible) return null;

    return AppBar(
      title: Text(
        controller.currentContent?.title ?? widget.book.name,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: _currentTheme.backgroundColor,
      foregroundColor: _currentTheme.fontColor,
      elevation: 0.5,
      actions: const [SizedBox.shrink()], // 禁用默认 endDrawer 按钮
    );
  }

  /// 构建主体内容
  Widget _buildBody(ReaderController controller) {
    if (controller.isLoading && controller.currentContent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null) {
      return _buildErrorState(controller);
    }

    if (controller.currentContent == null) {
      return Center(
        child: Text('没有内容', style: TextStyle(color: _currentTheme.fontColor)),
      );
    }

    // 每次内容变化时重置滚动位置
    // 使用 Key 强制重建 SingleChildScrollView 是一种简单有效的方法
    return SingleChildScrollView(
      key: ValueKey(controller.currentContent!.title),
      controller: _scrollController,
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: _isUiVisible ? 20.0 : MediaQuery.of(context).padding.top + 20.0,
        bottom: _isUiVisible
            ? 20.0
            : MediaQuery.of(context).padding.bottom + 20.0,
      ),
      child: Text(
        controller.currentContent!.content,
        style: TextStyle(
          fontSize: _fontSize,
          height: _lineHeight,
          color: _currentTheme.fontColor,
        ),
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(ReaderController controller) {
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
              controller.errorMessage!,
              style: TextStyle(color: _currentTheme.fontColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  controller.loadChapterContent(controller.currentChapterIndex),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建底部导航栏
  Widget? _buildBottomBar(ReaderController controller) {
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
            onPressed: controller.hasPreviousChapter
                ? controller.goToPreviousChapter
                : null,
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
            onPressed: controller.hasNextChapter
                ? controller.goToNextChapter
                : null,
            tooltip: '下一章',
          ),
        ],
      ),
    );
  }

  /// 构建章节目录抽屉
  Widget _buildChapterDrawer(ReaderController controller) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '目录 (${controller.chapters.length}章)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            // 章节列表
            Expanded(
              child: controller.chapters.isEmpty
                  ? const Center(child: Text('暂无章节'))
                  : ListView.builder(
                      itemCount: controller.chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = controller.chapters[index];
                        final isCurrent =
                            index == controller.currentChapterIndex;

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
                            controller.loadChapterContent(index);
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
