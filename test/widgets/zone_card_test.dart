import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_genie/models/stadium_data_model.dart';
import 'package:stadium_genie/widgets/zone_card.dart';

void main() {
  const testZone = ZoneData(
    id: "North",
    displayName: "North Stand",
    sections: ["101"],
    foodQueueMins: 5,
    restroomQueueMins: 12,
    merchQueueMins: 15,
    crowdLevel: CrowdLevel.medium,
    crowdPercent: 55,
    hasElevator: true,
    isWheelchairAccessible: true,
    isSensoryFriendly: false,
    foodStalls: [],
    walkTimes: {},
  );

  testWidgets('ZoneCard renders details and responds to tap actions', (
    WidgetTester tester,
  ) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoneCard(
            zone: testZone,
            isSelected: false,
            isDark: false,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text("North Stand"), findsOneWidget);
    expect(find.text("5 min"), findsOneWidget); // Food queue time text
    expect(find.text("12 min"), findsOneWidget); // Restroom queue time text
    expect(find.text("15 min"), findsOneWidget); // Merch queue time text

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });

  testWidgets('ZoneCard highlights when isSelected is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoneCard(
            zone: testZone,
            isSelected: true,
            isDark: false,
            onTap: () {},
          ),
        ),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    final borderSide = (card.shape as RoundedRectangleBorder).side;
    expect(borderSide.width, 2.0); // Selected cards get thicker border
  });
}
