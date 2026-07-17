import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadium_genie/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen dashboard renders layout skeleton', (
    WidgetTester tester,
  ) async {
    // Render HomeScreen inside a Riverpod ProviderScope
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );

    // Initial load will display the loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the mock asset load to complete or fail gracefully
    await tester.pump(const Duration(milliseconds: 100));

    // Verify main structures are initialized
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
