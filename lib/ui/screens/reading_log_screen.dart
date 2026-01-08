import 'package:flutter/material.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/ui/screens/reader_screen.dart';
import 'package:reader_flutter/services/storage_service.dart';

/// 阅读日志页面
///
/// 显示用户的阅读历史记录和统计数据
/// 包括最近阅读的书籍、阅读时长统计等
class ReadingLogScreen extends StatefulWidget {
  const ReadingLogScreen({super.key});

  @override
  State<ReadingLogScreen> createState() => _ReadingLogScreenState();
}

class _ReadingLogScreenState extends State<ReadingLogScreen>
    with WidgetsBindingObserver {
  final StorageService _storageService = StorageService();

  /// 阅读记录列表
  List<Book> _readingHistory = [];

  /// 是否正在加载
  bool _isLoading = true;

  /// 错误信息
  String? _errorMessage;

  /// 统计数据
  ReadingStats _stats = ReadingStats.empty();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReadingData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 当应用从后台恢复时刷新数据
    if (state == AppLifecycleState.resumed) {
      _loadReadingData();
    }
  }

  /// 加载阅读数据
  Future<void> _loadReadingData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final books = await _storageService.getBookshelf();

      // 过滤出有阅读记录的书籍
      final readingHistory = books
          .where((book) =>
              book.lastReadTime != null && (book.lastReadTime ?? 0) > 0)
          .toList();

      // 按最近阅读时间排序
      readingHistory
          .sort((a, b) => (b.lastReadTime ?? 0).compareTo(a.lastReadTime ?? 0));

      // 计算统计数据
      final stats = _calculateStats(books, readingHistory);

      if (!mounted) return;

      setState(() {
        _readingHistory = readingHistory;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '加载阅读数据失败，请稍后重试';
        _isLoading = false;
      });
    }
  }

  /// 计算阅读统计数据
  ReadingStats _calculateStats(List<Book> allBooks, List<Book> readingHistory) {
    final totalBooks = allBooks.length;
    final readBooks = readingHistory.length;
    final thisWeekRead = readingHistory.where((book) {
      final readTime = book.lastReadTime ?? 0;
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      return DateTime.fromMillisecondsSinceEpoch(readTime).isAfter(weekAgo);
    }).length;

    return ReadingStats(
      totalBooks: totalBooks,
      readBooks: readBooks,
      thisWeekRead: thisWeekRead,
    );
  }

  /// 打开阅读器
  void _openReader(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReaderScreen(book: book)),
    ).then((_) {
      // 返回时刷新数据
      _loadReadingData();
    });
  }

  /// 格式化时间显示
  String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '未知';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('阅读日志'),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsSection(),
              const SizedBox(height: 20),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建统计区域
  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '阅读统计',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatItem(
                      '总藏书', '${_stats.totalBooks}', Icons.book_outlined)),
              const SizedBox(width: 20),
              Expanded(
                  child: _buildStatItem('已阅读', '${_stats.readBooks}',
                      Icons.check_circle_outline)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatItem(
                      '本周阅读', '${_stats.thisWeekRead}', Icons.trending_up)),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建主内容区域
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_readingHistory.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最近阅读',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildReadingHistoryList()),
      ],
    );
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReadingData,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            '还没有阅读记录',
            style: TextStyle(fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Text(
            '快去书架选择一本书开始阅读吧！',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// 构建阅读历史列表
  Widget _buildReadingHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadReadingData,
      child: ListView.builder(
        itemCount: _readingHistory.length,
        itemBuilder: (context, index) {
          final book = _readingHistory[index];
          return _ReadingHistoryItem(
            book: book,
            onTap: () => _openReader(book),
            timeText: _formatTime(book.lastReadTime),
          );
        },
      ),
    );
  }
}

/// 阅读统计数据
class ReadingStats {
  final int totalBooks;
  final int readBooks;
  final int thisWeekRead;

  const ReadingStats({
    required this.totalBooks,
    required this.readBooks,
    required this.thisWeekRead,
  });

  factory ReadingStats.empty() {
    return const ReadingStats(
      totalBooks: 0,
      readBooks: 0,
      thisWeekRead: 0,
    );
  }
}

/// 阅读历史列表项组件
class _ReadingHistoryItem extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final String timeText;

  const _ReadingHistoryItem({
    required this.book,
    required this.onTap,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 封面图片
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book.coverUrl,
                width: 60,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 书籍信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.lastReadChapterTitle ?? '尚未开始阅读',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 箭头图标
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
