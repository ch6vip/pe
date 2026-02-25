/// Chapter data model
///
/// Represents chapter information for a novel, including ID and title
class Chapter {
  const Chapter({
    required this.itemId,
    required this.title,
    this.volumeName,
    this.wordNumber,
  });

  /// Unique chapter identifier
  final String itemId;

  /// Chapter title
  final String title;

  /// Volume name (optional)
  final String? volumeName;

  /// Word count (optional)
  final int? wordNumber;

  /// Create a Chapter instance from a JSON map
  ///
  /// Expected JSON format:
  /// ```json
  /// {
  ///   "item_id": "123456",
  ///   "title": "Chapter 1: Begin"
  /// }
  /// ```
  ///
  /// Supports multiple field name variants for better compatibility:
  /// - ID: item_id, id, chapter_id
  /// - Title: title, chapter_name, name
  /// - Volume name: volume_name
  /// - Word count: chapter_word_number, word_number, word_count
  factory Chapter.fromJson(Map<String, dynamic> json) {
    try {
      // Support multiple ID field names for better type safety.
      final dynamic rawItemId =
          json['item_id'] ?? json['id'] ?? json['chapter_id'];

      // Safely convert itemId.
      final String itemId = rawItemId?.toString() ?? '';
      if (itemId.isEmpty) {
        throw const FormatException('章节ID为空或无效');
      }

      // Support multiple title field names for better type safety.
      String? title;
      try {
        title = json['title'] as String? ??
            json['chapter_name'] as String? ??
            json['name'] as String?;
      } catch (e) {
        // If the title field exists but the type is wrong, try toString().
        final titleValue =
            json['title'] ?? json['chapter_name'] ?? json['name'];
        title = titleValue?.toString();
      }

      final finalTitle = title?.isNotEmpty == true ? title! : '未知章节';

      // Safely read volume name.
      String? volumeName;
      try {
        volumeName = json['volume_name'] as String?;
      } catch (e) {
        final volumeValue = json['volume_name'];
        volumeName = volumeValue?.toString();
      }

      // Safely convert word count, supporting String/Int types.
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
          // Try parsing after toString().
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
      // If parsing fails completely, return a minimal usable Chapter.
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

  /// Convert the Chapter instance to a JSON map
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
