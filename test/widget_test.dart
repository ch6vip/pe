import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reader_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // 构建应用并触发一帧
    await tester.pumpWidget(const PeReaderApp());

    // 验证应用能够正常启动
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
