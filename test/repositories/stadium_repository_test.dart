import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_genie/repositories/stadium_repository.dart';
import 'package:stadium_genie/services/mock_data_service.dart';
import 'package:stadium_genie/models/stadium_data_model.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up mock rootBundle asset loader for JSON status
  const mockJson = '''
  {
    "stadium_name": "MetLife Stadium",
    "event": "FIFA World Cup 2026",
    "match": "USA vs Italy",
    "kickoff": "2026-07-19T20:00:00Z",
    "capacity": 82500,
    "zones": {
      "North": {
        "display_name": "North Stands",
        "sections": ["101", "102"],
        "food_queue_mins": 10,
        "restroom_queue_mins": 5,
        "merch_queue_mins": 8,
        "crowd_level": "medium",
        "crowd_percent": 65,
        "has_elevator": true,
        "is_wheelchair_accessible": true,
        "is_sensory_friendly": false,
        "food_stalls": [
          {"name": "Pizza", "queue_mins": 10, "is_open": true}
        ],
        "walk_times": {"North": 0, "South": 10}
      }
    },
    "gates": {
      "Gate A": {
        "queue_mins": 12,
        "is_open": true,
        "is_wheelchair_accessible": true,
        "location": "North Side",
        "transport_nearby": ["NJ Transit", "Uber Dropoff"]
      }
    },
    "alerts": [],
    "services": {
      "first_aid": [
        {"location": "Section 112", "is_staffed": true}
      ]
    },
    "transport": {
      "parking": {
        "Lot A": {
          "total": 1000,
          "available": 450,
          "accessible_available": 30
        }
      }
    }
  }
  ''';

  group('StadiumRepository Tests', () {
    late StadiumRepository repository;
    late MockDataService service;

    setUp(() {
      service = MockDataService();
      repository = StadiumRepositoryImpl(service);

      // Program the asset channel to return our mock JSON
      const MethodChannel('flutter/assets')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'decodeImage') return null;
        return mockJson;
      });
    });

    test('getStadiumData loads parsed data matching JSON model representation', () async {
      final data = await repository.getStadiumData();
      expect(data.stadiumName, "MetLife Stadium");
      expect(data.zones.containsKey("North"), isTrue);
      expect(data.gates.containsKey("Gate A"), isTrue);
    });

    test('simulateUpdate fluctuates values safely inside reasonable bounds', () async {
      final initialData = await repository.getStadiumData();
      final updated = repository.simulateUpdate(initialData);

      expect(updated.lastUpdated.isAfter(initialData.lastUpdated) || updated.lastUpdated == initialData.lastUpdated, isTrue);
      
      final zone = updated.zones["North"]!;
      expect(zone.crowdPercent, greaterThanOrEqualTo(10));
      expect(zone.crowdPercent, lessThanOrEqualTo(100));
      expect(zone.foodQueueMins, greaterThanOrEqualTo(0));
      expect(zone.restroomQueueMins, greaterThanOrEqualTo(0));
    });

    test('buildContextString formats valid text structure with parameters matching user settings', () async {
      final data = await repository.getStadiumData();
      final ctx = repository.buildContextString(
        data: data,
        userZone: "North",
        wheelchairMode: false,
        sensoryMode: false,
      );

      expect(ctx, contains("=== REAL-TIME STADIUM STATUS ==="));
      expect(ctx, contains("North Zone:"));
      expect(ctx, contains("Crowd: medium"));
    });
  });
}
