import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import 'auth_token.dart';

class AuthService {
  final Dio _dio;

  AuthService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              headers: {
                'Accept': 'application/json',
                'Content-Type':
                    'application/x-www-form-urlencoded; charset=utf-8',
              },
            ),
          );

  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/v1/auth/token',
      data: {
        'client_id': AppConfig.clientId,
        'grant_type': 'password',
        'username': email,
        'password': password,
        'scope': 'user',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    return AuthToken.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<AuthToken> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      '/v1/auth/token',
      data: {
        'client_id': AppConfig.clientId,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    return AuthToken.fromJson(Map<String, dynamic>.from(response.data));
  }
}
