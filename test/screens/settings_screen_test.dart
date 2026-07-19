import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadium_genie/screens/settings_screen.dart';
import 'package:stadium_genie/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SettingsScreen displays toggles and updates settings provider values', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("Settings & Accessibility"), findsOneWidget);
    expect(find.text("Dark Mode"), findsOneWidget);
    expect(find.text("Staff View Mode"), findsOneWidget);

    // Initial state: staffModeEnabled is false
    expect(container.read(settingsProvider).staffModeEnabled, isFalse);

    // Toggle Staff View Mode switch
    final staffSwitchFinder = find.byType(Switch).at(1); // Second switch is usually staff mode
    await tester.tap(staffSwitchFinder);
    await tester.pumpAndSettle();

    // Verify staffModeEnabled becomes true
    expect(container.read(settingsProvider).staffModeEnabled, isTrue);
  });
}
