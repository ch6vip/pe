import 'package:flutter/material.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/models/chapter.dart';
import 'package:reader_flutter/models/chapter_content.dart';
import 'package:reader_flutter/services/api_service.dart';
import 'package:reader_flutter/services/storage_service.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Chapter> _chapters = [];
  ChapterContent? _currentContent;
  int _currentChapterIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // Reading settings
  double _fontSize = 18.0;
  double _lineHeight = 1.8;
  Color _backgroundColor = Colors.white;
  Color _fontColor = Colors.black87;
  bool _isUiVisible = true;

  final List<Map<String, Color>> _themes = [
    {'bg': Colors.white, 'font': Colors.black87},
    {'bg': const Color(0xFFF5F5DC), 'font': Colors.black87}, // Beige
    {'bg': const Color(0xFFE0F2F1), 'font': Colors.black87}, // Cyan light
    {'bg': const Color(0xFF333333), 'font': Colors.grey.shade400}, // Dark
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final chapters = await _apiService.getChapterList(widget.book.id);
      if (chapters.isNotEmpty) {
        setState(() {
          _chapters = chapters;
        });
        // Check for saved progress and load it, otherwise load the first chapter.
        final bookshelf = await _storageService.getBookshelf();
        int initialChapterIndex = 0;
        try {
          final savedBook = bookshelf.firstWhere((b) => b.id == widget.book.id);
          if (savedBook.lastReadChapterTitle != null) {
            final savedIndex = chapters.indexWhere((c) => c.title == savedBook.lastReadChapterTitle);
            if (savedIndex != -1) {
              initialChapterIndex = savedIndex;
            }
          }
        } catch (e) {
          // Book is not in the shelf, orElse is not used to avoid side effects.
          // No problem, we just load the first chapter.
        }
        await _loadChapterContent(initialChapterIndex);
      } else {
        setState(() {
          _errorMessage = '未能加载到章节列表。';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载章节列表失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChapterContent(int index) async {
    if (index < 0 || index >= _chapters.length) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final content = await _apiService.getChapterContent(_chapters[index].itemId);
      setState(() {
        _currentContent = content;
        _currentChapterIndex = index;
        _isLoading = false;
      });
      await _saveProgress(index);
    } catch (e) {
      setState(() {
        _errorMessage = '加载章节内容失败: $e';
        _isLoading = false;
      });
    }
  }
  
    Future<void> _saveProgress(int chapterIndex) async {
      try {
        // We only save progress for books that are actually in the bookshelf.
        final List<Book> bookshelf = await _storageService.getBookshelf();
        final int bookIndexInShelf = bookshelf.indexWhere((b) => b.id == widget.book.id);
  
        if (bookIndexInShelf != -1) {
          final Book oldBook = bookshelf[bookIndexInShelf];
          final Book updatedBook = oldBook.copyWith(
            lastReadTime: DateTime.now().millisecondsSinceEpoch,
            lastReadChapterTitle: _chapters[chapterIndex].title,
          );
          bookshelf[bookIndexInShelf] = updatedBook;
          await _storageService.saveBookshelf(bookshelf);
        }
      } catch (e) {
        // Saving progress is a background task, so we don't need to show an error to the user.
        print("Failed to save progress: $e");
      }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_isUiVisible ? kToolbarHeight : 0),
        child: AnimatedOpacity(
          opacity: _isUiVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: AppBar(
            title: Text(_currentContent?.title ?? widget.book.name, overflow: TextOverflow.ellipsis),
            backgroundColor: _backgroundColor,
            foregroundColor: _fontColor,
            elevation: 0.5,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isUiVisible = !_isUiVisible;
          });
        },
        child: _buildBody(),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _isUiVisible ? kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom : 0,
        child: Wrap(
          children: [
            _buildNavigationControls(),
          ],
        ),
      ),
      endDrawer: _buildChapterDrawer(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _currentContent == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }
    if (_currentContent == null) {
      return const Center(child: Text('没有内容'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Text(
        _currentContent!.content,
        style: TextStyle(fontSize: _fontSize, height: _lineHeight, color: _fontColor),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return BottomAppBar(
      color: _backgroundColor,
      elevation: 0.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: _fontColor),
            onPressed: _currentChapterIndex > 0 ? () => _loadChapterContent(_currentChapterIndex - 1) : null,
          ),
          IconButton(
            icon: Icon(Icons.list, color: _fontColor),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: _fontColor),
            onPressed: _showSettingsPanel,
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward, color: _fontColor),
            onPressed: _currentChapterIndex < _chapters.length - 1 ? () => _loadChapterContent(_currentChapterIndex + 1) : null,
          ),
        ],
      ),
    );
  }
  
    Widget _buildChapterDrawer() {
      if (_chapters.isEmpty) {
        return const Drawer(child: Center(child: Text("No Chapters")));
      }
  
      return Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '目录 (${_chapters.length}章)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = _chapters[index];
                    final bool isCurrent = index == _currentChapterIndex;
                    return ListTile(
                      title: Text(
                        chapter.title,
                        style: TextStyle(
                          color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.of(context).pop(); // Close the drawer
                        _loadChapterContent(index); // Load the selected chapter
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
    
      void _showSettingsPanel() {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Container(
                  color: _backgroundColor,
                  padding: const EdgeInsets.all(20.0),
                  child: Wrap(
                    runSpacing: 20,
                    children: [
                      // Font Size Control
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('字号', style: TextStyle(color: _fontColor)),
                          Row(
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(side: BorderSide(color: _fontColor.withOpacity(0.5))),
                                onPressed: () {
                                  setModalState(() {
                                    setState(() {
                                      _fontSize = (_fontSize - 1).clamp(12.0, 30.0);
                                    });
                                  });
                                },
                                child: Text('A-', style: TextStyle(color: _fontColor)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(_fontSize.toInt().toString(), style: TextStyle(color: _fontColor)),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(side: BorderSide(color: _fontColor.withOpacity(0.5))),
                                onPressed: () {
                                  setModalState(() {
                                    setState(() {
                                      _fontSize = (_fontSize + 1).clamp(12.0, 30.0);
                                    });
                                  });
                                },
                                child: Text('A+', style: TextStyle(color: _fontColor)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Line Height Control
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('行距', style: TextStyle(color: _fontColor)),
                          Row(
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(side: BorderSide(color: _fontColor.withOpacity(0.5))),
                                onPressed: () {
                                  setModalState(() {
                                    setState(() {
                                      _lineHeight = (_lineHeight - 0.1).clamp(1.2, 2.5);
                                    });
                                  });
                                },
                                child: Icon(Icons.format_line_spacing_sharp, color: _fontColor),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(_lineHeight.toStringAsFixed(1), style: TextStyle(color: _fontColor)),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(side: BorderSide(color: _fontColor.withOpacity(0.5))),
                                onPressed: () {
                                  setModalState(() {
                                    setState(() {
                                      _lineHeight = (_lineHeight + 0.1).clamp(1.2, 2.5);
                                    });
                                  });
                                },
                                child: Icon(Icons.format_line_spacing_outlined, color: _fontColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Theme Control
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('主题', style: TextStyle(color: _fontColor)),
                          Row(
                            children: _themes.map((theme) {
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    setState(() {
                                      _backgroundColor = theme['bg']!;
                                      _fontColor = theme['font']!;
                                    });
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: CircleAvatar(
                                    backgroundColor: theme['bg'],
                                    radius: 15,
                                    child: _backgroundColor == theme['bg']
                                        ? const Icon(Icons.check, size: 20, color: Colors.blue)
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      }
    }
