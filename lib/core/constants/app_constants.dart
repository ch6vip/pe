# 核心常量配置

class AppConstants {
  // 应用信息
  static const String appName = 'PE Reader';
  static const String version = '1.0.0';
  static const String userAgent = 'PE-Reader/1.0 (Flutter)';

  // API 配置
  static const Duration timeout = Duration(seconds: 15);
  static const int maxConnectionsPerHost = 6;

  // 缓存配置
  static const int maxCacheSizeBytes = 100 * 1024 * 1024; // 100 MB
  static const Duration cacheExpiry = Duration(days: 7);
  static const String cacheKeyBookshelf = 'bookshelf';
  static const String cacheKeySettings = 'settings';
  static const String cacheKeySources = 'sources';
  static const String cacheKeyReadingProgress = 'reading_progress';

  // 规则引擎
  static const bool enableRuleCache = true;
  static const int maxRuleCacheSize = 50;
  static const Duration ruleCacheExpiry = Duration(hours: 24);
  static const String ruleCacheKeyPrefix = 'rule_';

  // 书架
  static const int maxBookshelfSize = 1000;
  static const String defaultBookshelfSort = 'addedAt';
  static const List<String> bookshelfSortOptions = [
    'addedAt',    // 添加时间
    'title',      // 书名
    'author',     // 作者
    'lastRead',   // 最近阅读
  ];

  // 阅读器
  static const double defaultFontSize = 16.0;
  static const double minFontSize = 8.0;
  static const double maxFontSize = 36.0;
  static const List<double> fontSizes = [12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36];
  static const double defaultLineHeight = 1.6;
  static const double minLineHeight = 1.0;
  static const double maxLineHeight = 3.0;
  static const int defaultMargin = 16;
  static const int minMargin = 0;
  static const int maxMargin = 32;

  // 预加载
  static const int prefetchChaptersCount = 3;
  static const int prefetchPagesCount = 5;

  // Legado 协议
  static const String legadoSourceVersion = '1.0';
  static const String legadoApiPath = '/legado';
  static const Map<String, String> legadoRequiredFields = {
    'name': 'string',
    'baseUrl': 'string',
    'search': 'object',
    'bookDetail': 'object',
    'chapterList': 'object',
    'chapterContent': 'object',
  };

  // UI
  static const double defaultElevation = 4.0;
  static const double borderRadius = 8.0;
  static const double splashRadius = 24.0;

  // 网络
  static const List<String> defaultHeaders = {
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    'Accept-Encoding': 'gzip, deflate',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
  };

  // 调试
  static const bool enableDebugLog = bool.fromEnvironment('dart.vm.product') == false;
  static const int maxLogLength = 1000;
}
