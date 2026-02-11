import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book_source.dart';
import '../../services/source_manager_service.dart';
import 'source_debug_screen.dart';

/// 书源编辑页面
///
/// 提供新建和编辑书源的功能，使用 TabBar 分组展示不同类型的规则配置
///
/// 功能特性：
/// - 新建模式：创建全新的书源配置
/// - 编辑模式：修改现有书源的规则和设置
/// - 四个配置标签页：基本信息、搜索规则、目录规则、正文规则
/// - 表单验证：确保必填字段不为空
/// - 调试功能：编辑模式下可直接进入调试
class SourceEditScreen extends StatefulWidget {
  /// 要编辑的书源，如果为 null 则表示新建模式
  final BookSource? source;

  const SourceEditScreen({super.key, this.source});

  @override
  State<SourceEditScreen> createState() => _SourceEditScreenState();
}

class _SourceEditScreenState extends State<SourceEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 表单控制器
  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _ruleSearchController;
  late final TextEditingController _ruleChapterController;
  late final TextEditingController _ruleContentController;

  // 状态变量
  bool _enabled = true;
  bool _isLoading = false;

  // 表单 Key 用于验证
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // 初始化表单控制器
    _nameController = TextEditingController();
    _baseUrlController = TextEditingController();
    _ruleSearchController = TextEditingController();
    _ruleChapterController = TextEditingController();
    _ruleContentController = TextEditingController();

    // 如果是编辑模式，初始化表单数据
    if (widget.source != null) {
      _initializeFormData(widget.source!);
    }
  }

  /// 初始化表单数据（编辑模式）
  void _initializeFormData(BookSource source) {
    _nameController.text = source.bookSourceName;
    _baseUrlController.text = source.bookSourceUrl;
    _enabled = source.enabled;
    _ruleSearchController.text = _encodeRuleJson(source.ruleSearch?.toJson());
    _ruleChapterController.text = _encodeRuleJson(source.ruleToc?.toJson());
    _ruleContentController.text = _encodeRuleJson(source.ruleContent?.toJson());
  }

  @override
  void dispose() {
    // 释放所有控制器，防止内存泄漏
    _tabController.dispose();
    _nameController.dispose();
    _baseUrlController.dispose();
    _ruleSearchController.dispose();
    _ruleChapterController.dispose();
    _ruleContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.source == null ? '新建书源' : '编辑书源'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelStyle: const TextStyle(fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: '基本信息', icon: Icon(Icons.info_outline)),
            Tab(text: '搜索规则', icon: Icon(Icons.search)),
            Tab(text: '目录规则', icon: Icon(Icons.list)),
            Tab(text: '正文规则', icon: Icon(Icons.article)),
          ],
        ),
        actions: [
          // 调试按钮（仅在编辑模式下显示）
          if (widget.source != null)
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: '调试书源',
              onPressed: _isLoading ? null : _openDebugScreen,
            ),
          // 保存按钮
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: '保存',
            onPressed: _isLoading ? null : _saveSource,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildSearchRuleTab(),
            _buildChapterRuleTab(),
            _buildContentRuleTab(),
          ],
        ),
      ),
    );
  }

  /// 构建基本信息标签页
  Widget _buildBasicInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 书源名称（必填）
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '书源名称 *',
              hintText: '例如：起点中文网',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.book),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入书源名称';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // BaseURL（必填）
          TextFormField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: '书源地址 *',
              hintText: '例如：www.qidian.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入书源地址';
              }
              return null;
            },
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // 启用开关
          SwitchListTile(
            title: const Text('启用书源'),
            subtitle: const Text('关闭后将不会使用此书源进行搜索'),
            value: _enabled,
            onChanged: (value) {
              setState(() {
                _enabled = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  /// 构建搜索规则标签页
  Widget _buildSearchRuleTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '搜索规则配置',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '请输入 JSON 格式的搜索规则，包含搜索URL和结果解析规则等',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextFormField(
              controller: _ruleSearchController,
              decoration: const InputDecoration(
                labelText: '搜索规则',
                hintText:
                    '{"searchUrl": "/search?q={key}", "ruleList": "class.book@tag.li"}',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '示例：{"searchUrl": "/search?q={key}", "ruleList": "class.book-item", "bookName": "text", "bookAuthor": "text"}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// 构建目录规则标签页
  Widget _buildChapterRuleTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '目录规则配置',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '请输入 JSON 格式的章节列表解析规则',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextFormField(
              controller: _ruleChapterController,
              decoration: const InputDecoration(
                labelText: '目录规则',
                hintText:
                    '{"chapterList": "class.chapter@tag.a", "chapterName": "text"}',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '示例：{"chapterList": "class.chapter@tag.a", "chapterName": "text", "chapterUrl": "href"}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// 构建正文规则标签页
  Widget _buildContentRuleTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '正文规则配置',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '请输入 JSON 格式的正文内容解析规则',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextFormField(
              controller: _ruleContentController,
              decoration: const InputDecoration(
                labelText: '正文规则',
                hintText:
                    '{"content": "id.content@textNodes", "nextUrl": "id.nextBtn@href"}',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '示例：{"content": "id.content@textNodes", "nextUrl": "id.next@href", "replaceRules": ["广告1", "广告2"]}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _parseRuleJson(String text) {
    if (text.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  String _encodeRuleJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return '';
    }
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  /// 保存书源
  Future<void> _saveSource() async {
    // 验证表单
    if (!_formKey.currentState!.validate()) {
      // 切换到基本信息标签页显示验证错误
      _tabController.animateTo(0);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sourceService = context.read<SourceManagerService>();

      // 标准化 URL
      String normalizedUrl = _baseUrlController.text.trim();
      if (!normalizedUrl.startsWith('http://') &&
          !normalizedUrl.startsWith('https://')) {
        normalizedUrl = 'https://$normalizedUrl';
      }

      final ruleSearchJson = _parseRuleJson(_ruleSearchController.text);
      final ruleTocJson = _parseRuleJson(_ruleChapterController.text);
      final ruleContentJson = _parseRuleJson(_ruleContentController.text);

      final bookSource = BookSource(
        bookSourceUrl: normalizedUrl,
        bookSourceName: _nameController.text.trim(),
        enabled: _enabled,
        ruleSearch:
            ruleSearchJson != null ? SearchRule.fromJson(ruleSearchJson) : null,
        ruleToc: ruleTocJson != null ? TocRule.fromJson(ruleTocJson) : null,
        ruleContent: ruleContentJson != null
            ? ContentRule.fromJson(ruleContentJson)
            : null,
        lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
      );

      bool success;
      if (widget.source == null) {
        // 新建模式
        success = await sourceService.addSource(bookSource);
      } else {
        // 编辑模式
        success = await sourceService.updateSource(bookSource);
      }

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.source == null ? '书源创建成功' : '书源更新成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sourceService.errorMessage ?? '保存失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 打开调试页面
  void _openDebugScreen() async {
    if (widget.source == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先保存书源后再进行调试'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 创建当前书源对象（包含最新的编辑内容）
    final currentRuleSearchJson = _parseRuleJson(_ruleSearchController.text);
    final currentRuleTocJson = _parseRuleJson(_ruleChapterController.text);
    final currentRuleContentJson = _parseRuleJson(_ruleContentController.text);

    final currentSource = BookSource(
      bookSourceUrl: _baseUrlController.text.trim().isEmpty
          ? widget.source!.bookSourceUrl
          : _baseUrlController.text.trim(),
      bookSourceName: _nameController.text.trim().isEmpty
          ? widget.source!.bookSourceName
          : _nameController.text.trim(),
      enabled: _enabled,
      ruleSearch: currentRuleSearchJson != null
          ? SearchRule.fromJson(currentRuleSearchJson)
          : widget.source!.ruleSearch,
      ruleToc: currentRuleTocJson != null
          ? TocRule.fromJson(currentRuleTocJson)
          : widget.source!.ruleToc,
      ruleContent: currentRuleContentJson != null
          ? ContentRule.fromJson(currentRuleContentJson)
          : widget.source!.ruleContent,
      lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SourceDebugScreen(source: currentSource),
      ),
    );
  }
}
