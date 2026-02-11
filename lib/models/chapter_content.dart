/// Chapter content data model
///
/// Represents the actual content of a novel chapter, including title and body text
class ChapterContent {
  /// Chapter title
  final String title;

  /// Chapter body content (processed plain text)
  final String content;

  /// Chapter ID (optional)
  final String? itemId;

  /// HTML 段落起始标签正则（如 <p>, <p class="...">）
  static final RegExp _pTagStartPattern = RegExp(r'<p[^>]*>');

  /// HTML 段落结束标签正则
  static final RegExp _pTagEndPattern = RegExp(r'</p>');

  /// 所有 HTML 标签正则
  static final RegExp _allTagsPattern = RegExp(r'<[^>]*>');

  /// HTML article 标签正则
  static final RegExp _articlePattern = RegExp(
    r'<article>.*?</article>',
    dotAll: true,
  );

  const ChapterContent({
    required this.title,
    required this.content,
    this.itemId,
  });

  /// 从 JSON Map 创建 ChapterContent 实例
  ///
  /// 预期的 JSON 格式：
  /// ```json
  /// {
  ///   "data": {
  ///     "title": "第一章 开始",
  ///     "content": "<p>正文内容...</p>"
  ///   }
  /// }
  /// ```
  ///
  /// HTML 处理逻辑：
  /// 1. 提取 <article> 标签内容（如果存在）
  /// 2. 移除 <p> 起始标签
  /// 3. 将 </p> 替换为双换行符
  /// 4. 移除所有其他 HTML 标签
  /// 5. 清理首尾空白字符
  ///
  /// Throws:
  /// - [FormatException] 当 JSON 格式不正确或缺少必要字段时
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

  /// 处理 HTML 内容，移除标签并格式化换行
  ///
  /// 处理流程：
  /// 1. 提取 article 标签内的内容（如果存在）
  /// 2. 移除 <p> 起始标签
  /// 3. 将 </p> 结束标签替换为双换行
  /// 4. 移除其他所有 HTML 标签
  /// 5. 去除首尾空白
  static String _processHtmlContent(String rawContent) {
    // 先解码 Unicode 转义序列（如 \u003c -> <）
    String decodedContent = rawContent;

    // 提取 article 标签内的内容
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

  /// 将 ChapterContent 实例转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'data': {
        'title': title,
        'content': content,
        if (itemId != null) 'item_id': itemId,
      },
    };
  }

  /// 检查内容是否为空
  bool get isEmpty => content.isEmpty;

  /// 检查内容是否不为空
  bool get isNotEmpty => content.isNotEmpty;

  @override
  String toString() =>
      'ChapterContent(title: $title, contentLength: ${content.length})';
}
