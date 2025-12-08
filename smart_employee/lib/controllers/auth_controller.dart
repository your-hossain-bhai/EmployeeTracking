// auth_controller.dart
// Authentication Controller (BLoC)
// 
// This controller manages authentication state using flutter_bloc.
// It handles user login, registration, logout, and session management.

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../models/user_model.dart';

// ============ Events ============

/// Base class for authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check current authentication status
class AuthCheckRequested extends AuthEvent {}

/// Event to sign in with email and password
class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Event to register a new user
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  final String companyId;
  final UserRole role;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
    required this.companyId,
    this.role = UserRole.employee,
  });

  @override
  List<Object?> get props => [email, password, displayName, companyId, role];
}

/// Event to sign out
class AuthSignOutRequested extends AuthEvent {}

/// Event to request password reset
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Event to update user profile
class AuthProfileUpdateRequested extends AuthEvent {
  final UserModel user;

  const AuthProfileUpdateRequested({required this.user});

  @override
  List<Object?> get props => [user];
}

// ============ States ============

/// Base class for authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial authentication state
class AuthInitial extends AuthState {}

/// Authentication loading state
class AuthLoading extends AuthState {}

/// User is authenticated
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {}

/// Authentication error state
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Password reset email sent
class AuthPasswordResetSent extends AuthState {}

// ============ Controller ============

/// Authentication controller managing auth state
class AuthController extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  StreamSubscription<User?>? _authStateSubscription;

  AuthController({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    // Register event handlers
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthProfileUpdateRequested>(_onProfileUpdateRequested);

    // Listen to auth state changes
    _authStateSubscription = _authService.authStateChanges.listen(
      (user) {
        if (user == null) {
          // ignore: invalid_use_of_visible_for_testing_member
          emit(AuthUnauthenticated());
        }
      },
    );

    // Check initial auth state
    add(AuthCheckRequested());
  }

  /// Handle auth check request
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userProfile = await _authService.getUserProfile(currentUser.uid);
        if (userProfile != null) {
          emit(AuthAuthenticated(user: userProfile));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Handle sign in request
  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await _authService.signInWithEmail(
        email: event.email,
        password: event.password,
      );

      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthError(message: 'Failed to sign in'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Handle registration request
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await _authService.registerWithEmail(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
        companyId: event.companyId,
        role: event.role,
      );

      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthError(message: 'Failed to register'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Handle sign out request
  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _authService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Handle password reset request
  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _authService.sendPasswordResetEmail(event.email);
      emit(AuthPasswordResetSent());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Handle profile update request
  Future<void> _onProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      await _authService.updateUserProfile(event.user);
      emit(AuthAuthenticated(user: event.user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
      emit(currentState); // Restore previous state
    }
  }

  /// Get current user
  UserModel? get currentUser {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.user;
    }
    return null;
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
