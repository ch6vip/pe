import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/models/chapter.dart';
import 'package:reader_flutter/models/chapter_content.dart';

class ApiService {
  static const String _fastUpdateApi = "https://api-lf.fanqiesdk.com/api/novel/channel/homepage/rank/rank_list/v2/?aid=13&limit=10&side_type=15&type=1";
  static const String _topListApi = "https://fanqienovel.com/api/author/misc/top_book_list/v1/?limit=10&offset=0";
  static const String _publishedApi = "https://fanqienovel.com/api/node/publication/list?page_index=0&page_count=10";
  static const String _searchApiBase = "http://novelsdk.hhlqilongzhu.cn/fq/search.php";
  static const String _chapterListApi = "https://fanqienovel.com/api/novel/directory/list/v1/?book_id=";
  static const String _chapterContentApi = "https://novel.snssdk.com/api/novel/content/v1/?item_id=";

  Future<Map<String, List<Book>>> fetchHomePageData() async {
    try {
      final [fastRes, topRes, pubRes] = await Future.wait([
        http.get(Uri.parse(_fastUpdateApi)),
        http.get(Uri.parse(_topListApi)),
        http.get(Uri.parse(_publishedApi)),
      ]);

      final fastUpdateList = _extractData(fastRes);
      final topList = _extractData(topRes);
      final publishedList = _extractData(pubRes);

      return {
        'featuredBook': fastUpdateList.isNotEmpty ? [fastUpdateList.first] : [],
        'fastUpdateList': fastUpdateList,
        'topList': topList,
        'publishedList': publishedList,
      };
    } catch (e) {
      print("Error fetching home page data: $e");
      // In a real app, you'd want to handle this error more gracefully.
      rethrow;
    }
  }

  List<Book> _extractData(http.Response response) {
    if (response.statusCode != 200) {
      print('API call failed with status code: ${response.statusCode}');
      return [];
    }
    
    final body = json.decode(utf8.decode(response.bodyBytes));
    
    // This logic mimics the original JavaScript 'extractData' function.
    dynamic dataList;
    if (body['data'] != null) {
      final data = body['data'];
      if (data['result'] != null) dataList = data['result'];
      else if (data['publication_list'] != null) dataList = data['publication_list'];
      else if (data['list'] != null) dataList = data['list'];
      else if (data['book_list'] != null) dataList = data['book_list'];
      else if (data is List) dataList = data;
    } else if (body['book_list'] != null && body['book_list'] is List) {
      dataList = body['book_list'];
    } else if (body['list'] != null && body['list'] is List) {
      dataList = body['list'];
    }

    if (dataList is List) {
      return dataList.map((item) => Book.fromJson(item)).toList();
    }

    print('Unknown data structure: $body');
    return [];
  }

  Future<List<Chapter>> getChapterList(String bookId) async {
    final response = await http.get(Uri.parse('$_chapterListApi$bookId'));
    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes));
      if (body['data'] != null && body['data']['item_list'] is List) {
        final List<dynamic> itemList = body['data']['item_list'];
        return itemList.map((item) => Chapter.fromJson(item)).toList();
      }
    }
    throw Exception('Failed to load chapter list');
  }

  Future<ChapterContent> getChapterContent(String itemId) async {
    final response = await http.get(Uri.parse('$_chapterContentApi$itemId'));
    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes));
      return ChapterContent.fromJson(body);
    }
    throw Exception('Failed to load chapter content');
  }
  Future<List<Book>> searchBooks(String query, {int page = 1}) async {
    final params = {
      'name': query,
      'page': page.toString(),
      'tab_type': '3',
    };
    final uri = Uri.parse(_searchApiBase).replace(queryParameters: params);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        
        if (body != null && body['search_tabs'] is List) {
          List<Book> allBooks = [];
          for (var tab in body['search_tabs']) {
            if (tab['data'] is List) {
              final books = (tab['data'] as List).map((item) {
                final bookData = item['book_data'] != null && item['book_data'] is List && item['book_data'].isNotEmpty
                    ? item['book_data'][0]
                    : item;
                return bookData != null ? Book.fromJson(bookData) : null;
              }).where((b) => b != null && b.id.isNotEmpty).cast<Book>();
              allBooks.addAll(books);
            }
          }
          return allBooks;
        }
        return [];
      } else {
        throw Exception('Failed to search books with status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error searching books: $e");
      rethrow;
    }
  }
}
