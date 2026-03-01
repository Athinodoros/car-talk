import '../config/api_endpoints.dart';
import 'api_client.dart';

class DeviceRepository {
  DeviceRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> registerDevice(String token) async {
    await _apiClient.dio.post<Map<String, dynamic>>(
      ApiEndpoints.devicesRegister,
      data: {'token': token},
    );
  }

  Future<void> removeDevice(String token) async {
    await _apiClient.dio.delete<void>(
      ApiEndpoints.devicesRemove(token),
    );
  }
}
