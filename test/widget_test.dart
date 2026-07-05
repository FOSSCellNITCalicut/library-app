import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:library_nitc/main.dart';

void main() {
  testWidgets('App renders loading screen smoke test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // The app no longer uses Flutter's counter template. It boots through the
    // splash/loading screen while auth refresh runs in the background.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
