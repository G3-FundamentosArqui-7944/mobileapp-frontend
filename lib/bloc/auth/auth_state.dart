import 'package:equatable/equatable.dart';

import '../../data/models/auth_models.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => const [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AuthenticatedUser user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user.id, user.accessToken];
}

class AuthUnauthenticated extends AuthState {
  /// Mensaje opcional (ej. "Sesión expirada, vuelve a entrar").
  final String? message;
  const AuthUnauthenticated({this.message});
  @override
  List<Object?> get props => [message];
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

/// Registro exitoso. La UI muestra un mensaje y redirige al login.
class AuthSignUpSuccess extends AuthState {
  final UserSummary user;
  const AuthSignUpSuccess(this.user);
  @override
  List<Object?> get props => [user.id];
}
