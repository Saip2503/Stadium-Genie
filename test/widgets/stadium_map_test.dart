import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadium_genie/models/stadium_data_model.dart';
import 'package:stadium_genie/widgets/stadium_map.dart';
import 'package:stadium_genie/providers/settings_provider.dart';

void main() {
  final testData = StadiumData(
    stadiumName: "MetLife Stadium",
    event: "FIFA World Cup",
    match: "USA vs Italy",
    kickoff: DateTime.now().add(const Duration(hours: 2)),
    lastUpdated: DateTime.now(),
    zones: const {
      "North": ZoneData(
        id: "North",
        displayName: "North Stand",
        sections: ["101"],
        foodQueueMins: 5,
        restroomQueueMins: 10,
        crowdLevel: CrowdLevel.medium,
        crowdPercent: 50,
        hasElevator: true,
        isWheelchairAccessible: true,
        isSensoryFriendly: false,
        foodStalls: [],
        walkTimes: {},
      )
    },
    gates: const {},
    alerts: const [],
    capacity: 80000,
  );

  testWidgets('StadiumMap renders map fallback and responds to interactive zone taps', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: StadiumMap(
              stadiumData: testData,
              isDark: false,
            ),
          ),
        ),
      ),
    );

    // Initial check: is active zone default 'North' or matching state?
    final initialZone = container.read(settingsProvider).currentZone;
    expect(initialZone, "North");

    // Renders fallback map since asset image doesn't load in test framework
    expect(find.byType(StadiumMap), findsOneWidget);

    // Find and tap on SOUTH zone button overlay
    final southButtonFinder = find.text("SOUTH");
    expect(southButtonFinder, findsOneWidget);
    await tester.tap(southButtonFinder);
    await tester.pump();

    // Active zone in provider settings should switch to 'South'
    final newZone = container.read(settingsProvider).currentZone;
    expect(newZone, "South");
  });
}
