import 'package:flutter/material.dart';

/// 设置页面
/// 简单的占位符Widget
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('设置'),
      ),
    );
  }
}
