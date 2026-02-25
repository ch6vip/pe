import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/app_log_service.dart';

/// 应用日志页面
///
/// 显示应用的运行日志、调试信息和错误记录
/// 支持筛选、搜索和导出功能
class AppLogScreen extends StatefulWidget {
  const AppLogScreen({super.key});

  @override
  State<AppLogScreen> createState() => _AppLogScreenState();
}

class _AppLogScreenState extends State<AppLogScreen>
    with WidgetsBindingObserver {
  final AppLogService _logService = AppLogService();
  final TextEditingController _searchController = TextEditingController();

  /// 当前筛选的日志级别
  LogLevel? _selectedLevel;

  /// 当前搜索关键词
  String _searchKeyword = '';

  /// 日志流订阅
  StreamSubscription? _logSubscription;

  /// 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLogs();
    _logSubscription = _logService.logStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// 初始化日志
  Future<void> _initializeLogs() async {
    // 等待一下确保应用已完全启动
    await Future.delayed(const Duration(milliseconds: 100));

    // 添加一些初始化日志
    _logService.info('应用日志页面已打开', tag: 'AppLogScreen');
    _logService.debug('当前日志数量: ${_logService.logs.length}',
        tag: 'AppLogScreen');

    setState(() {
      _isLoading = false;
    });
  }

  /// 获取筛选后的日志
  ///
  /// 支持按级别和关键词组合筛选
  /// - 级别筛选：只显示指定级别的日志
  /// - 关键词筛选：搜索消息和标签中的文本
  /// - 搜索不区分大小写
  List<LogEntry> get _filteredLogs {
    var logs = _logService.logs;

    // 按级别筛选
    if (_selectedLevel != null) {
      logs = logs.where((log) => log.level == _selectedLevel).toList();
    }

    // 按关键词搜索（不区分大小写）
    if (_searchKeyword.isNotEmpty) {
      final keyword = _searchKeyword.toLowerCase();
      logs = logs.where((log) {
        return log.message.toLowerCase().contains(keyword) ||
            log.tag.toLowerCase().contains(keyword);
      }).toList();
    }

    return logs;
  }

  /// 清空日志
  Future<void> _clearLogs() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空日志'),
        content: const Text('确定要清空所有日志记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _logService.clear();
      _logService.info('日志已清空', tag: 'AppLogScreen');
    }
  }

  /// 导出日志
  Future<void> _exportLogs() async {
    try {
      final logContent = _logService.exportLogs();

      // 由于share_plus可能不可用，只提供复制功能
      await Clipboard.setData(ClipboardData(text: logContent));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日志已复制到剪贴板，请手动分享')),
        );
      }

      _logService.info('日志已导出', tag: 'AppLogScreen');
    } catch (e) {
      _logService.error('导出日志失败', error: e, tag: 'AppLogScreen');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出失败，请稍后重试')),
        );
      }
    }
  }

  /// 复制日志到剪贴板
  Future<void> _copyToClipboard() async {
    try {
      final logContent = _logService.exportLogs();
      await Clipboard.setData(ClipboardData(text: logContent));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日志已复制到剪贴板')),
        );
      }

      _logService.info('日志已复制到剪贴板', tag: 'AppLogScreen');
    } catch (e) {
      _logService.error('复制日志失败', error: e, tag: 'AppLogScreen');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('复制失败，请稍后重试')),
        );
      }
    }
  }

  /// 构建级别筛选按钮
  Widget _buildLevelFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: LogLevel.values.length + 1, // +1 for "全部" option
        itemBuilder: (context, index) {
          if (index == 0) {
            // 全部选项
            final isSelected = _selectedLevel == null;
            return _buildLevelChip(
              label: '全部',
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedLevel = null;
                });
              },
            );
          } else {
            final level = LogLevel.values[index - 1];
            final isSelected = _selectedLevel == level;
            return _buildLevelChip(
              label: level.displayName,
              isSelected: isSelected,
              level: level,
              onTap: () {
                setState(() {
                  _selectedLevel = level;
                });
              },
            );
          }
        },
      ),
    );
  }

  /// 构建级别筛选芯片
  Widget _buildLevelChip({
    required String label,
    required bool isSelected,
    LogLevel? level,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (level != null) ...[
              Icon(
                level.icon,
                size: 16,
                color: isSelected ? Colors.white : level.color,
              ),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: level?.color.withAlpha(26) ?? Colors.grey.shade100,
        selectedColor: level?.color ?? Colors.grey,
        labelStyle: TextStyle(
          color:
              isSelected ? Colors.white : level?.color ?? Colors.grey.shade700,
        ),
        side: BorderSide(
          color: level?.color ?? Colors.grey.shade300,
          width: 1,
        ),
      ),
    );
  }

  /// 构建搜索框
  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索日志内容...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchKeyword.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchKeyword = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) {
          setState(() {
            _searchKeyword = value;
          });
        },
      ),
    );
  }

  /// 构建日志统计信息
  Widget _buildStatsInfo() {
    final allLogs = _logService.logs;
    final filteredLogs = _filteredLogs;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 8),
          Text(
            '显示 ${filteredLogs.length} / ${allLogs.length} 条日志',
            style: TextStyle(color: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用日志'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
            tooltip: '复制日志',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportLogs,
            tooltip: '导出日志',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: '清空日志',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildLevelFilter(),
          _buildSearchBox(),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            _buildStatsInfo(),
            Expanded(child: _buildLogList()),
          ],
        ],
      ),
    );
  }

  /// 构建日志列表
  Widget _buildLogList() {
    final logs = _filteredLogs;

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              _searchKeyword.isNotEmpty || _selectedLevel != null
                  ? '没有找到匹配的日志'
                  : '暂无日志记录',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        reverse: true, // 最新的日志在顶部
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[logs.length - 1 - index];
          return _LogEntryWidget(log: log);
        },
      ),
    );
  }
}

/// 日志条目组件
class _LogEntryWidget extends StatelessWidget {
  const _LogEntryWidget({required this.log});

  final LogEntry log;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: log.level.color.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                log.level.icon,
                size: 16,
                color: log.level.color,
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: log.level.color.withAlpha(26),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.level.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    color: log.level.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.tag,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(log.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log.message,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  /// 格式化时间显示
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
