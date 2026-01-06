import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/models/chapter.dart';
import 'package:reader_flutter/models/chapter_content.dart';

class ApiService {
  // 快速更新 API (未在新的 API 文档中找到对应接口)
  static const String _fastUpdateApi =
      "https://api-lf.fanqiesdk.com/api/novel/channel/homepage/rank/rank_list/v2/?aid=13&limit=10&side_type=15&type=1";
  // 排行榜 API (未在新的 API 文档中找到对应接口)
  static const String _topListApi =
      "https://fanqienovel.com/api/author/misc/top_book_list/v1/?limit=10&offset=0";
  // 出版物 API (未在新的 API 文档中找到对应接口)
  static const String _publishedApi =
      "https://fanqienovel.com/api/node/publication/list?page_index=0&page_count=10";

  static const String _newApiBase = "http://api.ch6vip.com";
  // 搜索 API
  static const String _searchApiBase = "$_newApiBase/search";
  // 详情 API
  static const String _detailApi = "$_newApiBase/detail";
  // 章节列表 API
  static const String _chapterListApi = "$_newApiBase/catalog";
  // 章节内容 API
  static const String _chapterContentApi = "$_newApiBase/content";

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
      if (data['result'] != null)
        dataList = data['result'];
      else if (data['publication_list'] != null)
        dataList = data['publication_list'];
      else if (data['list'] != null)
        dataList = data['list'];
      else if (data['book_list'] != null)
        dataList = data['book_list'];
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
    final uri = Uri.parse(_chapterListApi)
        .replace(queryParameters: {'book_id': bookId});
    final response = await http.get(uri);
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
    final uri = Uri.parse(_chapterContentApi)
        .replace(queryParameters: {'item_id': itemId});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes));
      return ChapterContent.fromJson(body);
    }
    throw Exception('Failed to load chapter content');
  }

  Future<List<Book>> searchBooks(String query, {int page = 1}) async {
    // 新 API 使用 'query' 和 'offset'
    final params = {
      'query': query,
      'offset': (page > 0 ? page - 1 : 0).toString(), // offset 从 0 开始
    };
    final uri = Uri.parse(_searchApiBase).replace(queryParameters: params);

    try {
      final response = await http.get(uri);
      // 使用通用的 _extractData 方法来解析返回的数据
      return _extractData(response);
    } catch (e) {
      print("Error searching books: $e");
      rethrow;
    }
  }
}
