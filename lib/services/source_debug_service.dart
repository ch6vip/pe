import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_source.dart';

/// 书源调试服务
///
/// 提供书源规则的调试功能，通过 Stream 实时输出调试日志
/// 模拟网络请求并应用规则解析（框架结构，实际解析引擎需后续集成）
class SourceDebugService {
  final StreamController<String> _logController =
      StreamController<String>.broadcast();

  /// 调试日志流
  Stream<String> get logStream => _logController.stream;

  /// 当前调试状态
  bool _isDebugging = false;

  /// 是否正在调试
  bool get isDebugging => _isDebugging;

  /// 调试书源
  ///
  /// [source] 要调试的书源
  /// [keyword] 测试关键词或书籍详情页URL
  /// 返回调试结果，通过 Stream 实时输出日志
  Future<void> debugSource(BookSource source, String keyword) async {
    if (_isDebugging) {
      _log('⚠️ 已有调试任务正在进行，请等待完成');
      return;
    }

    _isDebugging = true;
    try {
      _log('🚀 开始调试书源：${source.bookSourceName}');
      _log('📝 书源地址：${source.bookSourceUrl}');
      _log('');

      // Step 1: 搜索测试
      await _debugSearch(source, keyword);

      // Step 2: 详情测试（如果搜索成功）
      final searchResults = await _performSearch(source, keyword);
      if (searchResults.isNotEmpty) {
        await _debugDetail(source, searchResults.first);
      } else {
        _log('❌ 搜索无结果，跳过详情测试');
      }

      _log('');
      _log('✅ 调试完成');
    } catch (e) {
      _log('❌ 调试过程中发生错误：$e');
    } finally {
      _isDebugging = false;
    }
  }

  /// Step 1: 搜索规则调试
  Future<void> _debugSearch(BookSource source, String keyword) async {
    _log('📋 Step 1: 搜索规则测试');
    _log('🔍 测试关键词：$keyword');

    try {
      // 解析搜索规则
      final searchRule = _parseSearchRule(source.ruleSearch);
      _log('📄 解析搜索规则：$searchRule');

      // 构建搜索URL
      final searchUrl = _buildSearchUrl(
        source.bookSourceUrl,
        searchRule['searchUrl'] ?? '',
        keyword,
      );
      _log('🌐 搜索URL：$searchUrl');

      // 发起请求
      _log('⏳ 正在发起搜索请求...');
      final response = await _httpGet(searchUrl);
      _log('📡 响应状态码：${response.statusCode}');

      if (response.statusCode == 200) {
        _log('✅ 请求成功，响应长度：${response.body.length} 字符');
        _log(
          '📝 响应内容前200字符：${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
        );

        // 解析搜索结果
        final results = await _parseSearchResults(response.body, searchRule);
        _log('📚 解析到 ${results.length} 个搜索结果');

        // 显示前3个结果
        final displayCount = results.length > 3 ? 3 : results.length;
        for (int i = 0; i < displayCount; i++) {
          final result = results[i];
          _log('  📖 结果${i + 1}：${result['name']} - ${result['author']}');
          _log('    🔗 详情链接：${result['url']}');
        }
      } else {
        _log('❌ 请求失败：${response.reasonPhrase}');
      }
    } catch (e) {
      _log('❌ 搜索测试失败：$e');
    }

    _log('');
  }

  /// Step 2: 详情规则调试
  Future<void> _debugDetail(
    BookSource source,
    Map<String, String> bookInfo,
  ) async {
    _log('📋 Step 2: 详情规则测试');
    _log('📖 测试书籍：${bookInfo['name']}');

    try {
      final detailUrl = bookInfo['url'] ?? '';
      if (detailUrl.isEmpty) {
        _log('❌ 书籍详情链接为空，无法测试');
        return;
      }

      final fullUrl = _buildFullUrl(source.bookSourceUrl, detailUrl);
      _log('🌐 详情页URL：$fullUrl');

      // 发起详情页请求
      _log('⏳ 正在获取详情页...');
      final response = await _httpGet(fullUrl);
      _log('📡 响应状态码：${response.statusCode}');

      if (response.statusCode == 200) {
        // 解析详情信息
        final detail = await _parseDetailInfo(response.body);
        _log('✅ 详情解析成功：');
        _log('  📚 书名：${detail['name'] ?? '未解析到'}');
        _log('  ✍️ 作者：${detail['author'] ?? '未解析到'}');
        final description = detail['description'] ?? '未解析到';
        _log(
          '  📝 简介：${description.length > 100 ? description.substring(0, 100) : description}...',
        );
        _log('  🏷️ 分类：${detail['category'] ?? '未解析到'}');

        // Step 3: 目录测试
        if (detail['chapterUrl'] != null) {
          await _debugChapter(source, detail['chapterUrl']!);
        } else {
          _log('⚠️ 未找到章节链接，跳过目录测试');
        }
      } else {
        _log('❌ 详情页请求失败：${response.reasonPhrase}');
      }
    } catch (e) {
      _log('❌ 详情测试失败：$e');
    }

    _log('');
  }

  /// Step 3: 目录规则调试
  Future<void> _debugChapter(BookSource source, String chapterUrl) async {
    _log('📋 Step 3: 目录规则测试');

    try {
      final fullUrl = _buildFullUrl(source.bookSourceUrl, chapterUrl);
      _log('🌐 目录页URL：$fullUrl');

      // 发起目录页请求
      _log('⏳ 正在获取目录页...');
      final response = await _httpGet(fullUrl);
      _log('📡 响应状态码：${response.statusCode}');

      if (response.statusCode == 200) {
        // 解析章节列表
        final chapters = await _parseChapterList(
          response.body,
          _encodeRuleJson(source.ruleToc?.toJson()),
        );
        _log('✅ 目录解析成功，共 ${chapters.length} 个章节');

        // 显示前5个章节
        final displayCount = chapters.length > 5 ? 5 : chapters.length;
        for (int i = 0; i < displayCount; i++) {
          final chapter = chapters[i];
          _log('  📄 章节${i + 1}：${chapter['name']}');
          _log('    🔗 链接：${chapter['url']}');
        }

        // Step 4: 正文测试
        if (chapters.isNotEmpty) {
          await _debugContent(source, chapters.first['url']!);
        }
      } else {
        _log('❌ 目录页请求失败：${response.reasonPhrase}');
      }
    } catch (e) {
      _log('❌ 目录测试失败：$e');
    }

    _log('');
  }

  /// Step 4: 正文规则调试
  Future<void> _debugContent(BookSource source, String contentUrl) async {
    _log('📋 Step 4: 正文规则测试');

    try {
      final fullUrl = _buildFullUrl(source.bookSourceUrl, contentUrl);
      _log('🌐 正文页URL：$fullUrl');

      // 发起正文页请求
      _log('⏳ 正在获取正文页...');
      final response = await _httpGet(fullUrl);
      _log('📡 响应状态码：${response.statusCode}');

      if (response.statusCode == 200) {
        // 解析正文内容
        final content = await _parseContent(
          response.body,
          _encodeRuleJson(source.ruleContent?.toJson()),
        );
        _log('✅ 正文解析成功');
        _log(
          '📄 正文内容前100字：${content.substring(0, content.length > 100 ? 100 : content.length)}...',
        );
        _log('📊 正文总长度：${content.length} 字符');
      } else {
        _log('❌ 正文页请求失败：${response.reasonPhrase}');
      }
    } catch (e) {
      _log('❌ 正文测试失败：$e');
    }

    _log('');
  }

  /// 执行搜索并返回结果
  Future<List<Map<String, String>>> _performSearch(
    BookSource source,
    String keyword,
  ) async {
    try {
      final searchRule = _parseSearchRule(source.ruleSearch);
      final searchUrl = _buildSearchUrl(
        source.bookSourceUrl,
        searchRule['searchUrl'] ?? '',
        keyword,
      );
      final response = await _httpGet(searchUrl);

      if (response.statusCode == 200) {
        return await _parseSearchResults(response.body, searchRule);
      }
    } catch (e) {
      _log('搜索执行失败：$e');
    }
    return [];
  }

  /// 解析搜索规则
  Map<String, dynamic> _parseSearchRule(SearchRule? rule) {
    try {
      final jsonString = _encodeRuleJson(rule?.toJson());
      if (jsonString.isEmpty) {
        throw const FormatException('empty rule');
      }
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      _log('⚠️ 搜索规则解析失败，使用默认规则：$e');
      return {
        'searchUrl': '/search?q={key}',
        'ruleList': 'class.book-item',
        'bookName': 'text',
        'bookAuthor': 'text',
        'bookUrl': 'href',
      };
    }
  }

  /// 构建搜索URL
  String _buildSearchUrl(String baseUrl, String searchUrl, String keyword) {
    final url = searchUrl.replaceAll('{key}', Uri.encodeComponent(keyword));
    return _buildFullUrl(baseUrl, url);
  }

  String _encodeRuleJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return '';
    }
    return jsonEncode(json);
  }

  /// 构建完整URL
  String _buildFullUrl(String baseUrl, String relativeUrl) {
    if (relativeUrl.startsWith('http://') ||
        relativeUrl.startsWith('https://')) {
      return relativeUrl;
    }

    final baseUri = Uri.parse(baseUrl);
    final uri = Uri.parse(relativeUrl);

    if (uri.hasScheme) {
      return relativeUrl;
    }

    return baseUri.resolve(relativeUrl).toString();
  }

  /// HTTP GET 请求
  Future<http.Response> _httpGet(String url) async {
    final headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    };

    return await http.get(Uri.parse(url), headers: headers).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('请求超时'),
        );
  }

  /// 解析搜索结果（模拟实现）
  Future<List<Map<String, String>>> _parseSearchResults(
    String html,
    Map<String, dynamic> rule,
  ) async {
    // TODO: 此处需集成 JS/XPath/Regex 解析引擎
    // 目前返回模拟数据
    _log('🔧 使用模拟解析器（需集成真实的 JS/XPath/Regex 解析引擎）');

    return [
      {
        'name': '模拟书籍1',
        'author': '模拟作者1',
        'url': '/book/12345',
        'description': '这是一本模拟的书籍描述',
      },
      {
        'name': '模拟书籍2',
        'author': '模拟作者2',
        'url': '/book/67890',
        'description': '这是另一本模拟的书籍描述',
      },
    ];
  }

  /// 解析详情信息（模拟实现）
  Future<Map<String, String?>> _parseDetailInfo(String html) async {
    // TODO: 此处需集成 JS/XPath/Regex 解析引擎
    _log('🔧 使用模拟解析器（需集成真实的 JS/XPath/Regex 解析引擎）');

    return {
      'name': '模拟书名',
      'author': '模拟作者',
      'description': '这是一本模拟的书籍详细描述，包含了更多的内容信息。',
      'category': '小说',
      'chapterUrl': '/book/12345/chapters',
    };
  }

  /// 解析章节列表（模拟实现）
  Future<List<Map<String, String>>> _parseChapterList(
    String html,
    String ruleJson,
  ) async {
    // TODO: 此处需集成 JS/XPath/Regex 解析引擎
    _log('🔧 使用模拟解析器（需集成真实的 JS/XPath/Regex 解析引擎）');

    return List.generate(
      20,
      (index) => {
        'name': '第${index + 1}章 模拟章节',
        'url': '/chapter/${index + 1}',
      },
    );
  }

  /// 解析正文内容（模拟实现）
  Future<String> _parseContent(String html, String ruleJson) async {
    // TODO: 此处需集成 JS/XPath/Regex 解析引擎
    _log('🔧 使用模拟解析器（需集成真实的 JS/XPath/Regex 解析引擎）');

    return '这是模拟的正文内容。在实际实现中，这里会根据规则解析出真实的章节正文内容。正文可能包含多个段落，每个段落都有丰富的内容，为读者提供沉浸式的阅读体验。这个模拟内容足够长，可以用来测试解析器的功能和性能。';
  }

  /// 输出日志
  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _logController.add('[$timestamp] $message');
  }

  /// 停止调试
  void stopDebug() {
    if (_isDebugging) {
      _isDebugging = false;
      _log('⏹️ 调试已停止');
    }
  }

  /// 清理资源
  void dispose() {
    _logController.close();
  }
}
