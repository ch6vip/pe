import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_source.dart';

/// 书源管理服务
///
/// 负责书源的增删改查操作和本地持久化存储
/// 使用 shared_preferences 进行本地数据存储
class SourceManagerService extends ChangeNotifier {
  static const String _sourcesKey = 'book_sources';
  static const String _lastUpdateTimeKey = 'sources_last_update';

  List<BookSource> _sources = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// 获取所有书源列表（只读）
  List<BookSource> get sources => List.unmodifiable(_sources);

  /// 获取启用的书源列表
  List<BookSource> get enabledSources =>
      _sources.where((source) => source.enabled).toList();

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 获取书源总数
  int get sourceCount => _sources.length;

  /// 获取启用书源数量
  int get enabledSourceCount => enabledSources.length;

  /// 初始化服务，加载本地存储的书源数据
  Future<void> initialize() async {
    await _loadSources();
  }

  /// 从本地存储加载书源数据
  Future<void> _loadSources() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final sourcesJson = prefs.getString(_sourcesKey);

      if (sourcesJson != null && sourcesJson.isNotEmpty) {
        final List<dynamic> sourcesList = json.decode(sourcesJson);
        _sources = sourcesList
            .map((json) => BookSource.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // 如果没有本地数据，创建默认的演示书源
        _sources = [BookSource.createDemoSource()];
        await _saveSources();
      }

      _clearError();
    } catch (e) {
      _setError('加载书源数据失败: $e');
      // 发生错误时创建默认书源，确保应用可用
      _sources = [BookSource.createDemoSource()];
    } finally {
      _setLoading(false);
    }
  }

  /// 保存书源数据到本地存储
  Future<void> _saveSources() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sourcesJson = json.encode(
        _sources.map((source) => source.toJson()).toList(),
      );
      await prefs.setString(_sourcesKey, sourcesJson);
      await prefs.setInt(
          _lastUpdateTimeKey, DateTime.now().millisecondsSinceEpoch);
      _clearError();
    } catch (e) {
      _setError('保存书源数据失败: $e');
      rethrow;
    }
  }

  /// 添加新书源
  Future<bool> addSource(BookSource source) async {
    try {
      _setLoading(true);

      // 检查是否已存在相同 ID 的书源
      if (_sources.any((s) => s.id == source.id)) {
        _setError('已存在相同 ID 的书源');
        return false;
      }

      // 检查是否已存在相同名称的书源
      if (_sources.any((s) => s.name == source.name)) {
        _setError('已存在相同名称的书源');
        return false;
      }

      // 创建带有时间戳的新书源
      final newSource = source.copyWith(
        createTime: DateTime.now().millisecondsSinceEpoch,
        updateTime: DateTime.now().millisecondsSinceEpoch,
      );

      _sources.add(newSource);
      await _saveSources();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('添加书源失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 根据名称和 URL 创建并添加新书源（简化版导入）
  Future<bool> addSimpleSource(String name, String baseUrl) async {
    try {
      // 验证输入
      if (name.trim().isEmpty) {
        _setError('书源名称不能为空');
        return false;
      }

      if (baseUrl.trim().isEmpty) {
        _setError('书源地址不能为空');
        return false;
      }

      // 标准化 URL
      String normalizedUrl = baseUrl.trim();
      if (!normalizedUrl.startsWith('http://') &&
          !normalizedUrl.startsWith('https://')) {
        normalizedUrl = 'https://$normalizedUrl';
      }

      final newSource = BookSource(
        id: BookSource.generateId(),
        name: name.trim(),
        baseUrl: normalizedUrl,
        enabled: true,
      );

      return await addSource(newSource);
    } catch (e) {
      _setError('创建书源失败: $e');
      return false;
    }
  }

  /// 更新书源信息
  Future<bool> updateSource(BookSource updatedSource) async {
    try {
      _setLoading(true);

      final index =
          _sources.indexWhere((source) => source.id == updatedSource.id);
      if (index == -1) {
        _setError('未找到要更新的书源');
        return false;
      }

      // 更新时间戳
      final sourceWithTimestamp = updatedSource.copyWith(
        updateTime: DateTime.now().millisecondsSinceEpoch,
      );

      _sources[index] = sourceWithTimestamp;
      await _saveSources();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('更新书源失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 切换书源启用状态
  Future<bool> toggleSourceEnabled(String sourceId) async {
    try {
      final index = _sources.indexWhere((source) => source.id == sourceId);
      if (index == -1) {
        _setError('未找到要切换的书源');
        return false;
      }

      final updatedSource = _sources[index].copyWith(
        enabled: !_sources[index].enabled,
        updateTime: DateTime.now().millisecondsSinceEpoch,
      );

      _sources[index] = updatedSource;
      await _saveSources();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('切换书源状态失败: $e');
      return false;
    }
  }

  /// 删除书源
  Future<bool> deleteSource(String sourceId) async {
    try {
      _setLoading(true);

      final originalLength = _sources.length;
      _sources.removeWhere((source) => source.id == sourceId);

      if (_sources.length == originalLength) {
        _setError('未找到要删除的书源');
        return false;
      }

      await _saveSources();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('删除书源失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 根据ID获取书源
  BookSource? getSourceById(String sourceId) {
    try {
      return _sources.firstWhere((source) => source.id == sourceId);
    } catch (e) {
      return null;
    }
  }

  /// 清空所有书源
  Future<bool> clearAllSources() async {
    try {
      _setLoading(true);
      _sources.clear();
      await _saveSources();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('清空书源失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 重置为默认书源
  Future<bool> resetToDefault() async {
    try {
      _setLoading(true);
      _sources = [BookSource.createDemoSource()];
      await _saveSources();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('重置书源失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 设置错误信息
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 清除错误信息
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// 手动清除错误信息（供外部调用）
  void clearError() {
    _clearError();
  }
}
