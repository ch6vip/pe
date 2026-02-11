import 'package:flutter/material.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/ui/screens/reader_screen.dart';
import 'package:reader_flutter/services/storage_service.dart';

/// 书籍详情页面
///
/// 展示书籍的详细信息，提供加入书架和开始阅读功能
class DetailScreen extends StatefulWidget {
  /// 要展示的书籍
  final Book book;

  const DetailScreen({super.key, required this.book});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final StorageService _storageService = StorageService();

  /// 书籍是否已在书架中
  bool _isBookInShelf = false;

  /// 是否正在执行操作
  bool _isOperating = false;

  @override
  void initState() {
    super.initState();
    _checkIfBookInShelf();
  }

  /// 检查书籍是否已在书架中
  Future<void> _checkIfBookInShelf() async {
    final isInShelf = await _storageService.isBookInShelf(widget.book.id);

    if (mounted) {
      setState(() {
        _isBookInShelf = isInShelf;
      });
    }
  }

  /// 添加书籍到书架
  ///
  /// 防止重复添加，提供操作状态反馈
  /// 使用 finally 确保操作状态总是被重置
  Future<void> _addToBookshelf() async {
    // 防止重复操作
    if (_isBookInShelf || _isOperating) return;

    setState(() {
      _isOperating = true;
    });

    try {
      final success = await _storageService.addBookToShelf(widget.book);

      if (!mounted) return;

      if (success) {
        setState(() {
          _isBookInShelf = true;
        });

        _showSnackBar('已加入书架');
      } else {
        _showSnackBar('书籍已在书架中');
      }
    } catch (e) {
      if (!mounted) return;

      _showSnackBar('加入书架失败，请稍后重试');
    } finally {
      // 确保操作状态总是被重置
      if (mounted) {
        setState(() {
          _isOperating = false;
        });
      }
    }
  }

  /// 显示 SnackBar 提示
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 开始阅读
  void _startReading() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(book: widget.book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.book.name,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0.5,
      ),
      backgroundColor: Colors.white,
      body: _buildContent(),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  /// 构建页面内容
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 25),
          _buildDescription(),
        ],
      ),
    );
  }

  /// 构建头部信息区域
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 封面
        _buildCoverImage(),
        const SizedBox(width: 15),
        // 书籍信息
        Expanded(
          child: _buildBookInfo(),
        ),
      ],
    );
  }

  /// 构建封面图片
  Widget _buildCoverImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        widget.book.coverUrl,
        width: 100,
        height: 133,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 100,
          height: 133,
          color: Colors.grey.shade200,
          child: const Icon(
            Icons.image_not_supported,
            size: 40,
            color: Colors.grey,
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 100,
            height: 133,
            color: Colors.grey.shade100,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }

  /// 构建书籍信息
  Widget _buildBookInfo() {
    return SizedBox(
      height: 133,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 书名
          Text(
            widget.book.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // 作者
          Text(
            '作者：${widget.book.author}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          // 分类和字数（占位）
          Text(
            '暂无分类 · 0万字',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          // 状态标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '连载中',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建简介区域
  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '简介',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.book.description.isNotEmpty ? widget.book.description : '暂无简介',
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black54,
            height: 1.8,
          ),
        ),
      ],
    );
  }

  /// 构建底部按钮
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
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 加入书架按钮
          Expanded(
            child: _buildAddToShelfButton(),
          ),
          const SizedBox(width: 15),
          // 开始阅读按钮
          Expanded(
            child: _buildStartReadingButton(),
          ),
        ],
      ),
    );
  }

  /// 构建加入书架按钮
  Widget _buildAddToShelfButton() {
    final isDisabled = _isBookInShelf || _isOperating;

    return TextButton(
      onPressed: isDisabled ? null : _addToBookshelf,
      style: TextButton.styleFrom(
        backgroundColor:
            isDisabled ? Colors.grey.shade300 : const Color(0xFFF0F2F5),
        foregroundColor: isDisabled ? Colors.grey.shade600 : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isOperating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(_isBookInShelf ? '已在书架' : '加入书架'),
    );
  }

  /// 构建开始阅读按钮
  Widget _buildStartReadingButton() {
    return TextButton(
      onPressed: _startReading,
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text('开始阅读'),
    );
  }
}
