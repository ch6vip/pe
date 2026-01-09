import 'dart:async';

import '../models/book_source.dart';
import '../services/api_service.dart';
import '../utils/rule_parser.dart';

/// 书源调试服务
///
/// 提供书源规则的调试功能，通过 Stream 实时输出调试日志
class SourceDebugService {
  static const String _defaultSearchUrl = '/search?key={key}';
  static const SearchRule _defaultSearchRule = SearchRule(
    bookList: 'class.book-item@tag.li',
    name: 'text',
    author: 'class.author@text',
    intro: 'class.intro@text',
    bookUrl: 'tag.a@href',
  );
  static const BookInfoRule _defaultBookInfoRule = BookInfoRule(
    name: 'text',
    author: 'class.author@text',
    intro: 'class.intro@text',
    kind: 'class.category@text',
    tocUrl: 'class.chapter@href',
    coverUrl: 'class.cover@src',
  );
  static const TocRule _defaultTocRule = TocRule(
    chapterList: 'class.chapter@tag.a',
    chapterName: 'text',
    chapterUrl: 'href',
  );
  static const ContentRule _defaultContentRule = ContentRule(
    content: 'id.content@textNodes',
    title: 'class.chapter-title@text',
  );

  final StreamController<String> _logController =
      StreamController<String>.broadcast();
  final ApiService _apiService = ApiService();

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
      final searchUrl = source.searchUrl?.trim() ?? _defaultSearchUrl;
      final rule = _effectiveSearchRule(source.ruleSearch);

      _log(
        '📄 搜索规则：bookList=${rule.bookList ?? ''}, name=${rule.name ?? ''}, author=${rule.author ?? ''}, url=${rule.bookUrl ?? ''}',
      );

      // 构建搜索URL
      final requestUrl = _buildSearchUrl(
        source.bookSourceUrl,
        searchUrl,
        keyword,
      );
      _log('🌐 搜索URL：$requestUrl');

      // 发起请求
      _log('⏳ 正在发起搜索请求...');
      final response = await _apiService.fetchRaw(requestUrl);
      _log('📡 响应状态码：${response.statusCode}');

      if (response.statusCode == 200) {
        _log('✅ 请求成功，响应长度：${response.body.length} 字符');
        _log(
          '📝 响应内容前200字符：${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
        );

        // 解析搜索结果
        final results = await _parseSearchResults(response.body, rule);
        _log('📚 解析到 ${results.length} 个搜索结果');

        // 显示前3个结果
        final displayCount = results.length > 3 ? 3 : results.length;
        for (int i = 0; i < displayCount; i++) {
          final result = results[i];
          _log('  📖 结果${i + 1}：${result['name']} - ${result['author']}');
          _log('    🔗 详情链接：${result['url']}');
        }
      } else {
        _log('❌ 请求失败');
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
      final response = await _apiService.fetchRaw(fullUrl);
      _log('📡 响应状态码：${response.statusCode}');

      if (response.statusCode == 200) {
        // 解析详情信息
        final detail = await _parseDetailInfo(
          response.body,
          source.ruleBookInfo,
        );
        _log('✅ 详情解析成功：');
        _log('  📚 书名：${detail['name'] ?? '未解析到'}');
        _log('  ✍️ 作者：${detail['author'] ?? '未解析到'}');
        final description = detail['description'] ?? '未解析到';
        _log(
          '  📝 简介：${description.length > 100 ? description.substring(0, 100) : description}...',
        );
        _log('  🏷️ 分类：${detail['category'] ?? '未解析到'}');

        // Step 3: 目录测试
        if (detail['chapterUrl'] != null && detail['chapterUrl']!.isNotEmpty) {
          await _debugChapter(source, detail['chapterUrl']!);
        } else {
          _log('⚠️ 未找到章节链接，跳过目录测试');
        }
      } else {
        _log('❌ 详情页请求失败');
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
      final response = await _apiService.fetchRaw(fullUrl);
      _log('📡 响应状态码：${response.statusCode}');

      if (response.statusCode == 200) {
        // 解析章节列表
        final chapters = await _parseChapterList(
          response.body,
          source.ruleToc,
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
        _log('❌ 目录页请求失败');
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
      final response = await _apiService.fetchRaw(fullUrl);
      _log('📡 响应状态码：${response.statusCode}');

      if (response.statusCode == 200) {
        // 解析正文内容
        final content = await _parseContent(
          response.body,
          source.ruleContent,
        );
        if (content.isEmpty) {
          _log('⚠️ 正文解析为空');
          return;
        }
        _log('✅ 正文解析成功');
        _log(
          '📄 正文内容前100字：${content.substring(0, content.length > 100 ? 100 : content.length)}...',
        );
        _log('📊 正文总长度：${content.length} 字符');
      } else {
        _log('❌ 正文页请求失败');
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
      final searchUrl = source.searchUrl?.trim() ?? _defaultSearchUrl;
      final requestUrl = _buildSearchUrl(
        source.bookSourceUrl,
        searchUrl,
        keyword,
      );
      final response = await _apiService.fetchRaw(requestUrl);

      if (response.statusCode == 200) {
        return await _parseSearchResults(response.body, source.ruleSearch);
      }
    } catch (e) {
      _log('搜索执行失败：$e');
    }
    return [];
  }

  /// 构建搜索URL
  String _buildSearchUrl(String baseUrl, String searchUrl, String keyword) {
    final url = searchUrl.replaceAll('{key}', Uri.encodeComponent(keyword));
    return _buildFullUrl(baseUrl, url);
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

  SearchRule _effectiveSearchRule(SearchRule? rule) {
    return rule ?? _defaultSearchRule;
  }

  BookInfoRule _effectiveBookInfoRule(BookInfoRule? rule) {
    return rule ?? _defaultBookInfoRule;
  }

  TocRule _effectiveTocRule(TocRule? rule) {
    return rule ?? _defaultTocRule;
  }

  ContentRule _effectiveContentRule(ContentRule? rule) {
    return rule ?? _defaultContentRule;
  }

  /// 解析搜索结果
  Future<List<Map<String, String>>> _parseSearchResults(
    String raw,
    SearchRule? rule,
  ) async {
    final parser = RuleParser.from(raw);
    final effectiveRule = _effectiveSearchRule(rule);
    final items = parser.selectList(effectiveRule.bookList);
    final results = <Map<String, String>>[];

    for (final item in items) {
      final name =
          parser.selectString(effectiveRule.name, context: item).trim();
      final author =
          parser.selectString(effectiveRule.author, context: item).trim();
      final url =
          parser.selectString(effectiveRule.bookUrl, context: item).trim();
      final intro =
          parser.selectString(effectiveRule.intro, context: item).trim();

      if (name.isEmpty && author.isEmpty && url.isEmpty && intro.isEmpty) {
        continue;
      }

      results.add({
        'name': name,
        'author': author,
        'url': url,
        'description': intro,
      });
    }

    return results;
  }

  /// 解析详情信息
  Future<Map<String, String?>> _parseDetailInfo(
    String raw,
    BookInfoRule? rule,
  ) async {
    final parser = RuleParser.from(raw);
    final effectiveRule = _effectiveBookInfoRule(rule);

    return {
      'name': parser.selectString(effectiveRule.name),
      'author': parser.selectString(effectiveRule.author),
      'description': parser.selectString(effectiveRule.intro),
      'category': parser.selectString(effectiveRule.kind),
      'chapterUrl': parser.selectString(effectiveRule.tocUrl),
      'coverUrl': parser.selectString(effectiveRule.coverUrl),
    };
  }

  /// 解析章节列表
  Future<List<Map<String, String>>> _parseChapterList(
    String raw,
    TocRule? rule,
  ) async {
    final parser = RuleParser.from(raw);
    final effectiveRule = _effectiveTocRule(rule);
    final items = parser.selectList(effectiveRule.chapterList);
    final results = <Map<String, String>>[];

    for (final item in items) {
      final name =
          parser.selectString(effectiveRule.chapterName, context: item).trim();
      final url =
          parser.selectString(effectiveRule.chapterUrl, context: item).trim();
      if (name.isEmpty && url.isEmpty) {
        continue;
      }
      results.add({'name': name, 'url': url});
    }

    return results;
  }

  /// 解析正文内容
  Future<String> _parseContent(String raw, ContentRule? rule) async {
    final parser = RuleParser.from(raw);
    final effectiveRule = _effectiveContentRule(rule);
    return parser.selectString(effectiveRule.content).trim();
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
    _apiService.dispose();
    _logController.close();
  }
}
