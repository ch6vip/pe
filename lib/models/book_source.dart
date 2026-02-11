import 'dart:convert';

/// Book source data model
///
/// Fully compatible with the Legado 3.0 standard format for book sources.
/// Includes basic info, advanced settings, and parsing rules.
class BookSource {
  /// Basic info fields

  /// Unique book source identifier (URL, including http/https)
  /// Used as the primary key in Legado.
  final String bookSourceUrl;

  /// Book source name
  final String bookSourceName;

  /// Book source groups (comma-separated)
  final String? bookSourceGroup;

  /// Book source type: 0 text, 1 audio, 2 image, 3 file
  final int bookSourceType;

  /// Detail page URL regex
  final String? bookUrlPattern;

  /// Manual sort weight
  final int customOrder;

  /// Whether the book source is enabled
  final bool enabled;

  /// Whether explore/discovery is enabled
  final bool enabledExplore;

  /// Book source notes/description
  final String? bookSourceComment;

  /// Advanced settings fields

  /// JavaScript library
  final String? jsLib;

  /// Whether to enable CookieJar auto-save
  final bool? enabledCookieJar;

  /// Concurrency limit
  final String? concurrentRate;

  /// Request headers (User-Agent, etc.)
  final String? header;

  /// Login URL
  final String? loginUrl;

  /// Login UI config
  final String? loginUi;

  /// Login check JavaScript
  final String? loginCheckJs;

  /// Cover decode JavaScript
  final String? coverDecodeJs;

  /// Custom variable notes
  final String? variableComment;

  /// Last update time (for sorting)
  final int lastUpdateTime;

  /// Response time (for sorting, ms)
  final int respondTime;

  /// Smart sorting weight
  final int weight;

  /// Explore page URL
  final String? exploreUrl;

  /// Explore page filter rule
  final String? exploreScreen;

  /// Search URL
  final String? searchUrl;

  /// Rule object fields

  /// Search rule
  final SearchRule? ruleSearch;

  /// Explore rule
  final ExploreRule? ruleExplore;

  /// Book detail rule
  final BookInfoRule? ruleBookInfo;

  /// Table of contents rule (called ruleToc in Legado)
  final TocRule? ruleToc;

  /// Content rule
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

  /// Create a BookSource instance from a JSON map
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

  /// Create a BookSource instance from a JSON string
  factory BookSource.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return BookSource.fromJson(json);
  }

  /// Convert the BookSource instance to a JSON map
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

  /// Convert the BookSource instance to a JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create a new BookSource instance with updated fields
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

  /// Get display name (includes group info)
  String getDisplayName() {
    if (bookSourceGroup == null || bookSourceGroup!.isEmpty) {
      return bookSourceName;
    }
    return '$bookSourceName ($bookSourceGroup)';
  }

  /// Whether the source includes the given group
  bool hasGroup(String group) {
    if (bookSourceGroup == null || bookSourceGroup!.isEmpty) {
      return false;
    }
    final groups = bookSourceGroup!.split(',').map((g) => g.trim()).toList();
    return groups.contains(group);
  }

  /// Add groups
  BookSource addGroup(String groups) {
    final currentGroups =
        bookSourceGroup?.split(',')?.map((g) => g.trim())?.toList() ?? [];
    final newGroups = groups.split(',').map((g) => g.trim()).toList();
    final allGroups = {...currentGroups, ...newGroups}.toList();
    return copyWith(bookSourceGroup: allGroups.join(','));
  }

  /// Remove groups
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

  /// Create a default demo source
  ///
  /// Provides a full example source for demos and testing.
  /// Users can follow this structure to create their own sources.
  static BookSource createDemoSource() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return BookSource(
      bookSourceUrl: 'https://www.example.com',
      bookSourceName: '演示书源',
      bookSourceGroup: '演示',
      bookSourceType: 0,
      enabled: true,
      enabledExplore: true,
      lastUpdateTime: now,
      respondTime: 180000,
      weight: 0,
      searchUrl: '/search?key={key}',
      // Search rule configuration
      ruleSearch: SearchRule(
        bookList: 'class.book-item@tag.li',
        name: 'text',
        author: 'class.author@text',
        bookUrl: 'tag.a@href',
      ),
      // Book info rule configuration
      ruleBookInfo: BookInfoRule(
        name: 'text',
        author: 'class.author@text',
        intro: 'class.intro@text',
        kind: 'class.category@text',
        tocUrl: 'class.chapter@href',
        coverUrl: 'class.cover@src',
      ),
      // Table of contents rule configuration
      ruleToc: TocRule(
        chapterList: 'class.chapter@tag.a',
        chapterName: 'text',
        chapterUrl: 'href',
      ),
      // Content rule configuration
      ruleContent: ContentRule(
        content: 'id.content@textNodes',
        title: 'class.chapter-title@text',
      ),
    );
  }
}

/// Base class for book list rules
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

/// Search rule
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

/// Explore rule
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

/// Book detail rule
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

/// Table of contents rule (TocRule in Legado)
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

/// Content rule
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
