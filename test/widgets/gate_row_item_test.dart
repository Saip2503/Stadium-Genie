import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_genie/models/stadium_data_model.dart';
import 'package:stadium_genie/widgets/gate_row_item.dart';

void main() {
  const openGate = GateData(
    name: "Gate B",
    queueMins: 8,
    isOpen: true,
    isWheelchairAccessible: true,
    location: "Northwest Corner",
    transportNearby: ["Train"],
  );

  testWidgets('GateRowItem renders open gate details, accessible badge, and labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GateRowItem(
            gate: openGate,
            isDark: false,
          ),
        ),
      ),
    );

    expect(find.text("Gate B"), findsOneWidget);
    expect(find.text("8 min queue"), findsOneWidget);
    expect(find.byIcon(Icons.accessible), findsOneWidget);
  });
}
