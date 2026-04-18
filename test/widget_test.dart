import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tremor_test_fe/main.dart';

void main() {
  testWidgets('App boots to login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TremorDetectionApp());
    await tester.pumpAndSettle();

    // The initial route is the login screen.
    expect(find.text('떨림 검사'), findsWidgets);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
