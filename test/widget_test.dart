// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_flutter/main.dart';

void main() {
  testWidgets('麦麦笔记本应用启动测试', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app starts with home screen.
    expect(find.text('欢迎使用麦麦笔记本'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify bottom navigation items
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('知识库'), findsOneWidget);
    expect(find.text('消息'), findsOneWidget);
    expect(find.text('个人'), findsOneWidget);
  });
}
