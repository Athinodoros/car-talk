import '../config/api_endpoints.dart';
import 'api_client.dart';

class ReportRepository {
  ReportRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> createReport({
    required String reportedMessageId,
    required String reason,
    String? description,
  }) async {
    await _apiClient.dio.post<Map<String, dynamic>>(
      ApiEndpoints.reportsCreate,
      data: {
        'reportedMessageId': reportedMessageId,
        'reason': reason,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
  }
}
