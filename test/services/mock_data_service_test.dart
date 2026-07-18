import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_genie/models/stadium_data_model.dart';
import 'package:stadium_genie/services/mock_data_service.dart';

void main() {
  group('MockDataService Context Builder Tests', () {
    final mockData = StadiumData(
      stadiumName: "Test Arena",
      event: "World Cup Match",
      match: "Team A vs Team B",
      kickoff: DateTime.parse("2026-07-18T20:00:00-04:00"),
      lastUpdated: DateTime.now(),
      capacity: 50000,
      zones: {
        "North": const ZoneData(
          id: "North",
          displayName: "North Zone",
          sections: ["101"],
          foodQueueMins: 10,
          restroomQueueMins: 5,
          crowdLevel: CrowdLevel.medium,
          crowdPercent: 60,
          hasElevator: false,
          isWheelchairAccessible: false,
          isSensoryFriendly: false,
          foodStalls: [],
          walkTimes: {"South": 5},
        ),
        "South": const ZoneData(
          id: "South",
          displayName: "South Zone",
          sections: ["201"],
          foodQueueMins: 2,
          restroomQueueMins: 12,
          crowdLevel: CrowdLevel.low,
          crowdPercent: 30,
          hasElevator: true,
          isWheelchairAccessible: true,
          isSensoryFriendly: true,
          foodStalls: [],
          walkTimes: {"North": 5},
        ),
      },
      gates: {
        "Gate A": const GateData(
          name: "Gate A",
          queueMins: 15,
          isOpen: true,
          isWheelchairAccessible: true,
          location: "North",
          transportNearby: [],
        ),
      },
      alerts: [],
      parkingLots: {
        "Lot A": const ParkingLotStatus(
          name: "Lot A",
          total: 500,
          available: 120,
          accessibleAvailable: 15,
        ),
      },
    );

    final service = MockDataService();

    test('buildContextString builds proper context without special modes', () {
      final contextStr = service.buildContextString(
        data: mockData,
        userZone: "North",
        wheelchairMode: false,
        sensoryMode: false,
      );

      expect(contextStr, contains("User Current Location: North Zone"));
      expect(contextStr, contains("North Zone:"));
      expect(contextStr, contains("South Zone:"));
      expect(contextStr, contains("Gate A:"));
    });

    test(
      'buildContextString filters non-accessible zones if wheelchair mode is true',
      () {
        final contextStr = service.buildContextString(
          data: mockData,
          userZone: "North",
          wheelchairMode: true,
          sensoryMode: false,
        );

        // North Zone is not wheelchair accessible, so it should be omitted
        expect(contextStr, isNot(contains("North Zone:")));
        expect(contextStr, contains("South Zone:")); // South Zone remains
      },
    );

    test('buildContextString flags sensory rooms if sensoryMode is true', () {
      final contextStr = service.buildContextString(
        data: mockData,
        userZone: "North",
        wheelchairMode: false,
        sensoryMode: true,
      );

      expect(contextStr, contains("Sensory-friendly: Yes ✓"));
    });
  });
}
