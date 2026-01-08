import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reader_flutter/ui/main_scaffold.dart';
import 'package:reader_flutter/services/reader_settings_service.dart';

/// 应用入口函数
void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化阅读器设置服务（加载持久化数据）
  final readerSettingsService = ReaderSettingsService();
  await readerSettingsService.loadSettings();

  // 设置系统 UI 样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // 全局注入 ReaderSettingsService
        ChangeNotifierProvider.value(
          value: readerSettingsService,
        ),
      ],
      child: const PeReaderApp(),
    ),
  );
}

/// PE 阅读器应用根组件
class PeReaderApp extends StatelessWidget {
  const PeReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PE 阅读器',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const MainScaffold(),
    );
  }

  /// 构建应用主题
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      // AppBar 主题
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.transparent,
      ),
      // 卡片主题
      cardTheme: const CardThemeData(
        elevation: 2,
      ),
      // 底部导航栏主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 8,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
