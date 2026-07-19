import '../models/stadium_data_model.dart';
import '../services/mock_data_service.dart';

abstract class StadiumRepository {
  Future<StadiumData> getStadiumData();
  StadiumData simulateUpdate(StadiumData current);
  String buildContextString({
    required StadiumData data,
    required String userZone,
    required bool wheelchairMode,
    required bool sensoryMode,
  });
}

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
