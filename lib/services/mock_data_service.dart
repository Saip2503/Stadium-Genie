import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/stadium_data_model.dart';

/// Service that loads and provides mock stadium IoT data from local JSON.
/// Simulates real-time sensor feeds without requiring a live backend.
class MockDataService {
  StadiumData? _cachedData;

  /// Loads stadium data from the bundled asset JSON file
  Future<StadiumData> loadStadiumData() async {
    if (_cachedData != null) return _cachedData!;

    final jsonStr = await rootBundle.loadString(
      'assets/data/stadium_status.json',
    );
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    _cachedData = StadiumData.fromJson(json);
    return _cachedData!;
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

    return buf.toString();
  }
}
