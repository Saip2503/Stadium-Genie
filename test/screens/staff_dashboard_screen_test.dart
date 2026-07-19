import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadium_genie/screens/staff_dashboard_screen.dart';
import 'package:stadium_genie/providers/settings_provider.dart';
import 'package:stadium_genie/providers/chat_provider.dart';
import 'package:stadium_genie/models/stadium_data_model.dart';
import 'package:stadium_genie/repositories/ai_repository.dart';
import 'package:stadium_genie/models/message_model.dart';
import 'package:stadium_genie/providers/auth_provider.dart';

class ManualMockAIRepository implements AIRepository {
  @override
  Stream<String> sendMessageStream({
    required List<MessageModel> conversationHistory,
    required String systemPrompt,
  }) {
    return Stream.fromIterable(['Mock ', 'AI ', 'Response']);
  }

  @override
  bool get hasConfiguredApiKey => true;
}

void main() {
  late ManualMockAIRepository mockAiRepository;

  setUp(() {
    mockAiRepository = ManualMockAIRepository();
  });

  Widget createTestWidget({
    required bool staffModeEnabled,
    StadiumData? stadiumData,
  }) {
    return ProviderScope(
      overrides: [
        aiRepositoryProvider.overrideWithValue(mockAiRepository),
        currentUserProvider.overrideWithValue(null),
        if (stadiumData != null)
          chatProvider.overrideWith((ref) => ChatNotifier(
                ref,
                ref.read(stadiumRepositoryProvider),
                mockAiRepository,
              )..state = ChatState(
                  stadiumData: stadiumData,
                  messages: [],
                  isLoading: false,
                )),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) {
            // Force the state we want
            final settingsNotifier = ref.read(settingsProvider.notifier);
            if (settingsNotifier.state.staffModeEnabled != staffModeEnabled) {
               Future.microtask(() => settingsNotifier.toggleStaffMode());
            }
            return const StaffDashboardScreen();
          },
        ),
      ),
    );
  }

  testWidgets('StaffDashboardScreen shows Access Denied when staff mode is disabled', (tester) async {
    await tester.pumpWidget(createTestWidget(staffModeEnabled: false));
    await tester.pumpAndSettle();
    expect(find.text("Access Denied"), findsOneWidget);
    expect(find.textContaining("Staff mode is currently disabled"), findsOneWidget);
  });

  testWidgets('StaffDashboardScreen renders metrics when staff mode is enabled', (tester) async {
    final testData = StadiumData(
      stadiumName: "Test Stadium",
      event: "Test Event",
      match: "Team A vs Team B",
      kickoff: DateTime.parse("2026-01-01T00:00:00Z"),
      capacity: 50000,
      zones: {
        "North": ZoneData(
          id: "North",
          displayName: "North Stand",
          sections: const ["1"],
          foodQueueMins: 5,
          restroomQueueMins: 5,
          merchQueueMins: 5,
          crowdLevel: CrowdLevel.low,
          crowdPercent: 20,
          hasElevator: true,
          isWheelchairAccessible: true,
          isSensoryFriendly: true,
          foodStalls: const [],
          walkTimes: const {},
        )
      },
      gates: {
        "Gate A": const GateData(
          name: "Gate A",
          queueMins: 10,
          isOpen: true,
          isWheelchairAccessible: true,
          location: "North",
          transportNearby: [],
        )
      },
      alerts: const [
        StadiumAlert(id: "1", type: "weather", message: "High Wind", severity: "warning"),
      ],
      lastUpdated: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(staffModeEnabled: true, stadiumData: testData));
    await tester.pumpAndSettle();

    expect(find.textContaining("Control Room"), findsOneWidget);
    expect(find.text("ACTIVE SYSTEM ALERTS"), findsOneWidget);
    expect(find.text("High Wind"), findsOneWidget);
    expect(find.text("ZONE OCCUPANCY LEVEL"), findsOneWidget);
    expect(find.text("North Zone"), findsOneWidget);
    expect(find.text("GATES QUEUE STATUS"), findsOneWidget);
    expect(find.text("Gate A"), findsOneWidget);
  });

  testWidgets('StaffDashboardScreen handles staff chat interaction', (tester) async {
    // Increase surface size to ensure chat panel is visible
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testData = StadiumData(
      stadiumName: "Test Stadium",
      event: "Test Event",
      match: "Team A vs Team B",
      kickoff: DateTime.parse("2026-01-01T00:00:00Z"),
      capacity: 50000,
      zones: const {},
      gates: const {},
      alerts: const [],
      lastUpdated: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(staffModeEnabled: true, stadiumData: testData));
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    await tester.enterText(textField, "How is the North gate?");
    
    final sendButton = find.byIcon(Icons.send);
    await tester.ensureVisible(sendButton);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(find.text("How is the North gate?"), findsOneWidget);
    expect(find.textContaining("Mock AI Response"), findsOneWidget);
  });
}
