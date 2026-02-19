import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:reader_flutter/services/app_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 翻页动画类型枚举
enum PageAnimationType {
  /// 覆盖动画
  cover,

  /// 仿真翻页动画
  simulation,

  /// 无动画
  none,
}

/// 阅读器主题枚举
enum ReaderTheme {
  /// 护眼模式（米黄色背景）
  eyeProtection,

  /// 夜间模式（深色背景）
  dark,

  /// 羊皮纸模式（浅棕色背景）
  parchment,

  /// E-ink 模式（灰白色背景）
  eInk,
}

/// 阅读器设置服务
///
/// 使用 ChangeNotifier 实现状态管理，通过 SharedPreferences 持久化存储
/// 管理阅读器的核心设置：字体大小、行高、翻页动画、背景主题等
class ReaderSettingsService extends ChangeNotifier {
  final AppLogService _logService = AppLogService();

  // ==================== 私有属性 ====================

  /// 字体大小（默认 18.0）
  double _fontSize = 18.0;

  /// 行高倍数（默认 1.8）
  double _lineHeight = 1.8;

  /// 翻页动画类型（默认覆盖动画）
  PageAnimationType _pageAnimation = PageAnimationType.cover;

  /// 背景主题（默认护眼模式）
  ReaderTheme _theme = ReaderTheme.eyeProtection;

  /// SharedPreferences 键名常量
  static const String _keyFontSize = 'reader_font_size';
  static const String _keyLineHeight = 'reader_line_height';
  static const String _keyPageAnimation = 'reader_page_animation';
  static const String _keyTheme = 'reader_theme';

  // ==================== Getter 方法 ====================

  /// 获取字体大小
  double get fontSize => _fontSize;

  /// 获取行高
  double get lineHeight => _lineHeight;

  /// 获取翻页动画类型
  PageAnimationType get pageAnimation => _pageAnimation;

  /// 获取背景主题
  ReaderTheme get theme => _theme;

  /// 获取当前主题的背景色
  Color get themeBackgroundColor {
    switch (_theme) {
      case ReaderTheme.eyeProtection:
        return const Color(0xFFF5E6D3); // 米黄色
      case ReaderTheme.dark:
        return const Color(0xFF1A1A1A); // 深灰色
      case ReaderTheme.parchment:
        return const Color(0xFFF4E4BC); // 羊皮纸色
      case ReaderTheme.eInk:
        return const Color(0xFFE8E8E8); // 灰白色
    }
  }

  /// 获取当前主题的文字颜色
  Color get themeTextColor {
    switch (_theme) {
      case ReaderTheme.eyeProtection:
      case ReaderTheme.parchment:
      case ReaderTheme.eInk:
        return const Color(0xFF2C2C2C); // 深灰色文字
      case ReaderTheme.dark:
        return const Color(0xFFE0E0E0); // 浅灰色文字
    }
  }

  // ==================== Setter 方法 ====================

  /// 更新字体大小
  ///
  /// [value] 字体大小，范围建议 12.0 - 30.0
  /// 超出范围的值会被限制在有效范围内
  void updateFontSize(double value) {
    _fontSize = value.clamp(12.0, 30.0);
    notifyListeners();
    _saveSettings();
  }

  /// 更新行高
  ///
  /// [value] 行高倍数，范围建议 1.2 - 2.5
  /// 超出范围的值会被限制在有效范围内
  void updateLineHeight(double value) {
    _lineHeight = value.clamp(1.2, 2.5);
    notifyListeners();
    _saveSettings();
  }

  /// 更新翻页动画类型
  ///
  /// [type] 翻页动画类型
  void updatePageAnimation(PageAnimationType type) {
    _pageAnimation = type;
    notifyListeners();
    _saveSettings();
  }

  /// 更新背景主题
  ///
  /// [theme] 背景主题
  void updateTheme(ReaderTheme theme) {
    _theme = theme;
    notifyListeners();
    _saveSettings();
  }

  // ==================== 持久化存储方法 ====================

  /// 保存设置到 SharedPreferences
  ///
  /// 性能优化：批量保存以减少 I/O 操作次数
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 批量保存所有设置，减少 I/O 操作次数
      await Future.wait([
        prefs.setDouble(_keyFontSize, _fontSize),
        prefs.setDouble(_keyLineHeight, _lineHeight),
        prefs.setInt(_keyPageAnimation, _pageAnimation.index),
        prefs.setInt(_keyTheme, _theme.index),
      ]);

      _logService.info('阅读设置已保存', tag: 'ReaderSettingsService');
    } catch (e) {
      _logService.warning('保存阅读设置失败: $e', tag: 'ReaderSettingsService');
    }
  }

  /// 从 SharedPreferences 加载设置
  ///
  /// 在应用启动时调用，恢复用户之前的设置
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载字体大小，失败则使用默认值 18.0
      _fontSize = prefs.getDouble(_keyFontSize) ?? 18.0;

      // 加载行高，失败则使用默认值 1.8
      _lineHeight = prefs.getDouble(_keyLineHeight) ?? 1.8;

      // 加载翻页动画类型，失败则使用默认值 cover
      final pageAnimationIndex = prefs.getInt(_keyPageAnimation);
      if (pageAnimationIndex != null &&
          pageAnimationIndex >= 0 &&
          pageAnimationIndex < PageAnimationType.values.length) {
        _pageAnimation = PageAnimationType.values[pageAnimationIndex];
      } else {
        _pageAnimation = PageAnimationType.cover;
      }

      // 加载主题，失败则使用默认值 eyeProtection
      final themeIndex = prefs.getInt(_keyTheme);
      if (themeIndex != null &&
          themeIndex >= 0 &&
          themeIndex < ReaderTheme.values.length) {
        _theme = ReaderTheme.values[themeIndex];
      } else {
        _theme = ReaderTheme.eyeProtection;
      }

      // 通知监听器设置已更新
      notifyListeners();

      _logService.info('阅读设置已加载', tag: 'ReaderSettingsService');
      _logService.debug('字体大小: $_fontSize', tag: 'ReaderSettingsService');
      _logService.debug('行高: $_lineHeight', tag: 'ReaderSettingsService');
      _logService.debug('翻页动画: $_pageAnimation', tag: 'ReaderSettingsService');
      _logService.debug('主题: $_theme', tag: 'ReaderSettingsService');
    } catch (e) {
      _logService.warning('加载阅读设置失败，使用默认值: $e', tag: 'ReaderSettingsService');
      // 加载失败时使用默认值
      _fontSize = 18.0;
      _lineHeight = 1.8;
      _pageAnimation = PageAnimationType.cover;
      _theme = ReaderTheme.eyeProtection;
      notifyListeners();
    }
  }

  /// 重置所有设置为默认值
  Future<void> resetToDefaults() async {
    _fontSize = 18.0;
    _lineHeight = 1.8;
    _pageAnimation = PageAnimationType.cover;
    _theme = ReaderTheme.eyeProtection;

    notifyListeners();
    await _saveSettings();

    _logService.info('阅读设置已重置为默认值', tag: 'ReaderSettingsService');
  }
}

/// PageAnimationType 扩展方法
extension PageAnimationTypeExtension on PageAnimationType {
  /// 获取翻页动画的显示名称
  String get displayName {
    switch (this) {
      case PageAnimationType.cover:
        return '覆盖';
      case PageAnimationType.simulation:
        return '仿真';
      case PageAnimationType.none:
        return '无动画';
    }
  }
}

/// ReaderTheme 扩展方法
extension ReaderThemeExtension on ReaderTheme {
  /// 获取主题的显示名称
  String get displayName {
    switch (this) {
      case ReaderTheme.eyeProtection:
        return '护眼';
      case ReaderTheme.dark:
        return '夜间';
      case ReaderTheme.parchment:
        return '羊皮纸';
      case ReaderTheme.eInk:
        return 'E-ink';
    }
  }
}
