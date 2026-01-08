import 'package:flutter/material.dart';
import 'package:reader_flutter/ui/screens/bookshelf_screen.dart';
import 'package:reader_flutter/ui/screens/search_screen.dart';
import 'package:reader_flutter/ui/screens/settings_screen.dart';

class _NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // 默认选中书架页（索引 1），因为这是用户最高频使用的页面
  int _selectedIndex = 1;

  // 导航项配置列表
  // 顺序：搜索(0) - 书架(1) - 设置(2)
  static const List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
      label: '搜索',
      screen: SearchScreen(),
    ),
    _NavigationItem(
      icon: Icons.book_outlined,
      activeIcon: Icons.book,
      label: '书架',
      screen: BookshelfScreen(),
    ),
    _NavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: '设置',
      screen: SettingsScreen(),
    ),
  ];

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    // 初始化 PageController，初始页为书架（索引 1）
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 底栏点击事件处理
  /// 更新选中索引并切换页面
  void _onItemTapped(int index) {
    // 避免重复点击同一 Tab
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    // 使用 jumpToPage 实现无动画切换，保证性能
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        // 禁用滑动手势，仅通过底栏切换
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _navigationItems.length,
        itemBuilder: (context, index) => _navigationItems[index].screen,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// 构建底部导航栏
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      items: _navigationItems.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          activeIcon: Icon(item.activeIcon),
          label: item.label,
        );
      }).toList(),
    );
  }
}
