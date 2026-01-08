import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
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
        _lastUpdateTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
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

      // 检查是否已存在相同 URL 的书源
      if (_sources.any((s) => s.bookSourceUrl == source.bookSourceUrl)) {
        _setError('已存在相同 URL 的书源');
        return false;
      }

      // 检查是否已存在相同名称的书源
      if (_sources.any((s) => s.bookSourceName == source.bookSourceName)) {
        _setError('已存在相同名称的书源');
        return false;
      }

      // 创建带有时间戳的新书源
      final newSource = source.copyWith(
        lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
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
  Future<bool> addSimpleSource(String name, String bookSourceUrl) async {
    try {
      // 验证输入
      if (name.trim().isEmpty) {
        _setError('书源名称不能为空');
        return false;
      }

      if (bookSourceUrl.trim().isEmpty) {
        _setError('书源地址不能为空');
        return false;
      }

      // 标准化 URL
      String normalizedUrl = bookSourceUrl.trim();
      if (!normalizedUrl.startsWith('http://') &&
          !normalizedUrl.startsWith('https://')) {
        normalizedUrl = 'https://$normalizedUrl';
      }

      final newSource = BookSource(
        bookSourceUrl: normalizedUrl,
        bookSourceName: name.trim(),
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

      final index = _sources.indexWhere(
        (source) => source.bookSourceUrl == updatedSource.bookSourceUrl,
      );
      if (index == -1) {
        _setError('未找到要更新的书源');
        return false;
      }

      // 更新时间戳
      final sourceWithTimestamp = updatedSource.copyWith(
        lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
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
  Future<bool> toggleSourceEnabled(String sourceUrl) async {
    try {
      final index =
          _sources.indexWhere((source) => source.bookSourceUrl == sourceUrl);
      if (index == -1) {
        _setError('未找到要切换的书源');
        return false;
      }

      final updatedSource = _sources[index].copyWith(
        enabled: !_sources[index].enabled,
        lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
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
  Future<bool> deleteSource(String sourceUrl) async {
    try {
      _setLoading(true);

      final originalLength = _sources.length;
      _sources.removeWhere((source) => source.bookSourceUrl == sourceUrl);

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

  /// 根据URL获取书源
  BookSource? getSourceByUrl(String sourceUrl) {
    try {
      return _sources.firstWhere((source) => source.bookSourceUrl == sourceUrl);
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

  /// 从 URL 导入书源
  ///
  /// 支持 JSON 格式的书源文件，可以是单个书源对象或书源数组
  /// 返回成功导入的书源数量
  Future<int> importSourceFromUrl(String url) async {
    try {
      _setLoading(true);
      _clearError();

      // 验证 URL
      if (url.trim().isEmpty) {
        throw Exception('URL 不能为空');
      }

      // 发起网络请求
      final response = await http.get(
        Uri.parse(url.trim()),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('网络请求失败，状态码: ${response.statusCode}');
      }

      // 解析响应数据
      final responseData = json.decode(response.body);
      List<BookSource> sourcesToImport = [];

      // 处理 JSON 数据兼容性：可能是单个对象或数组
      if (responseData is List) {
        // JSON 数组：遍历每个元素转换为 BookSource
        for (final item in responseData) {
          if (item is Map<String, dynamic>) {
            try {
              final source = BookSource.fromJson(item);
              sourcesToImport.add(source);
            } catch (e) {
              // 调试信息：解析单个书源失败
              debugPrint('解析单个书源失败: $e, 数据: $item');
            }
          }
        }
      } else if (responseData is Map<String, dynamic>) {
        // JSON 对象：直接转换为 BookSource
        try {
          final source = BookSource.fromJson(responseData);
          sourcesToImport.add(source);
        } catch (e) {
          throw Exception('解析书源数据失败: $e');
        }
      } else {
        throw Exception('不支持的数据格式，期望 JSON 对象或数组');
      }

      if (sourcesToImport.isEmpty) {
        throw Exception('未找到有效的书源数据');
      }

      // 批量导入书源（去重逻辑）
      int importedCount = 0;
      for (final source in sourcesToImport) {
        bool shouldAdd = true;
        bool shouldUpdate = false;

        // 如果存在相同 bookSourceUrl，则更新
        if (_sources.any((s) => s.bookSourceUrl == source.bookSourceUrl)) {
          shouldAdd = false;
          shouldUpdate = true;
        }
        // 如果存在相同名称但不同 bookSourceUrl，则跳过（避免重复）
        else if (_sources
            .any((s) => s.bookSourceName == source.bookSourceName)) {
          shouldAdd = false;
        }

        if (shouldUpdate) {
          // 更新现有书源
          final index = _sources
              .indexWhere((s) => s.bookSourceUrl == source.bookSourceUrl);
          final updatedSource = source.copyWith(
            lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
          );
          _sources[index] = updatedSource;
          importedCount++;
        } else if (shouldAdd) {
          // 添加新书源
          final newSource = source.copyWith(
            lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
          );
          _sources.add(newSource);
          importedCount++;
        }
      }

      // 保存到本地存储
      if (importedCount > 0) {
        await _saveSources();
        notifyListeners();
      }

      return importedCount;
    } catch (e) {
      _setError('导入失败: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
