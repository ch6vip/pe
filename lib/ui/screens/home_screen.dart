import 'package:flutter/material.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/ui/screens/detail_screen.dart';
import 'package:reader_flutter/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Future<Map<String, List<Book>>>? _homePageData;

  @override
  void initState() {
    super.initState();
    _homePageData = _apiService.fetchHomePageData();
  }

  void _navigateToDetail(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // Match the background color
      body: FutureBuilder<Map<String, List<Book>>>(
        future: _homePageData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data found.'));
          }

          final data = snapshot.data!;
          final featuredBook = data['featuredBook']?.first;
          final topList = data['topList'] ?? [];
          final publishedList = data['publishedList'] ?? [];
          final fastUpdateList = data['fastUpdateList'] ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),
              SliverToBoxAdapter(
                child: _buildSearchBar(),
              ),
              if (featuredBook != null)
                SliverToBoxAdapter(
                  child: _buildFeaturedCard(featuredBook),
                ),
              SliverToBoxAdapter(
                child: _buildRankingSectionHeader(),
              ),
              SliverToBoxAdapter(
                child: _buildRankingLists(topList, publishedList, fastUpdateList),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // This container holds the slogan and the gradient background.
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20, // Status bar height + padding
        left: 20,
        right: 20,
        bottom: 45, // Extra padding at the bottom to make space for the overlapping search bar
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9E9EE), Color(0xFFF8F9FB)],
          stops: [0.0, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PE阅读',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 2),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFF6A88), Color(0xFFFF9A8B)],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: const Text(
              '纯粹体验',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white, // This color is masked by the shader.
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '在海量小说中，为你精准捕捉那本心动之作。',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    // This container has a negative top margin to overlap the header.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      transform: Matrix4.translationValues(0.0, -35.0, 0.0), // Pulls the search bar up
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 5,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 15.0),
                  child: Icon(Icons.search, color: Colors.grey),
                ),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '搜索书名或作者...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D4F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(Book book) {
    // This card is also pulled up to overlap the search bar's negative space.
    return GestureDetector(
      onTap: () => _navigateToDetail(book),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        // The featured card sits below the search bar, so we give it a negative margin
        // to reduce the space created by the search bar's own negative margin.
        transform: Matrix4.translationValues(0.0, -20.0, 0.0),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                spreadRadius: 5,
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Book Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  book.coverUrl,
                  width: 80,
                  height: 106,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                ),
              ),
              const SizedBox(width: 15),
              // Book Info
              Expanded(
                child: SizedBox(
                  height: 106, // Match image height
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '爆更榜首',
                                style: TextStyle(
                                  color: Color(0xFFFF4D4F),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            book.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Text(
                        '作者：${book.author}',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      Text(
                        book.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingLists(List<Book> topList, List<Book> publishedList, List<Book> fastUpdateList) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 30),
      child: Column(
        children: [
          if (topList.isNotEmpty) ...[
            _buildRankingCard('巅峰榜单', topList.take(3).toList()),
            const SizedBox(height: 15),
          ],
          if (publishedList.isNotEmpty) ...[
            _buildRankingCard('出版榜单', publishedList.take(4).toList()),
            const SizedBox(height: 15),
          ],
          if (fastUpdateList.isNotEmpty) ...[
            _buildRankingCard('爆更榜单', fastUpdateList),
          ],
        ],
      ),
    );
  }

  Widget _buildRankingCard(String title, List<Book> books) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          ...List.generate(
            books.length,
            (index) {
              final book = books[index];
              final isLast = index == books.length - 1;
              return InkWell(
                onTap: () => _navigateToDetail(book),
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 18.0),
                  child: _buildBookRow(book, index + 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookRow(Book book, int rank) {
    Color rankColor;
    Color rankTextColor = Colors.white;
    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFF4D4F);
        break;
      case 2:
        rankColor = const Color(0xFFFF7A45);
        break;
      case 3:
        rankColor = const Color(0xFFFFC53D);
        break;
      default:
        rankColor = const Color(0xFFE8E8E8);
        rankTextColor = const Color(0xFF999999);
    }

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            color: rankColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                color: rankTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                book.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                book.author,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15), // Adjusted padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '热门榜单',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          InkWell(
            onTap: () {}, // Placeholder for "See More"
            child: Row(
              children: [
                Text(
                  '查看更多',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[600], size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
