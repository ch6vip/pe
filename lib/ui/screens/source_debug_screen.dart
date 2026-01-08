import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/book_source.dart';
import '../../services/source_debug_service.dart';

/// 书源调试页面
///
/// 提供书源规则的调试功能，实时显示调试日志
class SourceDebugScreen extends StatefulWidget {
  /// 要调试的书源
  final BookSource source;

  const SourceDebugScreen({super.key, required this.source});

  @override
  State<SourceDebugScreen> createState() => _SourceDebugScreenState();
}

class _SourceDebugScreenState extends State<SourceDebugScreen> {
  late final TextEditingController _keywordController;
  late final ScrollController _logScrollController;
  late final SourceDebugService _debugService;

  final List<String> _logs = [];
  bool _isDebugging = false;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController();
    _logScrollController = ScrollController();
    _debugService = SourceDebugService();

    // 设置默认测试关键词
    _keywordController.text = '测试';

    // 监听调试日志流
    _debugService.logStream.listen((log) {
      setState(() {
        _logs.add(log);
      });

      // 自动滚动到底部
      if (_autoScroll && _logScrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _logScrollController.animateTo(
            _logScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _logScrollController.dispose();
    _debugService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('调试书源：${widget.source.bookSourceName}'),
        elevation: 0,
        actions: [
          // 清空日志按钮
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: '清空日志',
            onPressed: _logs.isEmpty ? null : _clearLogs,
          ),
          // 停止调试按钮
          if (_isDebugging)
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: '停止调试',
              onPressed: _stopDebug,
            ),
        ],
      ),
      body: Column(
        children: [
          // 输入区域
          _buildInputArea(),
          const Divider(height: 1),
          // 日志显示区域
          Expanded(child: _buildLogArea()),
          // 底部操作栏
          _buildBottomBar(),
        ],
      ),
    );
  }

  /// 构建输入区域
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '调试配置',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '输入测试关键词或书籍详情页URL，用于测试书源规则的正确性',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keywordController,
                  decoration: const InputDecoration(
                    labelText: '测试关键词 / 书籍URL',
                    hintText: '例如：斗破苍穹 或 https://example.com/book/123',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _startDebug(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isDebugging ? null : _startDebug,
                icon: _isDebugging
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isDebugging ? '调试中...' : '开始调试'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建日志显示区域
  Widget _buildLogArea() {
    if (_logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bug_report, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无调试日志', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text(
              '点击"开始调试"按钮开始测试书源规则',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.black87,
      child: ListView.builder(
        controller: _logScrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final log = _logs[index];
          return _buildLogItem(log);
        },
      ),
    );
  }

  /// 构建单个日志项
  Widget _buildLogItem(String log) {
    Color textColor = Colors.white;
    FontWeight fontWeight = FontWeight.normal;

    // 根据日志内容设置颜色和样式
    if (log.contains('🚀') || log.contains('✅')) {
      textColor = Colors.green;
      fontWeight = FontWeight.bold;
    } else if (log.contains('❌') || log.contains('⚠️')) {
      textColor = log.contains('❌') ? Colors.red : Colors.orange;
      fontWeight = FontWeight.bold;
    } else if (log.contains('📋')) {
      textColor = Colors.cyan;
      fontWeight = FontWeight.bold;
    } else if (log.contains('🔧')) {
      textColor = Colors.yellow;
    } else if (log.contains('⏳')) {
      textColor = Colors.blue;
    }

    return SelectableText(
      log,
      style: TextStyle(
        color: textColor,
        fontFamily: 'monospace',
        fontSize: 13,
        fontWeight: fontWeight,
        height: 1.4,
      ),
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // 自动滚动开关
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.autorenew, size: 16),
              const SizedBox(width: 4),
              const Text('自动滚动'),
              Switch(
                value: _autoScroll,
                onChanged: (value) {
                  setState(() {
                    _autoScroll = value;
                  });
                },
              ),
            ],
          ),
          const Spacer(),
          // 复制日志按钮
          TextButton.icon(
            onPressed: _logs.isEmpty ? null : _copyLogs,
            icon: const Icon(Icons.copy),
            label: const Text('复制日志'),
          ),
          const SizedBox(width: 8),
          // 导出日志按钮
          TextButton.icon(
            onPressed: _logs.isEmpty ? null : _exportLogs,
            icon: const Icon(Icons.download),
            label: const Text('导出日志'),
          ),
        ],
      ),
    );
  }

  /// 开始调试
  void _startDebug() async {
    final keyword = _keywordController.text.trim();
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入测试关键词或书籍URL'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isDebugging = true;
    });

    // 清空之前的日志
    _clearLogs();

    // 开始调试
    await _debugService.debugSource(widget.source, keyword);

    setState(() {
      _isDebugging = false;
    });
  }

  /// 停止调试
  void _stopDebug() {
    _debugService.stopDebug();
    setState(() {
      _isDebugging = false;
    });
  }

  /// 清空日志
  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  /// 复制日志到剪贴板
  void _copyLogs() async {
    final logText = _logs.join('\n');
    await Clipboard.setData(ClipboardData(text: logText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('日志已复制到剪贴板'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// 导出日志
  void _exportLogs() {
    final logText = _logs.join('\n');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出调试日志'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('日志内容：'),
            const SizedBox(height: 8),
            Container(
              width: double.maxFinite,
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                child: Text(
                  logText,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: logText));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('日志已复制到剪贴板，可以粘贴保存'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );
  }
}
