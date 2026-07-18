/// Crowd density level for a stadium zone
enum CrowdLevel { low, medium, high }

/// A food stall within a zone
class FoodStall {
  final String name;
  final int queueMins;
  final bool isOpen;

  const FoodStall({
    required this.name,
    required this.queueMins,
    required this.isOpen,
  });

  factory FoodStall.fromJson(Map<String, dynamic> json) {
    return FoodStall(
      name: json['name'] as String,
      queueMins: json['queue_mins'] as int,
      isOpen: json['is_open'] as bool,
    );
  }
}

/// A stadium zone (North / South / East / West)
class ZoneData {
  final String id;
  final String displayName;
  final List<String> sections;
  final int foodQueueMins;
  final int restroomQueueMins;
  final int merchQueueMins;
  final CrowdLevel crowdLevel;
  final int crowdPercent;
  final bool hasElevator;
  final bool isWheelchairAccessible;
  final bool isSensoryFriendly;
  final List<FoodStall> foodStalls;
  final Map<String, int> walkTimes;

  const ZoneData({
    required this.id,
    required this.displayName,
    required this.sections,
    required this.foodQueueMins,
    required this.restroomQueueMins,
    this.merchQueueMins = 0,
    required this.crowdLevel,
    required this.crowdPercent,
    required this.hasElevator,
    required this.isWheelchairAccessible,
    required this.isSensoryFriendly,
    required this.foodStalls,
    required this.walkTimes,
  });

  factory ZoneData.fromJson(String id, Map<String, dynamic> json) {
    final crowdStr = json['crowd_level'] as String;
    final crowdLevel = switch (crowdStr) {
      'low' => CrowdLevel.low,
      'high' => CrowdLevel.high,
      _ => CrowdLevel.medium,
    };

    final stallsJson = json['food_stalls'] as List<dynamic>? ?? [];
    final stalls = stallsJson
        .map((s) => FoodStall.fromJson(s as Map<String, dynamic>))
        .toList();

    final walkTimesJson = json['walk_times'] as Map<String, dynamic>? ?? {};
    final walkTimes = walkTimesJson.map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );

    return ZoneData(
      id: id,
      displayName: json['display_name'] as String,
      sections: (json['sections'] as List<dynamic>).cast<String>(),
      foodQueueMins: json['food_queue_mins'] as int,
      restroomQueueMins: json['restroom_queue_mins'] as int,
      merchQueueMins: (json['merch_queue_mins'] as num?)?.toInt() ?? 0,
      crowdLevel: crowdLevel,
      crowdPercent: json['crowd_percent'] as int,
      hasElevator: json['has_elevator'] as bool,
      isWheelchairAccessible: json['is_wheelchair_accessible'] as bool,
      isSensoryFriendly: json['is_sensory_friendly'] as bool,
      foodStalls: stalls,
      walkTimes: walkTimes,
    );
  }

  ZoneData copyWith({
    String? id,
    String? displayName,
    List<String>? sections,
    int? foodQueueMins,
    int? restroomQueueMins,
    int? merchQueueMins,
    CrowdLevel? crowdLevel,
    int? crowdPercent,
    bool? hasElevator,
    bool? isWheelchairAccessible,
    bool? isSensoryFriendly,
    List<FoodStall>? foodStalls,
    Map<String, int>? walkTimes,
  }) {
    return ZoneData(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      sections: sections ?? this.sections,
      foodQueueMins: foodQueueMins ?? this.foodQueueMins,
      restroomQueueMins: restroomQueueMins ?? this.restroomQueueMins,
      merchQueueMins: merchQueueMins ?? this.merchQueueMins,
      crowdLevel: crowdLevel ?? this.crowdLevel,
      crowdPercent: crowdPercent ?? this.crowdPercent,
      hasElevator: hasElevator ?? this.hasElevator,
      isWheelchairAccessible:
          isWheelchairAccessible ?? this.isWheelchairAccessible,
      isSensoryFriendly: isSensoryFriendly ?? this.isSensoryFriendly,
      foodStalls: foodStalls ?? this.foodStalls,
      walkTimes: walkTimes ?? this.walkTimes,
    );
  }

  String get crowdLevelLabel {
    return switch (crowdLevel) {
      CrowdLevel.low => 'Low',
      CrowdLevel.medium => 'Moderate',
      CrowdLevel.high => 'High',
    };
  }
}

/// A stadium entry gate
class GateData {
  final String name;
  final int queueMins;
  final bool isOpen;
  final bool isWheelchairAccessible;
  final String location;
  final List<String> transportNearby;

  const GateData({
    required this.name,
    required this.queueMins,
    required this.isOpen,
    required this.isWheelchairAccessible,
    required this.location,
    required this.transportNearby,
  });

  GateData copyWith({
    String? name,
    int? queueMins,
    bool? isOpen,
    bool? isWheelchairAccessible,
    String? location,
    List<String>? transportNearby,
  }) {
    return GateData(
      name: name ?? this.name,
      queueMins: queueMins ?? this.queueMins,
      isOpen: isOpen ?? this.isOpen,
      isWheelchairAccessible:
          isWheelchairAccessible ?? this.isWheelchairAccessible,
      location: location ?? this.location,
      transportNearby: transportNearby ?? this.transportNearby,
    );
  }

  factory GateData.fromJson(String name, Map<String, dynamic> json) {
    return GateData(
      name: name,
      queueMins: json['queue_mins'] as int,
      isOpen: json['is_open'] as bool,
      isWheelchairAccessible: json['is_wheelchair_accessible'] as bool,
      location: json['location'] as String,
      transportNearby: (json['transport_nearby'] as List<dynamic>)
          .cast<String>(),
    );
  }
}

/// A stadium-wide alert
class StadiumAlert {
  final String id;
  final String type;
  final String message;
  final String severity;

  const StadiumAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.severity,
  });

  factory StadiumAlert.fromJson(Map<String, dynamic> json) {
    return StadiumAlert(
      id: json['id'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String,
    );
  }
}

/// A parking lot summary for the stadium campus
class ParkingLotStatus {
  final String name;
  final int total;
  final int available;
  final int accessibleAvailable;

  const ParkingLotStatus({
    required this.name,
    required this.total,
    required this.available,
    required this.accessibleAvailable,
  });

  factory ParkingLotStatus.fromJson(String name, Map<String, dynamic> json) {
    return ParkingLotStatus(
      name: name,
      total: (json['total'] as num).toInt(),
      available: (json['available'] as num).toInt(),
      accessibleAvailable: (json['accessible_available'] as num).toInt(),
    );
  }
}

/// Root data model representing the full stadium status
class StadiumData {
  final String stadiumName;
  final String event;
  final String match;
  final DateTime kickoff;
  final DateTime lastUpdated;
  final Map<String, ZoneData> zones;
  final Map<String, GateData> gates;
  final List<StadiumAlert> alerts;
  final List<String> firstAidLocations;
  final String? guestServicesLocation;
  final Map<String, ParkingLotStatus> parkingLots;
  final int capacity;

  const StadiumData({
    required this.stadiumName,
    required this.event,
    required this.match,
    required this.kickoff,
    required this.lastUpdated,
    required this.zones,
    required this.gates,
    required this.alerts,
    this.firstAidLocations = const [],
    this.guestServicesLocation,
    this.parkingLots = const {},
    required this.capacity,
  });

  StadiumData copyWith({
    String? stadiumName,
    String? event,
    String? match,
    DateTime? kickoff,
    DateTime? lastUpdated,
    Map<String, ZoneData>? zones,
    Map<String, GateData>? gates,
    List<StadiumAlert>? alerts,
    List<String>? firstAidLocations,
    String? guestServicesLocation,
    Map<String, ParkingLotStatus>? parkingLots,
    int? capacity,
  }) {
    return StadiumData(
      stadiumName: stadiumName ?? this.stadiumName,
      event: event ?? this.event,
      match: match ?? this.match,
      kickoff: kickoff ?? this.kickoff,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      zones: zones ?? this.zones,
      gates: gates ?? this.gates,
      alerts: alerts ?? this.alerts,
      firstAidLocations: firstAidLocations ?? this.firstAidLocations,
      guestServicesLocation:
          guestServicesLocation ?? this.guestServicesLocation,
      parkingLots: parkingLots ?? this.parkingLots,
      capacity: capacity ?? this.capacity,
    );
  }

  factory StadiumData.fromJson(Map<String, dynamic> json) {
    final zonesJson = json['zones'] as Map<String, dynamic>;
    final zones = zonesJson.map(
      (k, v) => MapEntry(k, ZoneData.fromJson(k, v as Map<String, dynamic>)),
    );

    final gatesJson = json['gates'] as Map<String, dynamic>;
    final gates = gatesJson.map(
      (k, v) => MapEntry(k, GateData.fromJson(k, v as Map<String, dynamic>)),
    );

    final alertsJson = json['alerts'] as List<dynamic>? ?? [];
    final alerts = alertsJson
        .map((a) => StadiumAlert.fromJson(a as Map<String, dynamic>))
        .toList();
    final servicesJson = json['services'] as Map<String, dynamic>? ?? {};
    final firstAidJson = servicesJson['first_aid'] as List<dynamic>? ?? [];
    final firstAidLocations = firstAidJson
        .whereType<Map<String, dynamic>>()
        .where((s) => s['is_staffed'] != false)
        .map((s) => s['location'] as String)
        .toList();
    final parkingJson = json['transport'] as Map<String, dynamic>? ?? {};
    final parkingLotsJson =
        parkingJson['parking'] as Map<String, dynamic>? ?? {};
    final parkingLots = parkingLotsJson.map(
      (k, v) =>
          MapEntry(k, ParkingLotStatus.fromJson(k, v as Map<String, dynamic>)),
    );

    return StadiumData(
      stadiumName: json['stadium'] as String,
      event: json['event'] as String,
      match: json['match'] as String,
      kickoff: DateTime.parse(json['kickoff'] as String),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      zones: zones,
      gates: gates,
      alerts: alerts,
      firstAidLocations: firstAidLocations,
      guestServicesLocation: servicesJson['guest_services'] as String?,
      parkingLots: parkingLots,
      capacity: json['capacity'] as int,
    );
  }

  /// Returns zones sorted by food queue (shortest first)
  List<MapEntry<String, ZoneData>> get zonesByFoodQueue {
    final entries = zones.entries.toList();
    entries.sort(
      (a, b) => a.value.foodQueueMins.compareTo(b.value.foodQueueMins),
    );
    return entries;
  }

  /// Returns gates sorted by queue time (shortest first)
  List<MapEntry<String, GateData>> get gatesByQueue {
    final entries = gates.entries.toList();
    entries.sort((a, b) => a.value.queueMins.compareTo(b.value.queueMins));
    return entries;
  }

  /// Returns zones sorted by merchandise queue (shortest first)
  List<MapEntry<String, ZoneData>> get zonesByMerchQueue {
    final entries = zones.entries.toList();
    entries.sort(
      (a, b) => a.value.merchQueueMins.compareTo(b.value.merchQueueMins),
    );
    return entries;
  }

  /// Returns zones that are wheelchair accessible (with elevator)
  List<MapEntry<String, ZoneData>> get accessibleZones {
    return zones.entries
        .where((e) => e.value.isWheelchairAccessible && e.value.hasElevator)
        .toList();
  }

  /// Returns gates that are wheelchair accessible
  List<MapEntry<String, GateData>> get accessibleGates {
    return gates.entries
        .where((e) => e.value.isWheelchairAccessible && e.value.isOpen)
        .toList();
  }
}
