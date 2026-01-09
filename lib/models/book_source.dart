import 'dart:convert';

/// 书源数据模型
///
/// 完全兼容 Legado 3.0 标准格式的书源定义
/// 包含基础信息、高级配置和各类解析规则
class BookSource {
  /// 基础信息字段

  /// 书源唯一标识符（URL地址，包括 http/https）
  /// 在 Legado 中作为主键
  final String bookSourceUrl;

  /// 书源名称
  final String bookSourceName;

  /// 书源分组（多个分组用逗号分隔）
  final String? bookSourceGroup;

  /// 书源类型：0文本, 1音频, 2图片, 3文件
  final int bookSourceType;

  /// 详情页URL正则表达式
  final String? bookUrlPattern;

  /// 手动排序权重
  final int customOrder;

  /// 是否启用该书源
  final bool enabled;

  /// 是否启用发现功能
  final bool enabledExplore;

  /// 书源注释/说明
  final String? bookSourceComment;

  /// 高级配置字段

  /// JavaScript库
  final String? jsLib;

  /// 是否启用CookieJar自动保存cookie
  final bool? enabledCookieJar;

  /// 并发率限制
  final String? concurrentRate;

  /// 请求头配置（User-Agent等）
  final String? header;

  /// 登录地址
  final String? loginUrl;

  /// 登录UI配置
  final String? loginUi;

  /// 登录检测JavaScript
  final String? loginCheckJs;

  /// 封面解密JavaScript
  final String? coverDecodeJs;

  /// 自定义变量说明
  final String? variableComment;

  /// 最后更新时间（用于排序）
  final int lastUpdateTime;

  /// 响应时间（用于排序，毫秒）
  final int respondTime;

  /// 智能排序权重
  final int weight;

  /// 发现页地址
  final String? exploreUrl;

  /// 发现页筛选规则
  final String? exploreScreen;

  /// 搜索地址
  final String? searchUrl;

  /// 规则对象字段

  /// 搜索规则
  final SearchRule? ruleSearch;

  /// 发现规则
  final ExploreRule? ruleExplore;

  /// 书籍详情页规则
  final BookInfoRule? ruleBookInfo;

  /// 目录规则（Legado中叫 ruleToc 而不是 ruleChapter）
  final TocRule? ruleToc;

  /// 正文规则
  final ContentRule? ruleContent;

  const BookSource({
    required this.bookSourceUrl,
    required this.bookSourceName,
    this.bookSourceGroup,
    this.bookSourceType = 0,
    this.bookUrlPattern,
    this.customOrder = 0,
    this.enabled = true,
    this.enabledExplore = true,
    this.bookSourceComment,
    this.jsLib,
    this.enabledCookieJar = true,
    this.concurrentRate,
    this.header,
    this.loginUrl,
    this.loginUi,
    this.loginCheckJs,
    this.coverDecodeJs,
    this.variableComment,
    this.lastUpdateTime = 0,
    this.respondTime = 180000,
    this.weight = 0,
    this.exploreUrl,
    this.exploreScreen,
    this.searchUrl,
    this.ruleSearch,
    this.ruleExplore,
    this.ruleBookInfo,
    this.ruleToc,
    this.ruleContent,
  });

  /// 从 JSON Map 创建 BookSource 实例
  factory BookSource.fromJson(Map<String, dynamic> json) {
    return BookSource(
      bookSourceUrl: json['bookSourceUrl'] as String? ?? '',
      bookSourceName: json['bookSourceName'] as String? ?? '未命名书源',
      bookSourceGroup: json['bookSourceGroup'] as String?,
      bookSourceType: json['bookSourceType'] as int? ?? 0,
      bookUrlPattern: json['bookUrlPattern'] as String?,
      customOrder: json['customOrder'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      enabledExplore: json['enabledExplore'] as bool? ?? true,
      bookSourceComment: json['bookSourceComment'] as String?,
      jsLib: json['jsLib'] as String?,
      enabledCookieJar: json['enabledCookieJar'] as bool?,
      concurrentRate: json['concurrentRate'] as String?,
      header: json['header'] as String?,
      loginUrl: json['loginUrl'] as String?,
      loginUi: json['loginUi'] as String?,
      loginCheckJs: json['loginCheckJs'] as String?,
      coverDecodeJs: json['coverDecodeJs'] as String?,
      variableComment: json['variableComment'] as String?,
      lastUpdateTime: json['lastUpdateTime'] as int? ?? 0,
      respondTime: json['respondTime'] as int? ?? 180000,
      weight: json['weight'] as int? ?? 0,
      exploreUrl: json['exploreUrl'] as String?,
      exploreScreen: json['exploreScreen'] as String?,
      searchUrl: json['searchUrl'] as String?,
      ruleSearch: json['ruleSearch'] != null
          ? SearchRule.fromJson(json['ruleSearch'] as Map<String, dynamic>)
          : null,
      ruleExplore: json['ruleExplore'] != null
          ? ExploreRule.fromJson(json['ruleExplore'] as Map<String, dynamic>)
          : null,
      ruleBookInfo: json['ruleBookInfo'] != null
          ? BookInfoRule.fromJson(json['ruleBookInfo'] as Map<String, dynamic>)
          : null,
      ruleToc: json['ruleToc'] != null
          ? TocRule.fromJson(json['ruleToc'] as Map<String, dynamic>)
          : null,
      ruleContent: json['ruleContent'] != null
          ? ContentRule.fromJson(json['ruleContent'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 从 JSON 字符串创建 BookSource 实例
  factory BookSource.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return BookSource.fromJson(json);
  }

  /// 将 BookSource 实例转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'bookSourceUrl': bookSourceUrl,
      'bookSourceName': bookSourceName,
      'bookSourceGroup': bookSourceGroup,
      'bookSourceType': bookSourceType,
      'bookUrlPattern': bookUrlPattern,
      'customOrder': customOrder,
      'enabled': enabled,
      'enabledExplore': enabledExplore,
      'bookSourceComment': bookSourceComment,
      'jsLib': jsLib,
      'enabledCookieJar': enabledCookieJar,
      'concurrentRate': concurrentRate,
      'header': header,
      'loginUrl': loginUrl,
      'loginUi': loginUi,
      'loginCheckJs': loginCheckJs,
      'coverDecodeJs': coverDecodeJs,
      'variableComment': variableComment,
      'lastUpdateTime': lastUpdateTime,
      'respondTime': respondTime,
      'weight': weight,
      'exploreUrl': exploreUrl,
      'exploreScreen': exploreScreen,
      'searchUrl': searchUrl,
      'ruleSearch': ruleSearch?.toJson(),
      'ruleExplore': ruleExplore?.toJson(),
      'ruleBookInfo': ruleBookInfo?.toJson(),
      'ruleToc': ruleToc?.toJson(),
      'ruleContent': ruleContent?.toJson(),
    };
  }

  /// 将 BookSource 实例转换为 JSON 字符串
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// 创建一个带有更新字段的新 BookSource 实例
  BookSource copyWith({
    String? bookSourceUrl,
    String? bookSourceName,
    String? bookSourceGroup,
    int? bookSourceType,
    String? bookUrlPattern,
    int? customOrder,
    bool? enabled,
    bool? enabledExplore,
    String? bookSourceComment,
    String? jsLib,
    bool? enabledCookieJar,
    String? concurrentRate,
    String? header,
    String? loginUrl,
    String? loginUi,
    String? loginCheckJs,
    String? coverDecodeJs,
    String? variableComment,
    int? lastUpdateTime,
    int? respondTime,
    int? weight,
    String? exploreUrl,
    String? exploreScreen,
    String? searchUrl,
    SearchRule? ruleSearch,
    ExploreRule? ruleExplore,
    BookInfoRule? ruleBookInfo,
    TocRule? ruleToc,
    ContentRule? ruleContent,
  }) {
    return BookSource(
      bookSourceUrl: bookSourceUrl ?? this.bookSourceUrl,
      bookSourceName: bookSourceName ?? this.bookSourceName,
      bookSourceGroup: bookSourceGroup ?? this.bookSourceGroup,
      bookSourceType: bookSourceType ?? this.bookSourceType,
      bookUrlPattern: bookUrlPattern ?? this.bookUrlPattern,
      customOrder: customOrder ?? this.customOrder,
      enabled: enabled ?? this.enabled,
      enabledExplore: enabledExplore ?? this.enabledExplore,
      bookSourceComment: bookSourceComment ?? this.bookSourceComment,
      jsLib: jsLib ?? this.jsLib,
      enabledCookieJar: enabledCookieJar ?? this.enabledCookieJar,
      concurrentRate: concurrentRate ?? this.concurrentRate,
      header: header ?? this.header,
      loginUrl: loginUrl ?? this.loginUrl,
      loginUi: loginUi ?? this.loginUi,
      loginCheckJs: loginCheckJs ?? this.loginCheckJs,
      coverDecodeJs: coverDecodeJs ?? this.coverDecodeJs,
      variableComment: variableComment ?? this.variableComment,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      respondTime: respondTime ?? this.respondTime,
      weight: weight ?? this.weight,
      exploreUrl: exploreUrl ?? this.exploreUrl,
      exploreScreen: exploreScreen ?? this.exploreScreen,
      searchUrl: searchUrl ?? this.searchUrl,
      ruleSearch: ruleSearch ?? this.ruleSearch,
      ruleExplore: ruleExplore ?? this.ruleExplore,
      ruleBookInfo: ruleBookInfo ?? this.ruleBookInfo,
      ruleToc: ruleToc ?? this.ruleToc,
      ruleContent: ruleContent ?? this.ruleContent,
    );
  }

  /// 获取显示名称（包含分组信息）
  String getDisplayName() {
    if (bookSourceGroup == null || bookSourceGroup!.isEmpty) {
      return bookSourceName;
    }
    return '$bookSourceName ($bookSourceGroup)';
  }

  /// 检查是否包含指定分组
  bool hasGroup(String group) {
    if (bookSourceGroup == null || bookSourceGroup!.isEmpty) {
      return false;
    }
    final groups = bookSourceGroup!.split(',').map((g) => g.trim()).toList();
    return groups.contains(group);
  }

  /// 添加分组
  BookSource addGroup(String groups) {
    final currentGroups =
        bookSourceGroup?.split(',')?.map((g) => g.trim())?.toList() ?? [];
    final newGroups = groups.split(',').map((g) => g.trim()).toList();
    final allGroups = {...currentGroups, ...newGroups}.toList();
    return copyWith(bookSourceGroup: allGroups.join(','));
  }

  /// 移除分组
  BookSource removeGroup(String groups) {
    if (bookSourceGroup == null || bookSourceGroup!.isEmpty) {
      return this;
    }
    final currentGroups =
        bookSourceGroup!.split(',').map((g) => g.trim()).toList();
    final removeGroups = groups.split(',').map((g) => g.trim()).toSet();
    final remainingGroups =
        currentGroups.where((g) => !removeGroups.contains(g)).toList();
    return copyWith(bookSourceGroup: remainingGroups.join(','));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookSource && other.bookSourceUrl == bookSourceUrl;
  }

  @override
  int get hashCode => bookSourceUrl.hashCode;

  @override
  String toString() {
    return 'BookSource(bookSourceUrl: $bookSourceUrl, bookSourceName: $bookSourceName, enabled: $enabled)';
  }

  /// 创建默认的演示书源
  static BookSource createDemoSource() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return BookSource(
      bookSourceUrl: 'https://www.example.com',
      bookSourceName: '演示书源',
      bookSourceGroup: '演示',
      enabled: true,
      lastUpdateTime: now,
      searchUrl: '/search?key={key}',
      ruleSearch: SearchRule(
        bookList: 'class.book-item@tag.li',
        name: 'text',
        author: 'class.author@text',
        bookUrl: 'tag.a@href',
      ),
      ruleBookInfo: BookInfoRule(
        name: 'text',
        author: 'class.author@text',
        intro: 'class.intro@text',
        kind: 'class.category@text',
        tocUrl: 'class.chapter@href',
        coverUrl: 'class.cover@src',
      ),
      ruleToc: TocRule(
        chapterList: 'class.chapter@tag.a',
        chapterName: 'text',
        chapterUrl: 'href',
      ),
      ruleContent: ContentRule(
        content: 'id.content@textNodes',
        title: 'class.chapter-title@text',
      ),
    );
  }
}

/// 书籍列表规则基类
abstract class BookListRule {
  final String? bookList;
  final String? name;
  final String? author;
  final String? intro;
  final String? kind;
  final String? lastChapter;
  final String? updateTime;
  final String? bookUrl;
  final String? coverUrl;
  final String? wordCount;

  const BookListRule({
    this.bookList,
    this.name,
    this.author,
    this.intro,
    this.kind,
    this.lastChapter,
    this.updateTime,
    this.bookUrl,
    this.coverUrl,
    this.wordCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookList': bookList,
      'name': name,
      'author': author,
      'intro': intro,
      'kind': kind,
      'lastChapter': lastChapter,
      'updateTime': updateTime,
      'bookUrl': bookUrl,
      'coverUrl': coverUrl,
      'wordCount': wordCount,
    };
  }
}

/// 搜索规则
class SearchRule extends BookListRule {
  final String? checkKeyWord;

  const SearchRule({
    this.checkKeyWord,
    super.bookList,
    super.name,
    super.author,
    super.intro,
    super.kind,
    super.lastChapter,
    super.updateTime,
    super.bookUrl,
    super.coverUrl,
    super.wordCount,
  });

  factory SearchRule.fromJson(Map<String, dynamic> json) {
    return SearchRule(
      checkKeyWord: json['checkKeyWord'] as String?,
      bookList: json['bookList'] as String?,
      name: json['name'] as String?,
      author: json['author'] as String?,
      intro: json['intro'] as String?,
      kind: json['kind'] as String?,
      lastChapter: json['lastChapter'] as String?,
      updateTime: json['updateTime'] as String?,
      bookUrl: json['bookUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      wordCount: json['wordCount'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['checkKeyWord'] = checkKeyWord;
    return json;
  }
}

/// 发现规则
class ExploreRule extends BookListRule {
  const ExploreRule({
    super.bookList,
    super.name,
    super.author,
    super.intro,
    super.kind,
    super.lastChapter,
    super.updateTime,
    super.bookUrl,
    super.coverUrl,
    super.wordCount,
  });

  factory ExploreRule.fromJson(Map<String, dynamic> json) {
    return ExploreRule(
      bookList: json['bookList'] as String?,
      name: json['name'] as String?,
      author: json['author'] as String?,
      intro: json['intro'] as String?,
      kind: json['kind'] as String?,
      lastChapter: json['lastChapter'] as String?,
      updateTime: json['updateTime'] as String?,
      bookUrl: json['bookUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      wordCount: json['wordCount'] as String?,
    );
  }
}

/// 书籍详情页规则
class BookInfoRule {
  final String? init;
  final String? name;
  final String? author;
  final String? intro;
  final String? kind;
  final String? lastChapter;
  final String? updateTime;
  final String? coverUrl;
  final String? tocUrl;
  final String? wordCount;
  final String? canReName;
  final String? downloadUrls;

  const BookInfoRule({
    this.init,
    this.name,
    this.author,
    this.intro,
    this.kind,
    this.lastChapter,
    this.updateTime,
    this.coverUrl,
    this.tocUrl,
    this.wordCount,
    this.canReName,
    this.downloadUrls,
  });

  factory BookInfoRule.fromJson(Map<String, dynamic> json) {
    return BookInfoRule(
      init: json['init'] as String?,
      name: json['name'] as String?,
      author: json['author'] as String?,
      intro: json['intro'] as String?,
      kind: json['kind'] as String?,
      lastChapter: json['lastChapter'] as String?,
      updateTime: json['updateTime'] as String?,
      coverUrl: json['coverUrl'] as String?,
      tocUrl: json['tocUrl'] as String?,
      wordCount: json['wordCount'] as String?,
      canReName: json['canReName'] as String?,
      downloadUrls: json['downloadUrls'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'init': init,
      'name': name,
      'author': author,
      'intro': intro,
      'kind': kind,
      'lastChapter': lastChapter,
      'updateTime': updateTime,
      'coverUrl': coverUrl,
      'tocUrl': tocUrl,
      'wordCount': wordCount,
      'canReName': canReName,
      'downloadUrls': downloadUrls,
    };
  }
}

/// 目录规则（Legado中叫 TocRule）
class TocRule {
  final String? preUpdateJs;
  final String? chapterList;
  final String? chapterName;
  final String? chapterUrl;
  final String? formatJs;
  final String? isVolume;
  final String? isVip;
  final String? isPay;
  final String? updateTime;
  final String? nextTocUrl;

  const TocRule({
    this.preUpdateJs,
    this.chapterList,
    this.chapterName,
    this.chapterUrl,
    this.formatJs,
    this.isVolume,
    this.isVip,
    this.isPay,
    this.updateTime,
    this.nextTocUrl,
  });

  factory TocRule.fromJson(Map<String, dynamic> json) {
    return TocRule(
      preUpdateJs: json['preUpdateJs'] as String?,
      chapterList: json['chapterList'] as String?,
      chapterName: json['chapterName'] as String?,
      chapterUrl: json['chapterUrl'] as String?,
      formatJs: json['formatJs'] as String?,
      isVolume: json['isVolume'] as String?,
      isVip: json['isVip'] as String?,
      isPay: json['isPay'] as String?,
      updateTime: json['updateTime'] as String?,
      nextTocUrl: json['nextTocUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preUpdateJs': preUpdateJs,
      'chapterList': chapterList,
      'chapterName': chapterName,
      'chapterUrl': chapterUrl,
      'formatJs': formatJs,
      'isVolume': isVolume,
      'isVip': isVip,
      'isPay': isPay,
      'updateTime': updateTime,
      'nextTocUrl': nextTocUrl,
    };
  }
}

/// 正文规则
class ContentRule {
  final String? content;
  final String? title;
  final String? nextContentUrl;
  final String? webJs;
  final String? sourceRegex;
  final String? replaceRegex;
  final String? imageStyle;
  final String? imageDecode;
  final String? payAction;

  const ContentRule({
    this.content,
    this.title,
    this.nextContentUrl,
    this.webJs,
    this.sourceRegex,
    this.replaceRegex,
    this.imageStyle,
    this.imageDecode,
    this.payAction,
  });

  factory ContentRule.fromJson(Map<String, dynamic> json) {
    return ContentRule(
      content: json['content'] as String?,
      title: json['title'] as String?,
      nextContentUrl: json['nextContentUrl'] as String?,
      webJs: json['webJs'] as String?,
      sourceRegex: json['sourceRegex'] as String?,
      replaceRegex: json['replaceRegex'] as String?,
      imageStyle: json['imageStyle'] as String?,
      imageDecode: json['imageDecode'] as String?,
      payAction: json['payAction'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'title': title,
      'nextContentUrl': nextContentUrl,
      'webJs': webJs,
      'sourceRegex': sourceRegex,
      'replaceRegex': replaceRegex,
      'imageStyle': imageStyle,
      'imageDecode': imageDecode,
      'payAction': payAction,
    };
  }
}
