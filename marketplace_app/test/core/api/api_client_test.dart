import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marketplace_app/core/api/api_client.dart';
import 'package:marketplace_app/core/storage/token_storage.dart';
import 'package:marketplace_app/features/auth/data/auth_service.dart';

class MockStorage extends Mock implements TokenStorage {}

class MockAuthService extends Mock implements AuthService {}

class UnauthorizedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{}',
    401,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  for (final status in [400, 401, 503]) {
    test('refresh status $status only expires rejected credentials', () async {
      final storage = MockStorage();
      final service = MockAuthService();
      when(() => storage.getAccessToken()).thenAnswer((_) async => 'expired');
      when(() => storage.getRefreshToken()).thenAnswer((_) async => 'refresh');
      when(() => storage.clear()).thenAnswer((_) async {});
      final request = RequestOptions(path: '/v1/auth/token');
      when(() => service.refreshToken('refresh')).thenThrow(
        DioException(
          requestOptions: request,
          response: Response(requestOptions: request, statusCode: status),
        ),
      );
      final client = ApiClient(tokenStorage: storage, authService: service);
      client.dio.httpClientAdapter = UnauthorizedAdapter();
      var expired = false;
      final subscription = client.sessionExpired.listen((_) => expired = true);
      await expectLater(
        client.dio.get('/v1/api/listings/query'),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(expired, status != 503);
      if (status != 503) {
        verify(() => storage.clear()).called(1);
      } else {
        verifyNever(() => storage.clear());
      }
      await subscription.cancel();
      await client.dispose();
    });
  }
}
