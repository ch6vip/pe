import 'package:flutter/material.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/ui/screens/reader_screen.dart';
import 'package:reader_flutter/services/storage_service.dart';

/// Bookshelf screen
///
/// Displays user's book collection with sorting by last read time or add time
class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final StorageService _storageService = StorageService();

  /// 原始书籍列表
  List<Book> _books = [];

  /// 排序后的书籍列表
  List<Book> _sortedBooks = [];

  /// 当前排序方式
  SortOrder _sortOrder = SortOrder.byReadTime;

  /// 是否正在加载
  bool _isLoading = true;

  /// 错误信息
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 监听应用生命周期，从后台恢复时刷新书架
    WidgetsBinding.instance.addObserver(this);
    _loadBookshelf();
  }

  @override
  void dispose() {
    // 移除生命周期监听
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 当应用从后台恢复时刷新书架
    if (state == AppLifecycleState.resumed) {
      _loadBookshelf();
    }
  }

  /// 加载书架数据
  Future<void> _loadBookshelf() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sortOrder = await _storageService.getSortOrder();
      final books = await _storageService.getBookshelf();

      if (!mounted) return;

      setState(() {
        _sortOrder = sortOrder;
        _books = books;
        _sortBooks();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '加载书架失败，请稍后重试';
        _isLoading = false;
      });
    }
  }

  /// 对书籍进行排序
  ///
  /// 根据 [SortOrder] 对书籍列表进行排序，支持：
  /// - [SortOrder.byReadTime]: 按最近阅读时间降序
  /// - [SortOrder.byAddTime]: 按添加时间降序
  void _sortBooks() {
    final books = List<Book>.from(_books);

    switch (_sortOrder) {
      case SortOrder.byReadTime:
        // 最近阅读的在前面，未阅读的排在后面
        books.sort(
          (a, b) => (b.lastReadTime ?? 0).compareTo(a.lastReadTime ?? 0),
        );
      case SortOrder.byAddTime:
        // 最近添加的在前面
        books.sort((a, b) => (b.addTime ?? 0).compareTo(a.addTime ?? 0));
    }

    _sortedBooks = books;
  }

  /// 设置排序方式
  Future<void> _setSortOrder(SortOrder order) async {
    if (order == _sortOrder) return;

    await _storageService.saveSortOrder(order);

    setState(() {
      _sortOrder = order;
      _sortBooks();
    });
  }

  /// 处理长按删除书籍
  Future<void> _handleLongPress(Book book) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除书籍'),
        content: Text('确定要从书架移除《${book.name}》吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _storageService.removeBookFromShelf(book.id);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已移除《${book.name}》'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: '撤销',
              onPressed: () async {
                await _storageService.addBookToShelf(book);
                _loadBookshelf();
              },
            ),
          ),
        );

        _loadBookshelf();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('移除失败，请稍后重试')));
      }
    }
  }

  /// 打开阅读器
  void _openReader(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReaderScreen(book: book)),
    ).then((_) {
      // 返回时刷新书架以更新阅读进度
      _loadBookshelf();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 用于 AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSortControls(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建页面标题
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        '我的书架',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 构建排序控制按钮
  Widget _buildSortControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          _SortButton(
            text: '最近阅读',
            isActive: _sortOrder == SortOrder.byReadTime,
            onTap: () => _setSortOrder(SortOrder.byReadTime),
          ),
          const SizedBox(width: 10),
          _SortButton(
            text: '最近添加',
            isActive: _sortOrder == SortOrder.byAddTime,
            onTap: () => _setSortOrder(SortOrder.byAddTime),
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

    if (_sortedBooks.isEmpty) {
      return _buildEmptyState();
    }

    return _buildBookshelfGrid();
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
          ElevatedButton(onPressed: _loadBookshelf, child: const Text('重试')),
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
          Icon(Icons.book_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            '书架空空如也',
            style: TextStyle(fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Text(
            '快去"搜索"页面发现好书吧！',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// 构建书架网格
  Widget _buildBookshelfGrid() {
    return RefreshIndicator(
      onRefresh: _loadBookshelf,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 15,
          mainAxisSpacing: 25,
          childAspectRatio: 3 / 5.5,
        ),
        itemCount: _sortedBooks.length,
        itemBuilder: (context, index) {
          final book = _sortedBooks[index];
          return _BookGridItem(
            book: book,
            onTap: () => _openReader(book),
            onLongPress: () => _handleLongPress(book),
          );
        },
      ),
    );
  }
}

/// 排序按钮组件
class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  final String text;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// 书籍网格项组件
class _BookGridItem extends StatelessWidget {
  const _BookGridItem({
    required this.book,
    required this.onTap,
    required this.onLongPress,
  });

  final Book book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面图片
          Expanded(
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  book.coverUrl,
                  fit: BoxFit.cover,
                  // 启用内存缓存，避免重复下载
                  cacheWidth: 300, // 限制缓存图片宽度，减少内存占用
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 书名
          Text(
            book.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          // 阅读进度
          Text(
            book.lastReadChapterTitle ?? '尚未阅读',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
