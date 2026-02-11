import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/models/book_source.dart';
import 'package:reader_flutter/services/api_service.dart';
import 'package:reader_flutter/services/source_manager_service.dart';
import 'package:reader_flutter/ui/screens/detail_screen.dart';

/// 搜索结果页面
///
/// 显示搜索关键词匹配的书籍列表
class ResultsScreen extends StatefulWidget {
  /// 搜索关键词
  final String query;

  const ResultsScreen({super.key, required this.query});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ApiService _apiService = ApiService();

  /// 搜索结果列表
  List<Book> _searchResults = [];

  /// 是否正在加载
  bool _isLoading = true;

  /// 错误信息
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 页面加载时立即执行搜索
    _searchBooks();
  }

  /// 执行搜索
  Future<void> _searchBooks() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sourceService = context.read<SourceManagerService>();
      final enabledSources = sourceService.enabledSources;

      if (enabledSources.isEmpty) {
        if (!mounted) return;
        setState(() {
          _searchResults = [];
          _errorMessage = '未启用任何书源，请先在书源管理中启用';
          _isLoading = false;
        });
        return;
      }

      final results = await _searchAcrossSources(enabledSources);

      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '搜索失败，请检查网络后重试';
        _isLoading = false;
      });
    }
  }

  /// 跨多个书源搜索书籍
  ///
  /// 并发查询所有启用的书源，收集所有搜索结果
  /// 单个书源失败不影响其他书源的搜索
  Future<List<Book>> _searchAcrossSources(List<BookSource> sources) async {
    // 为每个书源创建搜索任务
    final tasks = sources.map(
      (source) => _apiService
          .searchBooks(source, widget.query)
          .catchError((_) => <Book>[], test: (_) => true), // 单个失败不影响整体
    );

    // 等待所有搜索任务完成
    final results = await Future.wait(tasks);

    // 合并所有搜索结果
    return results.expand((items) => items).toList();
  }

  /// 跳转到书籍详情
  void _goToBookDetail(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('"${widget.query}"的搜索结果'), elevation: 0),
      backgroundColor: Colors.grey.shade100,
      body: _buildBody(),
    );
  }

  /// 构建主体内容
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildResultsList();
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _searchBooks, child: const Text('重试')),
        ],
      ),
    );
  }

  /// 构建空结果状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            '未找到相关书籍',
            style: TextStyle(fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            '请换个关键词试试',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// 构建搜索结果列表
  Widget _buildResultsList() {
    return RefreshIndicator(
      onRefresh: _searchBooks,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          return _BookResultCard(
            book: _searchResults[index],
            onTap: () => _goToBookDetail(_searchResults[index]),
          );
        },
      ),
    );
  }
}

/// 书籍结果卡片组件
class _BookResultCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookResultCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 简单判断是否完结（基于简介内容）
    final isCompleted = book.description.contains('完结');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 书籍信息行
              _buildBookInfoRow(),
              const Divider(height: 24),
              // 状态行
              _buildStatusRow(isCompleted),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建书籍信息行
  Widget _buildBookInfoRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 封面
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            book.coverUrl,
            width: 54,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 54,
              height: 72,
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.image_not_supported,
                size: 24,
                color: Colors.grey,
              ),
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 54,
                height: 72,
                color: Colors.grey.shade100,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        // 文字信息
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 书名
              Text(
                book.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // 作者
              Text(
                book.author,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              // 简介
              Text(
                book.description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建状态行
  Widget _buildStatusRow(bool isCompleted) {
    return Row(
      children: [
        // 状态指示点
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? Colors.grey : Colors.green,
          ),
        ),
        const SizedBox(width: 6),
        // 状态文字
        Text(
          isCompleted ? '已完结' : '连载中',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
