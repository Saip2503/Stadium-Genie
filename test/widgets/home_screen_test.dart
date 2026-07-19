import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadium_genie/screens/home_screen.dart';
import 'package:stadium_genie/models/stadium_data_model.dart';
import 'package:stadium_genie/models/message_model.dart';
import 'package:stadium_genie/repositories/stadium_repository.dart';
import 'package:stadium_genie/repositories/ai_repository.dart';
import 'package:stadium_genie/providers/chat_provider.dart';
import 'package:stadium_genie/widgets/emergency_info_card.dart';
import 'package:stadium_genie/providers/auth_provider.dart';
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

class FakeAIRepository implements AIRepository {
  @override
  Stream<String> sendMessageStream({
    required List<MessageModel> conversationHistory,
    required String systemPrompt,
  }) => const Stream.empty();

  @override
  bool get hasConfiguredApiKey => true;
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
    gates: const {
      "Gate A": GateData(
        name: "Gate A",
        queueMins: 5,
        isOpen: true,
        isWheelchairAccessible: true,
        location: "North",
        transportNearby: [],
      )
    },
    alerts: const [],
    capacity: 80000,
    firstAidLocations: const ["Section 102"],
    guestServicesLocation: "Gate B lobby",
  );

  testWidgets('HomeScreen dashboard renders layout skeleton, sustainability, and emergency cards', (
    WidgetTester tester,
  ) async {
    // Increase physical size to avoid overflow in tests
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeRepo = FakeStadiumRepository(testData);
    final fakeAI = FakeAIRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stadiumRepositoryProvider.overrideWithValue(fakeRepo),
          aiRepositoryProvider.overrideWithValue(fakeAI),
          currentUserProvider.overrideWithValue(null),
          chatProvider.overrideWith((ref) => ChatNotifier(
            ref,
            fakeRepo,
            fakeAI,
          )..state = ChatState(
            messages: const [],
            isLoading: false,
            stadiumData: testData,
          )),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify main structures are initialized
    expect(find.byType(HomeScreen), findsOneWidget);

    // Verify Sustainability card renders
    expect(find.textContaining("SUSTAINABILITY ACTION"), findsOneWidget);

    // Verify EmergencyInfoCard renders
    expect(find.byType(EmergencyInfoCard), findsOneWidget);
    expect(find.text("Emergency & Services"), findsOneWidget);
    expect(find.text("Section 102"), findsOneWidget);
  });
}
