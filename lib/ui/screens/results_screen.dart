import 'package:flutter/material.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/services/api_service.dart';
import 'package:reader_flutter/ui/screens/detail_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String query;

  const ResultsScreen({super.key, required this.query});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ApiService _apiService = ApiService();
  List<Book> _searchResults = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchBooks();
  }

  Future<void> _searchBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await _apiService.searchBooks(widget.query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '搜索失败，请稍后再试。';
        _isLoading = false;
      });
    }
  }

  void _goToBookDetail(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('“${widget.query}”的搜索结果'),
        elevation: 0,
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.black87,
      ),
      backgroundColor: Colors.grey.shade100,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text('未找到相关书籍，请换个关键词试试。'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return _buildBookCard(book);
      },
    );
  }

  Widget _buildBookCard(Book book) {
    // Assuming creation_status '0' is completed, others are ongoing.
    final isCompleted = book.description.contains('完结'); // A simple heuristic

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _goToBookDetail(book),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(book.coverUrl, width: 54, height: 72, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(book.author, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text(
                          book.description, // Using description for meta as word count is not available
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? Colors.grey : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCompleted ? '已完结' : '连载中',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
