import 'package:flutter/material.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/ui/screens/reader_screen.dart';
import 'package:reader_flutter/services/storage_service.dart';

class DetailScreen extends StatefulWidget {
  final Book book;

  const DetailScreen({super.key, required this.book});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final StorageService _storageService = StorageService();
  bool _isBookInShelf = false;
  late Book _detailedBook;

  @override
  void initState() {
    super.initState();
    _detailedBook = widget.book;
    _checkIfBookInShelf();
  }

  Future<void> _checkIfBookInShelf() async {
    final bookshelf = await _storageService.getBookshelf();
    if (mounted) {
      setState(() {
        _isBookInShelf = bookshelf.any((b) => b.id == _detailedBook.id);
      });
    }
  }

  Future<void> _toggleBookshelf() async {
    if (_isBookInShelf) {
      // In the original vue app, you can't remove from here. 
      // We will keep this behavior.
      return;
    }
    
    await _storageService.addBookToShelf(_detailedBook);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已加入书架'), duration: Duration(seconds: 1)),
    );
    _checkIfBookInShelf();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_detailedBook.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: Colors.white,
      body: _buildContent(),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 25),
          _buildAbstract(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _detailedBook.coverUrl,
            width: 100,
            height: 133,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: SizedBox(
            height: 133,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  _detailedBook.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '作者：${_detailedBook.author}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                // Placeholders, as this data is not in the current Book model
                const Text(
                  '暂无分类 · 0万字',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '连载中', // Placeholder
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAbstract() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '简介',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 10),
        Text(
          _detailedBook.description.isEmpty ? '暂无简介' : _detailedBook.description,
          style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.8),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.only(
        top: 15,
        left: 15,
        right: 15,
        bottom: 15 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _isBookInShelf ? null : _toggleBookshelf,
              style: TextButton.styleFrom(
                backgroundColor: _isBookInShelf ? Colors.grey.shade300 : const Color(0xFFF0F2F5),
                foregroundColor: _isBookInShelf ? Colors.grey.shade600 : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_isBookInShelf ? '已在书架' : '加入书架'),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReaderScreen(book: _detailedBook)),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('开始阅读'),
            ),
          ),
        ],
      ),
    );
  }
}
