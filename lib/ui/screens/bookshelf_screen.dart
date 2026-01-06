import 'package:flutter/material.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/ui/screens/reader_screen.dart';
import 'package:reader_flutter/services/storage_service.dart';

class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> with WidgetsBindingObserver {
  final StorageService _storageService = StorageService();
  List<Book> _books = [];
  List<Book> _sortedBooks = [];
  String _sortOrder = 'byReadTime';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBookshelf();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload bookshelf when app is resumed, similar to onShow()
    if (state == AppLifecycleState.resumed) {
      _loadBookshelf();
    }
  }

  Future<void> _loadBookshelf() async {
    setState(() {
      _isLoading = true;
    });
    final sortOrder = await _storageService.getSortOrder();
    final books = await _storageService.getBookshelf();
    setState(() {
      _sortOrder = sortOrder;
      _books = books;
      _sortBooks();
      _isLoading = false;
    });
  }

  void _sortBooks() {
    final books = [..._books];
    if (_sortOrder == 'byReadTime') {
      books.sort((a, b) => (b.lastReadTime ?? 0).compareTo(a.lastReadTime ?? 0));
    } else if (_sortOrder == 'byAddTime') {
      books.sort((a, b) => (b.addTime ?? 0).compareTo(a.addTime ?? 0));
    }
    _sortedBooks = books;
  }

  Future<void> _setSortOrder(String order) async {
    await _storageService.saveSortOrder(order);
    setState(() {
      _sortOrder = order;
      _sortBooks();
    });
  }

  Future<void> _handleLongPress(Book book) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: Text('确定要从书架移除《${book.name}》吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.removeBookFromShelf(book.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已移除'), duration: Duration(seconds: 1)),
      );
      _loadBookshelf(); // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _sortedBooks.isEmpty
                        ? _buildEmptyState()
                        : _buildBookshelfGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        '我的书架',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSortControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          _buildSortButton('byReadTime', '最近阅读'),
          const SizedBox(width: 10),
          _buildSortButton('byAddTime', '最近添加'),
        ],
      ),
    );
  }

  Widget _buildSortButton(String order, String text) {
    final bool isActive = _sortOrder == order;
    return GestureDetector(
      onTap: () => _setSortOrder(order),
      child: Container(
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Assuming you have added the empty.png to your assets folder
          // and declared it in pubspec.yaml
          Image.asset('assets/empty.png', width: 100, height: 100, errorBuilder: (c,e,s) => const Icon(Icons.image_not_supported, size: 100)),
          const SizedBox(height: 20),
          const Text('书架空空如也', style: TextStyle(fontSize: 18, color: Colors.black87)),
          const SizedBox(height: 10),
          Text('快去“搜索”页面发现好书吧！', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildBookshelfGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 25,
        childAspectRatio: 3 / 5.5, // Adjusted aspect ratio for more text space
      ),
      itemCount: _sortedBooks.length,
      itemBuilder: (context, index) {
        final book = _sortedBooks[index];
        return GestureDetector(
          onLongPress: () => _handleLongPress(book),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReaderScreen(book: book)),
            );
          },
          child: _buildBookItem(book),
        );
      },
    );
  }

  Widget _buildBookItem(Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              book.coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          book.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(
          book.lastReadChapterTitle ?? '尚未阅读',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
