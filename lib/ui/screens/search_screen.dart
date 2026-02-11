import 'package:flutter/material.dart';
import 'package:reader_flutter/ui/screens/results_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    // 释放资源，防止内存泄漏
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 执行搜索
  ///
  /// 验证搜索输入，收起键盘，然后导航到搜索结果页面
  void _performSearch() {
    final query = _searchController.text.trim();

    // 验证输入
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入搜索内容'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 收起键盘，提升用户体验
    _searchFocusNode.unfocus();

    // 导航到搜索结果页面
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResultsScreen(query: query)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 用于 AutomaticKeepAliveClientMixin

    return Scaffold(
      body: CustomScrollView(
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
          _buildSearchHint(),
        ],
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
      flexibleSpace: FlexibleSpaceBar(background: _buildHeaderBackground()),
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
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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

  /// 构建提示区域
  Widget _buildSearchHint() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '输入书名或作者开始搜索',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              '搜索结果会同时来自已启用的书源。',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
