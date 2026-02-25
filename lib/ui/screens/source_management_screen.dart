import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/source_manager_service.dart';
import '../../models/book_source.dart';
import 'source_edit_screen.dart';

/// 书源管理页面
///
/// 提供书源的增删改查功能，包括：
/// - 展示所有书源列表
/// - 启用/禁用书源
/// - 删除书源
/// - 添加新书源
class SourceManagementScreen extends StatefulWidget {
  const SourceManagementScreen({super.key});

  @override
  State<SourceManagementScreen> createState() => _SourceManagementScreenState();
}

class _SourceManagementScreenState extends State<SourceManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('书源管理'),
        elevation: 0,
        actions: [
          // 更多操作菜单
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: '更多操作',
            onSelected: (value) {
              if (value == 'network_import') {
                _showNetworkImportDialog(context);
              } else if (value == 'add_source') {
                _navigateToEditScreen(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'network_import',
                child: Row(
                  children: [
                    Icon(Icons.cloud_download),
                    SizedBox(width: 8),
                    Text('网络导入'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_source',
                child: Row(
                  children: [Icon(Icons.add), SizedBox(width: 8), Text('添加书源')],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<SourceManagerService>(
        builder: (context, sourceService, child) {
          // 显示加载状态
          if (sourceService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 显示错误信息
          if (sourceService.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    sourceService.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => sourceService.clearError(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          // 书源列表为空
          if (sourceService.sources.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无书源',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右上角 + 添加书源',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // 显示书源列表
          return Column(
            children: [
              // 统计信息
              _buildStatisticsHeader(sourceService),
              // 书源列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sourceService.sources.length,
                  itemBuilder: (context, index) {
                    final source = sourceService.sources[index];
                    return _buildSourceItem(source, sourceService);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建统计信息头部
  Widget _buildStatisticsHeader(SourceManagerService sourceService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(77),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withAlpha(77),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.library_books,
            label: '总书源',
            value: sourceService.sourceCount.toString(),
            color: Theme.of(context).colorScheme.primary,
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor.withAlpha(77),
          ),
          _buildStatItem(
            icon: Icons.check_circle,
            label: '已启用',
            value: sourceService.enabledSourceCount.toString(),
            color: Colors.green,
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor.withAlpha(77),
          ),
          _buildStatItem(
            icon: Icons.block,
            label: '已禁用',
            value:
                (sourceService.sourceCount - sourceService.enabledSourceCount)
                    .toString(),
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  /// 构建书源列表项
  Widget _buildSourceItem(
    BookSource source,
    SourceManagerService sourceService,
  ) {
    return Dismissible(
      key: Key(source.bookSourceUrl),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _confirmDeleteSource(source, sourceService);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          // 书源图标（使用首字母作为占位）
          leading: CircleAvatar(
            backgroundColor: source.enabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            child: Text(
              source.bookSourceName.isNotEmpty
                  ? source.bookSourceName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 书源名称和 URL
          title: Text(
            source.bookSourceName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: source.enabled ? null : Colors.grey,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                source.bookSourceUrl,
                style: TextStyle(
                  fontSize: 12,
                  color: source.enabled ? Colors.grey[600] : Colors.grey[400],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          // 操作按钮区域
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 编辑按钮
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: '编辑书源',
                onPressed: () {
                  _navigateToEditScreen(context, source: source);
                },
              ),
              // 启用/禁用开关
              Switch(
                value: source.enabled,
                onChanged: (value) {
                  sourceService.toggleSourceEnabled(source.bookSourceUrl);
                },
              ),
            ],
          ),
          // 点击编辑书源
          onTap: () {
            _navigateToEditScreen(context, source: source);
          },
        ),
      ),
    );
  }

  /// 导航到书源编辑页面
  void _navigateToEditScreen(BuildContext context, {BookSource? source}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SourceEditScreen(source: source)),
    );
  }

  /// 确认删除书源
  void _confirmDeleteSource(
    BookSource source,
    SourceManagerService sourceService,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除书源「${source.bookSourceName}」吗？\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success =
                  await sourceService.deleteSource(source.bookSourceUrl);
              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('书源已删除')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示网络导入对话框
  void _showNetworkImportDialog(BuildContext context) {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('网络导入'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请输入书源文件的 URL 地址：', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://example.com/sources.json',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              maxLines: 2,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            Text(
              '支持 JSON 格式的单个书源或书源数组',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isEmpty) {
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(const SnackBar(content: Text('请输入 URL')));
                return;
              }

              Navigator.pop(dialogContext);

              // 显示加载提示
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text('正在导入...'),
                    ],
                  ),
                  duration: Duration(seconds: 30),
                ),
              );

              try {
                final sourceService = Provider.of<SourceManagerService>(
                  context,
                  listen: false,
                );

                final importedCount = await sourceService.importSourceFromUrl(
                  url,
                );

                if (!context.mounted) return;

                // 清除加载提示
                ScaffoldMessenger.of(context).clearSnackBars();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('成功导入 $importedCount 个书源'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                // 清除加载提示
                ScaffoldMessenger.of(context).clearSnackBars();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('导入失败: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
