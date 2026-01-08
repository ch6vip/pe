/// 章节数据模型
///
/// 用于表示小说的章节信息，包含章节标识和标题
class Chapter {
  /// 章节唯一标识符
  final String itemId;

  /// 章节标题
  final String title;

  /// 卷名（可选）
  final String? volumeName;

  /// 章节字数（可选）
  final int? wordNumber;

  const Chapter({
    required this.itemId,
    required this.title,
    this.volumeName,
    this.wordNumber,
  });

  /// 从 JSON Map 创建 Chapter 实例
  ///
  /// 预期的 JSON 格式：
  /// ```json
  /// {
  ///   "item_id": "123456",
  ///   "title": "第一章 开始"
  /// }
  /// ```
  factory Chapter.fromJson(Map<String, dynamic> json) {
    // 支持多种 ID 字段名
    final dynamic rawItemId =
        json['item_id'] ?? json['id'] ?? json['chapter_id'];

    // 支持多种标题字段名
    final String? title = json['title'] as String? ??
        json['chapter_name'] as String? ??
        json['name'] as String?;

    return Chapter(
      itemId: rawItemId?.toString() ?? '',
      title: title ?? '未知章节',
      volumeName: json['volume_name'] as String?,
      wordNumber: (json['chapter_word_number'] ?? json['word_count']) as int?,
    );
  }

  /// 将 Chapter 实例转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'title': title,
      if (volumeName != null) 'volume_name': volumeName,
      if (wordNumber != null) 'chapter_word_number': wordNumber,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chapter && other.itemId == itemId;
  }

  @override
  int get hashCode => itemId.hashCode;

  @override
  String toString() => 'Chapter(itemId: $itemId, title: $title)';
}
