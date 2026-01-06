import 'package:flutter/material.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/ui/screens/detail_screen.dart';
import 'package:reader_flutter/ui/screens/results_screen.dart';
import 'package:reader_flutter/services/api_service.dart';
import 'package:reader_flutter/ui/widgets/ranking_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  Book? _featuredBook;
  List<Book> _topList = [];
  List<Book> _publishedList = [];
  List<Book> _fastUpdateList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _apiService.fetchHomePageData();
      setState(() {
        _featuredBook = data['featuredBook']?.first;
        _topList = data['topList'] ?? [];
        _publishedList = data['publishedList'] ?? [];
        _fastUpdateList = data['fastUpdateList'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '无法加载首页数据，请检查您的网络连接。';
        _isLoading = false;
      });
    }
  }

  void _goToResults() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(query: query),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入搜索内容')),
      );
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF9E9EE), Color(0xFFF8F9FB)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      const Text('PE阅读', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      Text('纯粹体验', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.pink.shade300)),
                      const SizedBox(height: 10),
                      Text('在海量小说中，为你精准捕捉那本心动之作。', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              child: _buildSearchBar(),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            SliverFillRemaining(child: Center(child: Text(_errorMessage!)))
          else 
            _buildContent(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Icon(Icons.search, color: Colors.grey),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '搜索书名或作者...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _goToResults(),
              ),
            ),
            GestureDetector(
              onTap: _goToResults,
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.search, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          if (_featuredBook != null) _buildFeaturedCard(_featuredBook!),
          _buildSectionHeader(),
          RankingCard(title: '巅峰榜单', books: _topList),
          RankingCard(title: '出版榜单', books: _publishedList),
          RankingCard(title: '爆更榜单', books: _fastUpdateList),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(Book book) {
    return GestureDetector(
      onTap: () => _goToBookDetail(book),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(book.coverUrl, width: 80, height: 106, fit: BoxFit.cover),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('爆更榜首', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                    ),
                    const SizedBox(height: 6),
                    Text(book.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('作者：${book.author}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    Text(book.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('热门榜单', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () {}, // seeMore
            child: Row(
              children: [
                Text('查看更多', style: TextStyle(color: Colors.grey.shade600)),
                Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
