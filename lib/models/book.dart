import 'dart:convert';

class Book {
  final String id;
  final String name;
  final String author;
  final String coverUrl;
  final String description;
  final int? addTime; // Unix timestamp
  final int? lastReadTime; // Unix timestamp
  final String? lastReadChapterTitle;

  Book({
    required this.id,
    required this.name,
    required this.author,
    required this.coverUrl,
    required this.description,
    this.addTime,
    this.lastReadTime,
    this.lastReadChapterTitle,
  });

  // A factory constructor for creating a new Book instance from a map.
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: (json['book_id'] ?? json['bookId'] ?? json['id'] ?? '').toString(),
      name: json['book_name'] ?? json['name'] ?? '未知书名',
      author: json['author'] ?? '未知作者',
      coverUrl: json['thumb_url'] ?? json['cover_url'] ?? json['coverUrl'] ?? 'https://p3-novel.byteimg.com/origin/novel-cover/0f5032c8338ecbe9173b620a934755a5',
      description: json['abstract'] ?? json['description'] ?? '暂无简介',
      addTime: json['addTime'],
      lastReadTime: json['lastReadTime'],
      lastReadChapterTitle: json['lastReadChapterTitle'],
    );
  }

  // Method to convert a Book instance to a map.
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

  Book copyWith({
    int? lastReadTime,
    String? lastReadChapterTitle,
  }) {
    return Book(
      id: id,
      name: name,
      author: author,
      coverUrl: coverUrl,
      description: description,
      addTime: addTime,
      lastReadTime: lastReadTime ?? this.lastReadTime,
      lastReadChapterTitle: lastReadChapterTitle ?? this.lastReadChapterTitle,
    );
  }
}
