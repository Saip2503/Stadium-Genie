import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadium_genie/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: StadiumGenieApp()));

    // Let the entry slide animations initialize and tick once
    await tester.pump(const Duration(milliseconds: 300));

    // Verify app starts loading
    expect(find.byType(StadiumGenieApp), findsOneWidget);
  });
}
