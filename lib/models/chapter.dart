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
  ///
  /// 支持多种字段名格式，增强数据兼容性：
  /// - ID: item_id, id, chapter_id
  /// - 标题: title, chapter_name, name
  /// - 卷名: volume_name
  /// - 字数: chapter_word_number, word_number, word_count
  factory Chapter.fromJson(Map<String, dynamic> json) {
    try {
      // 支持多种 ID 字段名，增强类型安全
      final dynamic rawItemId =
          json['item_id'] ?? json['id'] ?? json['chapter_id'];

      // 安全转换 itemId
      final String itemId = rawItemId?.toString() ?? '';
      if (itemId.isEmpty) {
        throw const FormatException('章节ID为空或无效');
      }

      // 支持多种标题字段名，增强类型安全
      String? title;
      try {
        title = json['title'] as String? ??
            json['chapter_name'] as String? ??
            json['name'] as String?;
      } catch (e) {
        // 如果标题字段存在但类型错误，尝试转换为字符串
        final titleValue =
            json['title'] ?? json['chapter_name'] ?? json['name'];
        title = titleValue?.toString();
      }

      final finalTitle = title?.isNotEmpty == true ? title! : '未知章节';

      // 安全获取卷名
      String? volumeName;
      try {
        volumeName = json['volume_name'] as String?;
      } catch (e) {
        final volumeValue = json['volume_name'];
        volumeName = volumeValue?.toString();
      }

      // 安全转换字数，支持 String/Int 类型
      int? wordNumber;
      final wordNumberValue = json['chapter_word_number'] ??
          json['word_number'] ??
          json['word_count'];
      if (wordNumberValue != null) {
        if (wordNumberValue is int) {
          wordNumber = wordNumberValue;
        } else if (wordNumberValue is String) {
          wordNumber = int.tryParse(wordNumberValue);
        } else {
          // 尝试通过 toString() 然后解析
          wordNumber = int.tryParse(wordNumberValue.toString());
        }
      }

      return Chapter(
        itemId: itemId,
        title: finalTitle,
        volumeName: volumeName,
        wordNumber: wordNumber,
      );
    } catch (e) {
      // 如果解析完全失败，返回一个最小可用的 Chapter 对象
      // 并记录原始数据以便调试
      final fallbackId = json['item_id']?.toString() ??
          json['id']?.toString() ??
          json['chapter_id']?.toString() ??
          'unknown_${DateTime.now().millisecondsSinceEpoch}';

      return Chapter(
        itemId: fallbackId,
        title: '解析失败章节',
        volumeName: null,
        wordNumber: null,
      );
    }
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
