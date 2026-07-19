import 'dart:convert';
import 'dart:math' as dart_math;
import 'package:flutter/services.dart';
import '../models/stadium_data_model.dart';

/// Service that loads and provides mock stadium IoT data from local JSON.
/// Simulates real-time sensor feeds without requiring a live backend.
class MockDataService {
  StadiumData? _cachedData;

  /// Loads stadium data from the bundled asset JSON file
  Future<StadiumData> loadStadiumData() async {
    if (_cachedData != null) return _cachedData!.copyWith();

    final jsonStr = await rootBundle.loadString(
      'assets/data/stadium_status.json',
    );
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    _cachedData = StadiumData.fromJson(json);
    return _cachedData!.copyWith();
  }

  /// Builds a structured context block to inject into the AI system prompt.
  ///
  /// [userZone] - the zone the fan is currently located in
  /// [wheelchairMode] - if true, only include accessible routes/zones
  /// [sensoryMode] - if true, flag sensory-friendly zones
  String buildContextString({
    required StadiumData data,
    required String userZone,
    required bool wheelchairMode,
    required bool sensoryMode,
  }) {
    final buf = StringBuffer();

    buf.writeln('=== REAL-TIME STADIUM STATUS ===');
    buf.writeln('Stadium: ${data.stadiumName}');
    buf.writeln('Event: ${data.event}');
    buf.writeln('Match: ${data.match}');
    buf.writeln('Kickoff: ${data.kickoff.toIso8601String()}');
    buf.writeln(
      'Minutes to kickoff: ${data.kickoff.difference(DateTime.now()).inMinutes}',
    );
    buf.writeln('User Current Location: $userZone Zone');
    buf.writeln('');

    buf.writeln('--- ZONE STATUS ---');
    for (final entry in data.zones.entries) {
      final zone = entry.value;
      // Skip non-accessible zones if wheelchair mode is on
      if (wheelchairMode && !zone.isWheelchairAccessible) continue;

      buf.writeln('${entry.key} Zone:');
      buf.writeln(
        '  Crowd: ${zone.crowdLevelLabel} (${zone.crowdPercent}% capacity)',
      );
      buf.writeln('  Food queue: ${zone.foodQueueMins} min');
      buf.writeln('  Restroom queue: ${zone.restroomQueueMins} min');
      buf.writeln('  Merchandise queue: ${zone.merchQueueMins} min');
      buf.writeln('  Elevator: ${zone.hasElevator ? "Yes" : "No"}');
      buf.writeln(
        '  Wheelchair accessible: ${zone.isWheelchairAccessible ? "Yes" : "No"}',
      );
      if (sensoryMode) {
        buf.writeln(
          '  Sensory-friendly: ${zone.isSensoryFriendly ? "Yes ✓" : "No"}',
        );
      }
      buf.writeln(
        '  Open food stalls: ${zone.foodStalls.where((f) => f.isOpen).map((f) => "${f.name} (${f.queueMins}min)").join(", ")}',
      );
      buf.writeln(
        '  Walk from $userZone: ${zone.walkTimes[userZone] ?? "?"} min',
      );
      buf.writeln('');
    }

    buf.writeln('--- GATE STATUS ---');
    for (final entry in data.gates.entries) {
      final gate = entry.value;
      if (wheelchairMode && !gate.isWheelchairAccessible) continue;
      buf.writeln(
        '${gate.name}: queue=${gate.queueMins} min, open=${gate.isOpen}, accessible=${gate.isWheelchairAccessible}',
      );
    }
    buf.writeln('');

    if (data.alerts.isNotEmpty) {
      buf.writeln('--- ACTIVE ALERTS ---');
      for (final alert in data.alerts) {
        buf.writeln('[${alert.severity.toUpperCase()}] ${alert.message}');
      }
    }

    if (data.firstAidLocations.isNotEmpty ||
        data.guestServicesLocation != null) {
      buf.writeln('');
      buf.writeln('--- EMERGENCY AND GUEST SERVICES ---');
      if (data.firstAidLocations.isNotEmpty) {
        buf.writeln(
          'First aid locations: ${data.firstAidLocations.join(", ")}',
        );
      }
      if (data.guestServicesLocation != null) {
        buf.writeln('Guest services: ${data.guestServicesLocation}');
      }
    }

    buf.writeln('');
    buf.writeln('--- TRANSPORT & PARKING ---');
    final transportSet = <String>{};
    for (final gate in data.gates.values) {
      transportSet.addAll(gate.transportNearby);
    }
    if (transportSet.isNotEmpty) {
      buf.writeln('Available transport: ${transportSet.join(", ")}');
    }
    if (data.parkingLots.isNotEmpty) {
      buf.writeln('Parking availability:');
      for (final lot in data.parkingLots.values) {
        buf.writeln(
          '  ${lot.name}: ${lot.available}/${lot.total} available, accessible spots ${lot.accessibleAvailable}',
        );
      }
    }

    buf.writeln('');
    buf.writeln('--- STAFF & VOLUNTEER INFO ---');
    buf.writeln('Volunteer Duty Roster:');
    buf.writeln('  North Zone: 12 Volunteers - Gate B Entry Support');
    buf.writeln('  South Zone: 8 Volunteers - Elevator Assist');
    buf.writeln('  East Zone: 15 Volunteers - Crowd Control');
    buf.writeln('  West Zone: 10 Volunteers - Sensory Room Support');

    return buf.toString();
  }

  /// Simulates real-time variations in stadium data
  StadiumData simulateUpdate(StadiumData current) {
    final random = dart_math.Random();

    // update zone crowd capacity percentages (+/- 1-5%, within 10-100%)
    // update zone food/restroom queue times (+/- 1-3 mins, keeping queues >= 0)
    final updatedZones = current.zones.map((key, zone) {
      final crowdDelta = random.nextBool()
          ? (random.nextInt(5) + 1)
          : -(random.nextInt(5) + 1);
      final newCrowdPercent = (zone.crowdPercent + crowdDelta).clamp(10, 100);

      final foodQueueDelta = random.nextBool()
          ? (random.nextInt(3) + 1)
          : -(random.nextInt(3) + 1);
      final newFoodQueue = dart_math.max(
        0,
        zone.foodQueueMins + foodQueueDelta,
      );

      final restroomQueueDelta = random.nextBool()
          ? (random.nextInt(3) + 1)
          : -(random.nextInt(3) + 1);
      final newRestroomQueue = dart_math.max(
        0,
        zone.restroomQueueMins + restroomQueueDelta,
      );

      return MapEntry(
        key,
        zone.copyWith(
          crowdPercent: newCrowdPercent,
          foodQueueMins: newFoodQueue,
          restroomQueueMins: newRestroomQueue,
        ),
      );
    });

    final updatedGates = current.gates.map((key, gate) {
      final queueDelta = random.nextBool()
          ? (random.nextInt(3) + 1)
          : -(random.nextInt(3) + 1);
      return MapEntry(
        key,
        gate.copyWith(queueMins: dart_math.max(0, gate.queueMins + queueDelta)),
      );
    });

    return current.copyWith(
      zones: updatedZones,
      gates: updatedGates,
      lastUpdated: DateTime.now(),
    );
  }
}
