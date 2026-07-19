import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadium_genie/screens/staff_dashboard_screen.dart';
import 'package:stadium_genie/providers/settings_provider.dart';
import 'package:stadium_genie/providers/chat_provider.dart';
import 'package:stadium_genie/models/stadium_data_model.dart';
import 'package:stadium_genie/repositories/ai_repository.dart';
import 'package:stadium_genie/models/message_model.dart';

class ManualMockAIRepository implements AIRepository {
  @override
  Stream<String> sendMessageStream({
    required List<MessageModel> conversationHistory,
    required String systemPrompt,
  }) {
    return Stream.fromIterable(['Mock ', 'AI ', 'Response']);
  }
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
        settingsProvider.notifier.overrideWith((ref) {
          final notifier = SettingsNotifier();
          // We can't easily set state here without a container, 
          // but we can use a custom notifier that starts with the desired state.
          return notifier;
        }),
        aiRepositoryProvider.overrideWithValue(mockAiRepository),
        if (stadiumData != null)
          chatProvider.overrideWith((ref) => ChatState(
                stadiumData: stadiumData,
                messages: [],
              )),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) {
            // Force the state we want
            final settings = ref.read(settingsProvider.notifier);
            if (settings.state.staffModeEnabled != staffModeEnabled) {
               // This is a bit hacky for a test but works to force state
               Future.microtask(() => settings.toggleStaffMode(staffModeEnabled));
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
    expect(find.text("Staff mode is currently disabled."), findsOneWidget);
  });

  testWidgets('StaffDashboardScreen renders metrics when staff mode is enabled', (tester) async {
    final testData = StadiumData(
      stadiumName: "Test Stadium",
      event: "Test Event",
      match: "Team A vs Team B",
      kickoff: "2026-01-01T00:00:00Z",
      capacity: 50000,
      zones: {
        "North": const ZoneData(
          id: "North",
          displayName: "North Stand",
          sections: ["1"],
          foodQueueMins: 5,
          restroomQueueMins: 5,
          merchQueueMins: 5,
          crowdLevel: CrowdLevel.low,
          crowdPercent: 20,
          hasElevator: true,
          isWheelchairAccessible: true,
          isSensoryFriendly: true,
          foodStalls: [],
          walkTimes: {},
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
      alerts: [
        const StadiumAlert(message: "High Wind", severity: "warning"),
      ],
      services: const {},
      transport: const {},
      lastUpdated: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(staffModeEnabled: true, stadiumData: testData));
    await tester.pumpAndSettle();

    expect(find.text("Operations & Volunteers Control Room"), findsOneWidget);
    expect(find.text("ACTIVE SYSTEM ALERTS"), findsOneWidget);
    expect(find.text("High Wind"), findsOneWidget);
    expect(find.text("ZONE OCCUPANCY LEVEL"), findsOneWidget);
    expect(find.text("North Zone"), findsOneWidget);
    expect(find.text("GATES QUEUE STATUS"), findsOneWidget);
    expect(find.text("Gate A"), findsOneWidget);
  });

  testWidgets('StaffDashboardScreen handles staff chat interaction', (tester) async {
    final testData = StadiumData(
      stadiumName: "Test Stadium",
      event: "Test Event",
      match: "Team A vs Team B",
      kickoff: "2026-01-01T00:00:00Z",
      capacity: 50000,
      zones: const {},
      gates: const {},
      alerts: const [],
      services: const {},
      transport: const {},
      lastUpdated: DateTime.now(),
    );

    await tester.pumpWidget(createTestWidget(staffModeEnabled: true, stadiumData: testData));
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    await tester.enterText(textField, "How is the North gate?");
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text("How is the North gate?"), findsOneWidget);
    expect(find.text("Mock AI Response"), findsOneWidget);
  });
}
