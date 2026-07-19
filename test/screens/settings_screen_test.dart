import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadium_genie/screens/settings_screen.dart';
import 'package:stadium_genie/providers/settings_provider.dart';
import 'package:stadium_genie/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SettingsScreen displays toggles and updates settings provider values', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("Settings & Accessibility"), findsOneWidget);
    expect(find.textContaining("Night Mode"), findsOneWidget);
    expect(find.textContaining("Staff & Volunteer"), findsOneWidget);

    // Toggle Staff View Mode switch
    final staffSwitch = find.byType(Switch).at(1); 
    await tester.tap(staffSwitch);
    await tester.pumpAndSettle();
  });
}
