import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_dynamic/main.dart';

void main() {
  testWidgets('Reading screen renders island and chapters', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ReadingDynamicApp());

    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Chapter 1'), findsOneWidget);
    expect(find.byType(DynamicIslandProgress), findsOneWidget);
  });

  testWidgets('Scroll updates reading progress', (WidgetTester tester) async {
    await tester.pumpWidget(const ReadingDynamicApp());

    expect(find.text('0% read'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();

    expect(find.text('0% read'), findsNothing);
  });
}
