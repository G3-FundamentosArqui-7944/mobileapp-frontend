import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => const [];
}

/// Verifica si hay sesión persistida al iniciar la app.
class AuthInitialized extends AuthEvent {
  const AuthInitialized();
}

/// Login con email + password.
class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

/// Registro de un atleta o coach. [asCoach] = true para crear con ROLE_COACH.
class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phone;
  final bool asCoach;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.asCoach,
  });

  @override
  List<Object?> get props => [email, password, firstName, lastName, phone, asCoach];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Disparado por ApiClient.onSessionExpired cuando el refresh-token también falla.
class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}
