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
  final MockDataService _service;

  StadiumRepositoryImpl(this._service);

  @override
  Future<StadiumData> getStadiumData() => _service.loadStadiumData();

  @override
  StadiumData simulateUpdate(StadiumData current) =>
      _service.simulateUpdate(current);

  @override
  String buildContextString({
    required StadiumData data,
    required String userZone,
    required bool wheelchairMode,
    required bool sensoryMode,
  }) {
    return _service.buildContextString(
      data: data,
      userZone: userZone,
      wheelchairMode: wheelchairMode,
      sensoryMode: sensoryMode,
    );
  }
}
