import 'package:flutter/material.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/ui/screens/detail_screen.dart';

/// 排行榜卡片组件
///
/// 用于展示榜单列表，支持不同排名的样式区分
class RankingCard extends StatelessWidget {
  const RankingCard({
    super.key,
    required this.title,
    required this.books,
    this.maxItems = 10,
  });

  /// 榜单标题
  final String title;

  /// 书籍列表
  final List<Book> books;

  /// 最大显示数量
  final int maxItems;


  /// 排名颜色配置
  static const List<Color> _rankColors = [
    Colors.redAccent, // 第1名
    Colors.orange, // 第2名
    Colors.amber, // 第3名
  ];

  /// 跳转到书籍详情
  void _goToBookDetail(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayBooks = books.take(maxItems).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 7.5),
      elevation: 3,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // 书籍列表
            ...List.generate(displayBooks.length, (index) {
              final book = displayBooks[index];
              final isLast = index == displayBooks.length - 1;

              return _RankingItem(
                book: book,
                rank: index + 1,
                isLast: isLast,
                onTap: () => _goToBookDetail(context, book),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// 排行榜项目组件
class _RankingItem extends StatelessWidget {
  const _RankingItem({
    required this.book,
    required this.rank,
    required this.isLast,
    required this.onTap,
  });

  final Book book;
  final int rank;
  final bool isLast;
  final VoidCallback onTap;


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 18.0),
        child: Row(
          children: [
            // 排名徽章
            _buildRankBadge(),
            const SizedBox(width: 15),
            // 书籍信息
            Expanded(
              child: _buildBookInfo(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建排名徽章
  Widget _buildRankBadge() {
    final bool isTopThree = rank <= 3;
    final Color backgroundColor =
        isTopThree ? RankingCard._rankColors[rank - 1] : Colors.grey.shade300;
    final Color textColor = isTopThree ? Colors.white : Colors.grey.shade700;

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// 构建书籍信息
  Widget _buildBookInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 书名
        Text(
          book.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        // 作者
        Text(
          book.author,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
