import '../models/stadium_data_model.dart';
import '../services/mock_data_service.dart';

/// Repository interface handling access to stadium real-time operations data,
/// simulation of live IoT updates, and prompt context formatting.
abstract class StadiumRepository {
  /// Fetches the latest live stadium status representation.
  Future<StadiumData> getStadiumData();

  /// Simulates variation updates for crowd levels and queue durations.
  StadiumData simulateUpdate(StadiumData current);

  /// Formats stadium data details into a context block suitable for AI prompts.
  String buildContextString({
    required StadiumData data,
    required String userZone,
    required bool wheelchairMode,
    required bool sensoryMode,
  });
}

/// Concrete implementation of [StadiumRepository] delegating to [MockDataService].
class StadiumRepositoryImpl implements StadiumRepository {
  final MockDataService _mockDataService;

  StadiumRepositoryImpl(this._mockDataService);

  @override
  Future<StadiumData> getStadiumData() {
    return _mockDataService.loadStadiumData();
  }

  @override
  StadiumData simulateUpdate(StadiumData current) {
    return _mockDataService.simulateUpdate(current);
  }

  @override
  String buildContextString({
    required StadiumData data,
    required String userZone,
    required bool wheelchairMode,
    required bool sensoryMode,
  }) {
    return _mockDataService.buildContextString(
      data: data,
      userZone: userZone,
      wheelchairMode: wheelchairMode,
      sensoryMode: sensoryMode,
    );
  }
}
