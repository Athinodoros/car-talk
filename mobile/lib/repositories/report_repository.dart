import '../config/api_endpoints.dart';
import 'api_client.dart';

class ReportRepository {
  ReportRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> createReport({
    String? messageId,
    required String reason,
  }) async {
    await _apiClient.dio.post<Map<String, dynamic>>(
      ApiEndpoints.reportsCreate,
      data: {
        'messageId': ?messageId,
        'reason': reason,
      },
    );
  }
}
