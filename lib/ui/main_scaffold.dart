import 'package:flutter/material.dart';
import 'package:reader_flutter/ui/screens/bookshelf_screen.dart';
import 'package:reader_flutter/ui/screens/search_screen.dart';

/// 导航项配置
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

/// 主框架组件
///
/// 包含底部导航栏，管理搜索和书架两个主要页面的切换
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  /// 当前选中的导航索引
  int _selectedIndex = 0;

  /// 导航项配置列表
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
  ];

  /// 页面控制器，用于保持页面状态
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 处理导航项点击
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    // 使用 jumpToPage 而非动画，避免不必要的中间页面构建
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // 禁用滑动切换
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
