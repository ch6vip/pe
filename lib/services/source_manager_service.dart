import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/book_source.dart';

/// Book source manager service
///
/// Handles CRUD operations for book sources and local persistence.
/// Uses shared_preferences for local storage.
class SourceManagerService extends ChangeNotifier {
  static const String _sourcesKey = 'book_sources';
  static const String _lastUpdateTimeKey = 'sources_last_update';

  List<BookSource> _sources = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// Get all book sources (read-only)
  List<BookSource> get sources => List.unmodifiable(_sources);

  /// Get enabled book sources
  List<BookSource> get enabledSources =>
      _sources.where((source) => source.enabled).toList();

  /// Whether loading is in progress
  bool get isLoading => _isLoading;

  /// Error message
  String? get errorMessage => _errorMessage;

  /// Total number of sources
  int get sourceCount => _sources.length;

  /// Number of enabled sources
  int get enabledSourceCount => enabledSources.length;

  /// Initialize service and load sources from local storage
  Future<void> initialize() async {
    await _loadSources();
  }

  /// Load sources from local storage
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
        // If there's no local data, create a default demo source.
        _sources = [BookSource.createDemoSource()];
        await _saveSources();
      }

      _clearError();
    } catch (e) {
      _setError('加载书源数据失败: $e');
      // Fall back to a demo source to keep the app usable.
      _sources = [BookSource.createDemoSource()];
    } finally {
      _setLoading(false);
    }
  }

  /// Save sources to local storage
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

  /// Add a new book source
  Future<bool> addSource(BookSource source) async {
    try {
      _setLoading(true);

      // Check for an existing source with the same URL.
      if (_sources.any((s) => s.bookSourceUrl == source.bookSourceUrl)) {
        _setError('已存在相同 URL 的书源');
        return false;
      }

      // Check for an existing source with the same name.
      if (_sources.any((s) => s.bookSourceName == source.bookSourceName)) {
        _setError('已存在相同名称的书源');
        return false;
      }

      // Create a new source with a timestamp.
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

  /// Create and add a book source by name and URL (simple import)
  Future<bool> addSimpleSource(String name, String bookSourceUrl) async {
    try {
      // Validate input.
      if (name.trim().isEmpty) {
        _setError('书源名称不能为空');
        return false;
      }

      if (bookSourceUrl.trim().isEmpty) {
        _setError('书源地址不能为空');
        return false;
      }

      // Normalize URL.
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

  /// Update a book source
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

      // Update timestamp.
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

  /// Toggle source enabled state
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

  /// Delete a book source
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

  /// Get a source by URL
  BookSource? getSourceByUrl(String sourceUrl) {
    try {
      return _sources.firstWhere((source) => source.bookSourceUrl == sourceUrl);
    } catch (e) {
      return null;
    }
  }

  /// Clear all sources
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

  /// Reset to the default source
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

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Clear error manually (for external callers)
  void clearError() {
    _clearError();
  }

  /// Import sources from a URL
  ///
  /// Supports JSON source files as a single object or an array.
  /// Returns the number of imported sources.
  Future<int> importSourceFromUrl(String url) async {
    try {
      _setLoading(true);
      _clearError();

      // Validate URL.
      if (url.trim().isEmpty) {
        throw Exception('URL 不能为空');
      }

      // Perform the network request.
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

      // Parse response data.
      final responseData = json.decode(response.body);
      List<BookSource> sourcesToImport = [];

      // Handle JSON that may be a single object or an array.
      if (responseData is List) {
        // JSON array: convert each element to a BookSource.
        for (final item in responseData) {
          if (item is Map<String, dynamic>) {
            try {
              final source = BookSource.fromJson(item);
              sourcesToImport.add(source);
            } catch (e) {
              // Debug info: failed to parse a single source.
              debugPrint('解析单个书源失败: $e, 数据: $item');
            }
          }
        }
      } else if (responseData is Map<String, dynamic>) {
        // JSON object: convert directly to a BookSource.
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

      // Bulk import with deduplication.
      int importedCount = 0;
      for (final source in sourcesToImport) {
        bool shouldAdd = true;
        bool shouldUpdate = false;

        // Update if the same bookSourceUrl exists.
        if (_sources.any((s) => s.bookSourceUrl == source.bookSourceUrl)) {
          shouldAdd = false;
          shouldUpdate = true;
        }
        // Skip if the same name exists with a different URL.
        else if (_sources
            .any((s) => s.bookSourceName == source.bookSourceName)) {
          shouldAdd = false;
        }

        if (shouldUpdate) {
          // Update existing source.
          final index = _sources
              .indexWhere((s) => s.bookSourceUrl == source.bookSourceUrl);
          final updatedSource = source.copyWith(
            lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
          );
          _sources[index] = updatedSource;
          importedCount++;
        } else if (shouldAdd) {
          // Add new source.
          final newSource = source.copyWith(
            lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
          );
          _sources.add(newSource);
          importedCount++;
        }
      }

      // Save to local storage.
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
