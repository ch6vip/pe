class ChapterContent {
  final String title;
  final String content;

  // 定义静态常量正则，避免重复创建
  static final _pTagStart = RegExp(r'<p[^>]*>');
  static final _pTagEnd = RegExp(r'</p>');
  static final _allTags = RegExp(r'<[^>]*>');

  ChapterContent({
    required this.title,
    required this.content,
  });

  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    // 假设外层已经判断过 json['data']
    final data = json['data'];

    if (data == null || data['content'] == null) {
      // 建议抛出异常，让 UI 层决定怎么显示
      throw Exception('Data missing');
    }

    String rawContent = data['content'] as String;
    
    // 更加健壮的处理方式
    String processedContent = rawContent
        .replaceAll(_pTagStart, '')      // 移除 <p> 或 <p class="...">
        .replaceAll(_pTagEnd, '\n\n')    // 替换结束标签为换行
        .replaceAll(_allTags, '')        // 移除其他所有标签
        .trim();

    return ChapterContent(
      title: data['title']?.toString() ?? '未知标题',
      content: processedContent,
    );
  }
}