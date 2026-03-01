import '../config/api_endpoints.dart';
import '../models/plate.dart';
import 'api_client.dart';

class PlateRepository {
  PlateRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Plate>> listPlates() async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      ApiEndpoints.plates,
    );

    return response.data!
        .map((json) => Plate.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Plate> claimPlate({
    required String plateNumber,
    String? stateOrRegion,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      ApiEndpoints.plates,
      data: {
        'plateNumber': plateNumber,
        'stateOrRegion': ?stateOrRegion,
      },
    );

    return Plate.fromJson(response.data!);
  }

  Future<void> releasePlate(String id) async {
    await _apiClient.dio.delete<void>(
      ApiEndpoints.plateRelease(id),
    );
  }
}
