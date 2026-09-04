// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulseflow/main.dart';

void main() {
  testWidgets('AdaptQApp smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AdaptQApp()));

    // Verify that the app opens directly on the tab shell.
    expect(find.text('AdaptQ'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('FlowMind'), findsOneWidget);
    expect(find.text('Pipeline'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Achieve more every day'), findsNothing);

    await tester.pump(const Duration(milliseconds: 100));
  });

  for (final width in [320.0, 360.0, 375.0, 412.0]) {
    testWidgets('AdaptQApp fits a ${width.toInt()}px viewport',
        (WidgetTester tester) async {
      final overflowErrors = <String>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) {
          overflowErrors.add(details.exceptionAsString());
        }
      };

      await tester.binding.setSurfaceSize(Size(width, 800));
      await tester.pumpWidget(const ProviderScope(child: AdaptQApp()));
      await tester.pump(const Duration(milliseconds: 100));

      FlutterError.onError = previousOnError;
      await tester.binding.setSurfaceSize(null);
      expect(overflowErrors, isEmpty);
    });
  }
}
