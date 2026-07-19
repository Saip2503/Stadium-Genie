import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadium_genie/screens/home_screen.dart';
import 'package:stadium_genie/models/stadium_data_model.dart';
import 'package:stadium_genie/repositories/stadium_repository.dart';
import 'package:stadium_genie/providers/chat_provider.dart';
import 'package:stadium_genie/widgets/emergency_info_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeStadiumRepository implements StadiumRepository {
  final StadiumData data;
  FakeStadiumRepository(this.data);

  @override
  Future<StadiumData> getStadiumData() async => data;

  @override
  StadiumData simulateUpdate(StadiumData current) => current;

  @override
  String buildContextString({
    required StadiumData data,
    required String userZone,
    required bool wheelchairMode,
    required bool sensoryMode,
  }) => "fake context";
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

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
    firstAidLocations: const ["Section 102"],
    guestServicesLocation: "Gate B lobby",
  );

  testWidgets('HomeScreen dashboard renders layout skeleton, sustainability, and emergency cards', (
    WidgetTester tester,
  ) async {
    final fakeRepo = FakeStadiumRepository(testData);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stadiumRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // Initial loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete microtask queue / future executions
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify main structures are initialized
    expect(find.byType(HomeScreen), findsOneWidget);

    // Verify Sustainability card renders
    expect(find.text("🌱 SUSTAINABILITY ACTION"), findsOneWidget);

    // Verify EmergencyInfoCard renders
    expect(find.byType(EmergencyInfoCard), findsOneWidget);
    expect(find.text("Emergency & Services"), findsOneWidget);
    expect(find.text("Section 102"), findsOneWidget);
  });
}
