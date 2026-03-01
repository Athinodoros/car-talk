import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_endpoints.dart';
import '../config/env.dart';
import '../config/storage_keys.dart';

class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  final FlutterSecureStorage _storage;
  late final Dio _dio;

  Completer<void>? _refreshCompleter;

  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _storage.read(key: StorageKeys.accessToken);
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode != 401) {
      return handler.next(error);
    }

    final requestPath = error.requestOptions.path;
    if (requestPath == ApiEndpoints.authRefresh) {
      return handler.next(error);
    }

    // If a refresh is already in progress, wait for it and retry.
    if (_refreshCompleter != null) {
      try {
        await _refreshCompleter!.future;
        final retryResponse = await _retry(error.requestOptions);
        return handler.resolve(retryResponse);
      } on DioException catch (retryError) {
        return handler.next(retryError);
      }
    }

    _refreshCompleter = Completer<void>();

    try {
      final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
      if (refreshToken == null) {
        await _clearTokens();
        _refreshCompleter!.completeError(error);
        _refreshCompleter = null;
        return handler.next(error);
      }

      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data!;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      await _storage.write(
        key: StorageKeys.accessToken,
        value: newAccessToken,
      );
      await _storage.write(
        key: StorageKeys.refreshToken,
        value: newRefreshToken,
      );

      _refreshCompleter!.complete();
      _refreshCompleter = null;

      final retryResponse = await _retry(error.requestOptions);
      return handler.resolve(retryResponse);
    } on DioException {
      await _clearTokens();
      _refreshCompleter!.completeError(error);
      _refreshCompleter = null;
      return handler.next(error);
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
      ),
    );
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.userId);
    await _storage.delete(key: StorageKeys.userEmail);
    await _storage.delete(key: StorageKeys.userDisplayName);
  }
}
