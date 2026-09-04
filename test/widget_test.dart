// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulseflow/main.dart';

void main() {
  testWidgets('AdaptQApp smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AdaptQApp()));

    // Verify that 'AdaptQ' title renders on the splash screen.
    expect(find.text('AdaptQ'), findsOneWidget);
    expect(find.text('Achieve more every day'), findsOneWidget);

    // Pump and settle to allow timers to complete cleanly
    await tester.pumpAndSettle();
  });
}
