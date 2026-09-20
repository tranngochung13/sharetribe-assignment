import 'package:bloc_test/bloc_test.dart';
import 'package:marketplace_app/features/auth/bloc/auth_bloc.dart';
import 'package:marketplace_app/features/auth/bloc/auth_event.dart';
import 'package:marketplace_app/features/auth/bloc/auth_state.dart';
import '../../../helpers/mock_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late MockAuthRepository authRepository;

  setUp(() {
    authRepository = MockAuthRepository();
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login succeeds',
      build: () {
        when(
          () => authRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async {});

        return AuthBloc(authRepository: authRepository);
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'customer@example.com',
          password: 'password',
        ),
      ),
      expect: () => [const AuthLoading(), const AuthAuthenticated()],
      verify: (_) {
        verify(
          () => authRepository.login(
            email: 'customer@example.com',
            password: 'password',
          ),
        ).called(1);
      },
    );
  });
}
