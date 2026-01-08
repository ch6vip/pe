import 'dart:math';

/// 书源数据模型
///
/// 用于表示小说书源的基本信息和规则配置
/// 参考 Legado 阅读书源格式设计
class BookSource {
  /// 书源唯一标识符（UUID 或自定义 ID）
  final String id;

  /// 书源名称
  final String name;

  /// 书源网站根地址
  final String baseUrl;

  /// 是否启用该书源
  final bool enabled;

  /// 搜索规则（JSON 字符串格式，包含搜索 URL、结果解析规则等）
  /// 示例格式：{"searchUrl": "/search?q={key}", "ruleList": "class.book@tag.li"}
  final String ruleSearch;

  /// 目录规则（JSON 字符串格式，包含章节列表解析规则）
  /// 示例格式：{"chapterList": "class.chapter@tag.a", "chapterName": "text"}
  final String ruleChapter;

  /// 正文规则（JSON 字符串格式，包含内容解析规则）
  /// 示例格式：{"content": "id.content@textNodes", "nextUrl": "id.nextBtn@href"}
  final String ruleContent;

  /// 书源图标 URL（可选）
  final String? iconUrl;

  /// 书源作者（可选）
  final String? author;

  /// 书源版本（可选）
  final String? version;

  /// 创建时间（Unix 时间戳，毫秒）
  final int? createTime;

  /// 更新时间（Unix 时间戳，毫秒）
  final int? updateTime;

  const BookSource({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.enabled = true,
    this.ruleSearch = '{}',
    this.ruleChapter = '{}',
    this.ruleContent = '{}',
    this.iconUrl,
    this.author,
    this.version,
    this.createTime,
    this.updateTime,
  });

  /// 从 JSON Map 创建 BookSource 实例
  factory BookSource.fromJson(Map<String, dynamic> json) {
    return BookSource(
      id: json['id'] as String? ?? generateId(),
      name: json['name'] as String? ?? '未命名书源',
      baseUrl: json['baseUrl'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      ruleSearch: json['ruleSearch'] as String? ?? '{}',
      ruleChapter: json['ruleChapter'] as String? ?? '{}',
      ruleContent: json['ruleContent'] as String? ?? '{}',
      iconUrl: json['iconUrl'] as String?,
      author: json['author'] as String?,
      version: json['version'] as String?,
      createTime: json['createTime'] as int?,
      updateTime: json['updateTime'] as int?,
    );
  }

  /// 将 BookSource 实例转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'enabled': enabled,
      'ruleSearch': ruleSearch,
      'ruleChapter': ruleChapter,
      'ruleContent': ruleContent,
      'iconUrl': iconUrl,
      'author': author,
      'version': version,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  /// 创建一个带有更新字段的新 BookSource 实例
  BookSource copyWith({
    String? id,
    String? name,
    String? baseUrl,
    bool? enabled,
    String? ruleSearch,
    String? ruleChapter,
    String? ruleContent,
    String? iconUrl,
    String? author,
    String? version,
    int? createTime,
    int? updateTime,
  }) {
    return BookSource(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      enabled: enabled ?? this.enabled,
      ruleSearch: ruleSearch ?? this.ruleSearch,
      ruleChapter: ruleChapter ?? this.ruleChapter,
      ruleContent: ruleContent ?? this.ruleContent,
      iconUrl: iconUrl ?? this.iconUrl,
      author: author ?? this.author,
      version: version ?? this.version,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
    );
  }

  /// 生成唯一 ID（基于时间戳和随机数）
  /// 公共方法，供外部调用
  static String generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_randomString(6)}';
  }

  /// 生成指定长度的随机字符串
  static String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final sb = StringBuffer();
    for (var i = 0; i < length; i++) {
      sb.write(chars[random.nextInt(chars.length)]);
    }
    return sb.toString();
  }

  /// 创建默认的演示书源
  static BookSource createDemoSource() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return BookSource(
      id: 'demo_source_${now % 100000}',
      name: '演示书源',
      baseUrl: 'https://example.com',
      enabled: true,
      ruleSearch:
          '{"searchUrl": "/search?q={key}", "ruleList": "class.book-item"}',
      ruleChapter:
          '{"chapterList": "class.chapter@tag.a", "chapterName": "text"}',
      ruleContent: '{"content": "id.content@textNodes"}',
      author: '系统',
      version: '1.0.0',
      createTime: now,
      updateTime: now,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookSource && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BookSource(id: $id, name: $name, baseUrl: $baseUrl, enabled: $enabled)';
}
