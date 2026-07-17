import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_genie/models/stadium_data_model.dart';

void main() {
  group('StadiumData Parsing Tests', () {
    final mockJson = {
      "stadium": "FIFA 2026 MetLife Stadium",
      "city": "East Rutherford, NJ",
      "event": "FIFA World Cup 2026 - Group Stage",
      "match": "Brazil vs Argentina",
      "kickoff": "2026-07-16T20:00:00-04:00",
      "capacity": 82500,
      "last_updated": "2026-07-16T01:30:00Z",
      "zones": {
        "North": {
          "display_name": "North Zone",
          "sections": ["101", "102"],
          "food_queue_mins": 15,
          "restroom_queue_mins": 2,
          "crowd_level": "high",
          "crowd_percent": 87,
          "has_elevator": true,
          "is_wheelchair_accessible": true,
          "is_sensory_friendly": false,
          "food_stalls": [
            {"name": "Pizza Palace", "queue_mins": 18, "is_open": true},
          ],
          "walk_times": {"South": 5},
        },
      },
      "gates": {
        "Gate A": {
          "queue_mins": 25,
          "is_open": true,
          "is_wheelchair_accessible": true,
          "location": "North entrance",
          "transport_nearby": ["Bus Stop A"],
        },
      },
      "alerts": [
        {
          "id": "alert_001",
          "type": "crowd",
          "zone": "North",
          "message": "North Zone concessions are very busy.",
          "severity": "warning",
        },
      ],
    };

    test('Parses complete JSON into StadiumData model successfully', () {
      final stadiumData = StadiumData.fromJson(mockJson);

      expect(stadiumData.stadiumName, equals("FIFA 2026 MetLife Stadium"));
      expect(stadiumData.event, equals("FIFA World Cup 2026 - Group Stage"));
      expect(stadiumData.match, equals("Brazil vs Argentina"));
      expect(stadiumData.capacity, equals(82500));
      expect(stadiumData.zones.length, equals(1));

      final northZone = stadiumData.zones['North']!;
      expect(northZone.displayName, equals("North Zone"));
      expect(northZone.crowdLevel, equals(CrowdLevel.high));
      expect(northZone.foodQueueMins, equals(15));
      expect(northZone.isWheelchairAccessible, isTrue);
      expect(northZone.hasElevator, isTrue);
      expect(northZone.isSensoryFriendly, isFalse);
      expect(northZone.foodStalls.length, equals(1));
      expect(northZone.foodStalls.first.name, equals("Pizza Palace"));

      expect(stadiumData.gates.length, equals(1));
      final gateA = stadiumData.gates['Gate A']!;
      expect(gateA.queueMins, equals(25));
      expect(gateA.isWheelchairAccessible, isTrue);
      expect(gateA.transportNearby.first, equals("Bus Stop A"));

      expect(stadiumData.alerts.length, equals(1));
      expect(
        stadiumData.alerts.first.message,
        equals("North Zone concessions are very busy."),
      );
    });

    test('Helper getters categorize zones and gates correctly', () {
      final stadiumData = StadiumData.fromJson(mockJson);

      expect(stadiumData.accessibleZones.length, equals(1));
      expect(stadiumData.accessibleGates.length, equals(1));
      expect(stadiumData.zonesByFoodQueue.first.key, equals('North'));
      expect(stadiumData.gatesByQueue.first.key, equals('Gate A'));
    });
  });
}
