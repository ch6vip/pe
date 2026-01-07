/// 书籍数据模型
///
/// 用于表示小说的基本信息，包括标识、元数据和阅读状态
class Book {
  /// 书籍唯一标识符
  final String id;

  /// 书籍名称
  final String name;

  /// 作者名称
  final String author;

  /// 封面图片 URL
  final String coverUrl;

  /// 书籍简介
  final String description;

  /// 添加到书架的时间（Unix 时间戳，毫秒）
  final int? addTime;

  /// 最后阅读时间（Unix 时间戳，毫秒）
  final int? lastReadTime;

  /// 最后阅读的章节标题
  final String? lastReadChapterTitle;

  /// 默认封面图片 URL
  static const String _defaultCoverUrl =
      'https://p3-novel.byteimg.com/origin/novel-cover/0f5032c8338ecbe9173b620a934755a5';

  const Book({
    required this.id,
    required this.name,
    required this.author,
    required this.coverUrl,
    required this.description,
    this.addTime,
    this.lastReadTime,
    this.lastReadChapterTitle,
  });

  /// 从 JSON Map 创建 Book 实例
  ///
  /// 支持多种 API 返回格式的字段名映射：
  /// - `book_id`, `bookId`, `id` -> [id]
  /// - `book_name`, `name` -> [name]
  /// - `thumb_url`, `cover_url`, `coverUrl` -> [coverUrl]
  /// - `abstract`, `description` -> [description]
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: _parseId(json),
      name: _parseString(json, ['book_name', 'name'], '未知书名'),
      author: _parseString(json, ['author'], '未知作者'),
      coverUrl: _parseString(
          json, ['thumb_url', 'cover_url', 'coverUrl'], _defaultCoverUrl),
      description: _parseString(json, ['abstract', 'description'], '暂无简介'),
      addTime: json['addTime'] as int?,
      lastReadTime: json['lastReadTime'] as int?,
      lastReadChapterTitle: json['lastReadChapterTitle'] as String?,
    );
  }

  /// 解析书籍 ID，支持多个字段名
  static String _parseId(Map<String, dynamic> json) {
    final dynamic rawId = json['book_id'] ?? json['bookId'] ?? json['id'];
    return rawId?.toString() ?? '';
  }

  /// 从多个可能的字段名中解析字符串值
  static String _parseString(
    Map<String, dynamic> json,
    List<String> keys,
    String defaultValue,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value is String && value.isNotEmpty) {
        return value;
      }
    }
    return defaultValue;
  }

  /// 将 Book 实例转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'author': author,
      'coverUrl': coverUrl,
      'description': description,
      'addTime': addTime,
      'lastReadTime': lastReadTime,
      'lastReadChapterTitle': lastReadChapterTitle,
    };
  }

  /// 创建一个带有更新字段的新 Book 实例
  ///
  /// 支持更新所有可选字段，未指定的字段保持原值
  Book copyWith({
    String? id,
    String? name,
    String? author,
    String? coverUrl,
    String? description,
    int? addTime,
    int? lastReadTime,
    String? lastReadChapterTitle,
  }) {
    return Book(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      addTime: addTime ?? this.addTime,
      lastReadTime: lastReadTime ?? this.lastReadTime,
      lastReadChapterTitle: lastReadChapterTitle ?? this.lastReadChapterTitle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Book(id: $id, name: $name, author: $author)';
}
