import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/reader_settings_service.dart';

/// 设置页面
///
/// 提供阅读器个性化设置和通用应用设置
/// 包含实时预览区域，展示当前设置效果
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        elevation: 0,
      ),
      body: Consumer<ReaderSettingsService>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 实时预览区域
              _buildPreviewArea(settings),

              const SizedBox(height: 24),

              // 阅读设置分组
              _buildReadingSettingsSection(context, settings),

              const SizedBox(height: 24),

              // 通用设置分组
              _buildGeneralSettingsSection(context),

              const SizedBox(height: 24),

              // 关于分组
              _buildAboutSection(context),
            ],
          );
        },
      ),
    );
  }

  /// 构建实时预览区域
  Widget _buildPreviewArea(ReaderSettingsService settings) {
    return Container(
      decoration: BoxDecoration(
        color: settings.themeBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '阅读效果预览',
            style: TextStyle(
              fontSize: 14,
              color: settings.themeTextColor.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '这是一段示例文本，用于预览当前字体大小和主题效果。\n\n用户可以实时看到设置变化，包括字体大小、行高、背景颜色等。',
            style: TextStyle(
              fontSize: settings.fontSize,
              height: settings.lineHeight,
              color: settings.themeTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建阅读设置分组
  Widget _buildReadingSettingsSection(
    BuildContext context,
    ReaderSettingsService settings,
  ) {
    return _buildSection(
      context: context,
      title: '阅读设置',
      children: [
        // 字体大小
        _buildSliderTile(
          title: '字体大小',
          value: settings.fontSize,
          min: 12.0,
          max: 30.0,
          divisions: 18,
          label: '${settings.fontSize.toInt()}',
          onChanged: (value) => settings.updateFontSize(value),
        ),

        // 行高
        _buildSliderTile(
          title: '行高',
          value: settings.lineHeight,
          min: 1.2,
          max: 2.5,
          divisions: 13,
          label: settings.lineHeight.toStringAsFixed(1),
          onChanged: (value) => settings.updateLineHeight(value),
        ),

        // 翻页动画
        _buildDropdownTile<PageAnimationType>(
          context: context,
          title: '翻页动画',
          value: settings.pageAnimation,
          items: PageAnimationType.values,
          itemLabel: (type) => type.displayName,
          onChanged: (value) {
            if (value != null) {
              settings.updatePageAnimation(value);
            }
          },
        ),

        // 背景主题
        _buildDropdownTile<ReaderTheme>(
          context: context,
          title: '背景主题',
          value: settings.theme,
          items: ReaderTheme.values,
          itemLabel: (theme) => theme.displayName,
          onChanged: (value) {
            if (value != null) {
              settings.updateTheme(value);
            }
          },
        ),
      ],
    );
  }

  /// 构建通用设置分组
  Widget _buildGeneralSettingsSection(BuildContext context) {
    return _buildSection(
      context: context,
      title: '通用设置',
      children: [
        // 缓存管理
        ListTile(
          leading: const Icon(Icons.cleaning_services_outlined),
          title: const Text('缓存管理'),
          subtitle: const Text('查看缓存大小、清理缓存'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            debugPrint('点击了缓存管理');
            // TODO: 跳转到缓存管理页面
          },
        ),

        // 数据备份
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: const Text('数据备份'),
          subtitle: const Text('导出书架数据'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            debugPrint('点击了数据备份');
            // TODO: 跳转到数据备份页面
          },
        ),

        // 数据恢复
        ListTile(
          leading: const Icon(Icons.restore_outlined),
          title: const Text('数据恢复'),
          subtitle: const Text('从备份恢复书架'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            debugPrint('点击了数据恢复');
            // TODO: 跳转到数据恢复页面
          },
        ),
      ],
    );
  }

  /// 构建关于分组
  Widget _buildAboutSection(BuildContext context) {
    return _buildSection(
      context: context,
      title: '关于',
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('版本信息'),
          subtitle: const Text('v1.0.0'),
          onTap: () {
            debugPrint('点击了版本信息');
          },
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('开源协议'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            debugPrint('点击了开源协议');
            // TODO: 显示开源协议
          },
        ),
      ],
    );
  }

  /// 构建分组容器
  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  /// 构建滑块设置项
  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建下拉选择设置项
  Widget _buildDropdownTile<T>({
    required BuildContext context,
    required String title,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(itemLabel(item)),
                  ))
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.expand_more),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
          dropdownColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}
