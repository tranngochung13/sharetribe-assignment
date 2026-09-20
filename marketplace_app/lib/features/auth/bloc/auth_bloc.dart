import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  StreamSubscription<void>? _sessionSubscription;

  AuthBloc({required this.authRepository, Stream<void>? sessionExpired})
    : super(const AuthInitial()) {
    on<AuthSessionExpired>((event, emit) => emit(const AuthUnauthenticated()));
    _sessionSubscription = sessionExpired?.listen(
      (_) => add(const AuthSessionExpired()),
    );
    on<AuthStatusChecked>(_onStatusChecked);
    on<AuthLoginRequested>(_onLogin);
    on<AuthLogoutRequested>(_onLogout);
  }

  @override
  Future<void> close() async {
    await _sessionSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await authRepository.login(email: event.email, password: event.password);

      emit(const AuthAuthenticated());
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;

      if (statusCode == 401) {
        emit(const AuthFailure('Invalid email or password.'));
        return;
      }

      emit(
        AuthFailure(
          e.response?.data?.toString() ??
              'Unable to sign in. Please try again.',
        ),
      );
    } catch (_) {
      emit(const AuthFailure('Something went wrong.'));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.logout();

    emit(const AuthUnauthenticated());
  }

  Future<void> _onStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isAuthenticated = await authRepository.isAuthenticated();
      emit(
        isAuthenticated
            ? const AuthAuthenticated()
            : const AuthUnauthenticated(),
      );
    } catch (_) {
      // Allow signing in again if the saved session cannot be read.
      emit(const AuthUnauthenticated());
    }
  }
}
