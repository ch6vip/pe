import 'dart:convert';
import 'package:reader_flutter/models/book.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _bookshelfKey = 'bookshelf';
  static const _sortOrderKey = 'sortOrder';

  Future<List<Book>> getBookshelf() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookshelfJson = prefs.getStringList(_bookshelfKey) ?? [];
    return bookshelfJson
        .map((bookJson) => Book.fromJson(json.decode(bookJson)))
        .toList();
  }

  Future<void> saveBookshelf(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookshelfJson =
        books.map((book) => json.encode(book.toJson())).toList();
    await prefs.setStringList(_bookshelfKey, bookshelfJson);
  }

  Future<void> addBookToShelf(Book book) async {
    final List<Book> bookshelf = await getBookshelf();
    // Avoid duplicates
    if (!bookshelf.any((b) => b.id == book.id)) {
      // Add current timestamp
      final bookToAdd = Book(
        id: book.id,
        name: book.name,
        author: book.author,
        coverUrl: book.coverUrl,
        description: book.description,
        addTime: DateTime.now().millisecondsSinceEpoch,
      );
      bookshelf.add(bookToAdd);
      await saveBookshelf(bookshelf);
    }
  }

  Future<void> removeBookFromShelf(String bookId) async {
    final List<Book> bookshelf = await getBookshelf();
    bookshelf.removeWhere((book) => book.id == bookId);
    await saveBookshelf(bookshelf);
  }
  
  Future<String> getSortOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sortOrderKey) ?? 'byReadTime';
  }

  Future<void> saveSortOrder(String order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortOrderKey, order);
  }
}
