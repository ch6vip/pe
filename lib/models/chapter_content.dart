/// Chapter content data model
///
/// Represents the actual content of a novel chapter, including title and body text
class ChapterContent {
  const ChapterContent({
    required this.title,
    required this.content,
    this.itemId,
  });

  /// Chapter title
  final String title;

  /// Chapter body content (processed plain text)
  final String content;

  /// Chapter ID (optional)
  final String? itemId;

  /// Regex for HTML paragraph start tags (e.g. <p>, <p class="...">).
  static final RegExp _pTagStartPattern = RegExp(r'<p[^>]*>');

  /// Regex for HTML paragraph end tags.
  static final RegExp _pTagEndPattern = RegExp(r'</p>');

  /// Regex for all HTML tags.
  static final RegExp _allTagsPattern = RegExp(r'<[^>]*>');

  /// Regex for HTML article tags.
  static final RegExp _articlePattern = RegExp(
    r'<article>.*?</article>',
    dotAll: true,
  );

  /// Create a ChapterContent instance from a JSON map
  ///
  /// Expected JSON format:
  /// ```json
  /// {
  ///   "data": {
  ///     "title": "Chapter 1: Begin",
  ///     "content": "<p>正文内容...</p>"
  ///   }
  /// }
  /// ```
  ///
  /// HTML processing steps:
  /// 1. Extract <article> tag content (if present)
  /// 2. Remove <p> start tags
  /// 3. Replace </p> end tags with double newlines
  /// 4. Remove all other HTML tags
  /// 5. Trim leading/trailing whitespace
  ///
  /// Throws:
  /// - [FormatException] when JSON format is invalid or required fields are missing.
  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'];

    if (data == null) {
      throw const FormatException('章节数据缺失：响应中缺少 data 字段');
    }

    if (data is! Map<String, dynamic>) {
      throw const FormatException('章节数据格式错误：data 字段格式不正确');
    }

    final dynamic rawContent = data['content'];
    if (rawContent == null) {
      throw const FormatException('章节内容缺失：响应中缺少 content 字段');
    }

    final String processedContent = _processHtmlContent(rawContent.toString());

    return ChapterContent(
      title: (data['title'] as String?) ?? '未知标题',
      content: processedContent,
      itemId: data['item_id']?.toString(),
    );
  }

  /// Process HTML content: remove tags and normalize line breaks.
  ///
  /// Steps:
  /// 1. Extract content inside <article> tags (if present)
  /// 2. Remove <p> start tags
  /// 3. Replace </p> end tags with double newlines
  /// 4. Remove all other HTML tags
  /// 5. Trim leading/trailing whitespace
  static String _processHtmlContent(String rawContent) {
    // Decode Unicode escape sequences first (e.g. \u003c -> <).
    String decodedContent = rawContent;

    // Extract content within article tags.
    final articleMatch = _articlePattern.firstMatch(decodedContent);
    if (articleMatch != null) {
      decodedContent = articleMatch.group(0)!;
    }

    return decodedContent
        .replaceAll(_pTagStartPattern, '')
        .replaceAll(_pTagEndPattern, '\n\n')
        .replaceAll(_allTagsPattern, '')
        .trim();
  }

  /// Convert ChapterContent instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'data': {
        'title': title,
        'content': content,
        if (itemId != null) 'item_id': itemId,
      },
    };
  }

  /// Whether the content is empty
  bool get isEmpty => content.isEmpty;

  /// Whether the content is not empty
  bool get isNotEmpty => content.isNotEmpty;

  @override
  String toString() =>
      'ChapterContent(title: $title, contentLength: ${content.length})';
}
