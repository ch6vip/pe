import 'package:flutter/material.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/ui/screens/detail_screen.dart';
import 'package:reader_flutter/ui/screens/results_screen.dart';
import 'package:reader_flutter/services/api_service.dart';
import 'package:reader_flutter/ui/widgets/ranking_card.dart';

/// 搜索页面
///
/// 作为应用首页，展示搜索功能和热门榜单
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  /// 推荐书籍
  Book? _featuredBook;

  /// 巅峰榜单
  List<Book> _topList = [];

  /// 出版榜单
  List<Book> _publishedList = [];

  /// 快速更新榜单
  List<Book> _fastUpdateList = [];

  /// 是否正在加载
  bool _isLoading = true;

  /// 错误信息
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 获取首页数据
  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.fetchHomePageData();

      if (!mounted) return;

      setState(() {
        _featuredBook = data['featuredBook']?.isNotEmpty == true
            ? data['featuredBook']!.first
            : null;
        _topList = data['topList'] ?? [];
        _publishedList = data['publishedList'] ?? [];
        _fastUpdateList = data['fastUpdateList'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '无法加载首页数据，请检查您的网络连接。';
        _isLoading = false;
      });
    }
  }

  /// 执行搜索
  void _performSearch() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入搜索内容'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 收起键盘
    _searchFocusNode.unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(query: query),
      ),
    );
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
    super.build(context); // 用于 AutomaticKeepAliveClientMixin

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 10.0,
                ),
                child: _buildSearchBar(),
              ),
            ),
            _buildContentSliver(),
          ],
        ),
      ),
    );
  }

  /// 构建 SliverAppBar
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: false,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeaderBackground(),
      ),
    );
  }

  /// 构建头部背景
  Widget _buildHeaderBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9E9EE), Color(0xFFF8F9FB)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PE阅读',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFF6A88), Color(0xFFFF9A8B)],
                ).createShader(bounds),
                child: const Text(
                  '纯粹体验',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '在海量小说中，为你精准捕捉那本心动之作。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                focusNode: _searchFocusNode,
                decoration: const InputDecoration(
                  hintText: '搜索书名或作者...',
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
              ),
            ),
            _buildSearchButton(),
          ],
        ),
      ),
    );
  }

  /// 构建搜索按钮
  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: _performSearch,
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
    );
  }

  /// 构建内容区域
  Widget _buildContentSliver() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(
        child: _buildErrorState(),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        if (_featuredBook != null) _buildFeaturedCard(_featuredBook!),
        _buildSectionHeader(),
        if (_topList.isNotEmpty) RankingCard(title: '巅峰榜单', books: _topList),
        if (_publishedList.isNotEmpty)
          RankingCard(title: '出版榜单', books: _publishedList),
        if (_fastUpdateList.isNotEmpty)
          RankingCard(title: '爆更榜单', books: _fastUpdateList),
        const SizedBox(height: 30),
      ]),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchData,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建推荐书籍卡片
  Widget _buildFeaturedCard(Book book) {
    return GestureDetector(
      onTap: () => _goToBookDetail(book),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        elevation: 5,
        shadowColor: Colors.black.withAlpha(25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              // 封面
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book.coverUrl,
                  width: 80,
                  height: 106,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 106,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              // 书籍信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '爆更榜首',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 4),
                    // 作者
                    Text(
                      '作者：${book.author}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 简介
                    Text(
                      book.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建榜单区域标题
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '热门榜单',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: 实现查看更多功能
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '查看更多',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade600,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
