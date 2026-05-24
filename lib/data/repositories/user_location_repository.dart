import '../models/user_location_model.dart';
import '../sources/local/user_location_local_data_source.dart';

class UserLocationRepository {
  final UserLocationLocalDataSource _local;

  UserLocationRepository(this._local);

  Future<UserLocationModel> saveSnapshot(UserLocationModel location) {
    return _local.saveSnapshot(location);
  }

  Future<List<UserLocationModel>> getLatestSnapshots() {
    return _local.getLatestSnapshots();
  }
}
