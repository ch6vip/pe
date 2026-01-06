class Chapter {
  final String itemId;
  final String title;

  Chapter({
    required this.itemId,
    required this.title,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      itemId: (json['item_id'] ?? '').toString(),
      title: json['title'] ?? '未知章节',
    );
  }
}
