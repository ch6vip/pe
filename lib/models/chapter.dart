/// 章节数据模型
///
/// 用于表示小说的章节信息，包含章节标识和标题
class Chapter {
  /// 章节唯一标识符
  final String itemId;

  /// 章节标题
  final String title;

  const Chapter({
    required this.itemId,
    required this.title,
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
    final dynamic rawItemId = json['item_id'];
    return Chapter(
      itemId: rawItemId?.toString() ?? '',
      title: (json['title'] as String?) ?? '未知章节',
    );
  }

  /// 将 Chapter 实例转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'title': title,
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
