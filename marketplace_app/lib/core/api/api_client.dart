import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/auth/data/auth_service.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final TokenStorage tokenStorage;
  final AuthService authService;

  late final Dio dio;
  final _sessionExpired = StreamController<void>.broadcast();
  Stream<void> get sessionExpired => _sessionExpired.stream;

  Future<void> _expireSession() async {
    try {
      await tokenStorage.clear();
    } finally {
      _sessionExpired.add(null);
    }
  }

  Future<void> dispose() async {
    dio.close();
    await _sessionExpired.close();
  }

  ApiClient({required this.tokenStorage, required this.authService}) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final accessToken = await tokenStorage.getAccessToken();
            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'bearer $accessToken';
            }
            handler.next(options);
          } catch (error) {
            handler.reject(DioException(requestOptions: options, error: error));
          }
        },

        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            handler.next(error);
            return;
          }

          // Prevent an infinite retry loop.
          if (error.requestOptions.extra['retried'] == true) {
            handler.next(error);
            return;
          }

          try {
            final refreshToken = await tokenStorage.getRefreshToken();

            if (refreshToken == null || refreshToken.isEmpty) {
              await _expireSession();
              handler.next(error);
              return;
            }

            final token = await authService.refreshToken(refreshToken);

            await tokenStorage.saveTokens(
              accessToken: token.accessToken,
              refreshToken: token.refreshToken,
            );

            final request = error.requestOptions;

            request.extra['retried'] = true;

            request.headers['Authorization'] = 'bearer ${token.accessToken}';

            final response = await dio.fetch(request);

            handler.resolve(response);
          } catch (failure) {
            // Connectivity/server errors should not discard a valid session.
            if (failure is DioException &&
                [400, 401, 403].contains(failure.response?.statusCode)) {
              try {
                await _expireSession();
              } catch (_) {
                // The UI must still leave the expired session if storage fails.
              }
            }
            handler.next(error);
          }
        },
      ),
    );
  }
}
