import '../config/api_endpoints.dart';
import '../models/auth_response.dart';
import '../models/auth_tokens.dart';
import 'api_client.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String displayName,
    required String plateNumber,
    String? stateOrRegion,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      ApiEndpoints.authRegister,
      data: {
        'email': email,
        'password': password,
        'displayName': displayName,
        'plateNumber': plateNumber,
        'stateOrRegion': ?stateOrRegion,
      },
    );

    return AuthResponse.fromJson(response.data!);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      ApiEndpoints.authLogin,
      data: {
        'email': email,
        'password': password,
      },
    );

    return AuthResponse.fromJson(response.data!);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      ApiEndpoints.authRefresh,
      data: {'refreshToken': refreshToken},
    );

    return AuthTokens.fromJson(response.data!);
  }

  Future<void> logout() async {
    // No API call needed. Token cleanup is handled by the auth provider.
  }
}
