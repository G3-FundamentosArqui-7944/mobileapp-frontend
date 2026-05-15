// Modelos de la capa IAM. Se serializan a mano (sin codegen) para que el
// proyecto compile sin pasar por `build_runner`.

class SignUpRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phone;
  final List<String>? roles;

  const SignUpRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.roles,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (phone != null) 'phone': phone,
        if (roles != null) 'roles': roles,
      };
}

class SignInRequest {
  final String email;
  final String password;

  const SignInRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

/// Resultado de POST /authentication/sign-in y /refresh-token.
/// Espejo de AuthenticatedUserResource del backend.
class AuthenticatedUser {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String accessToken;
  final String refreshToken;
  final List<String> roles;

  const AuthenticatedUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.accessToken,
    required this.refreshToken,
    required this.roles,
  });

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) => AuthenticatedUser(
        id: (json['id'] as num).toInt(),
        email: json['email'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'roles': roles,
      };

  bool get isAthlete => roles.contains('ROLE_ATHLETE');
  bool get isCoach => roles.contains('ROLE_COACH');
  bool get isAdmin => roles.contains('ROLE_ADMIN');

  String get fullName {
    final f = (firstName ?? '').trim();
    final l = (lastName ?? '').trim();
    final joined = [f, l].where((s) => s.isNotEmpty).join(' ');
    return joined.isEmpty ? email : joined;
  }
}

/// Resultado de POST /authentication/sign-up. Espejo de UserResource.
class UserSummary {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final bool active;
  final bool emailVerified;
  final List<String> roles;

  const UserSummary({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    required this.active,
    required this.emailVerified,
    required this.roles,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) => UserSummary(
        id: (json['id'] as num).toInt(),
        email: json['email'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        phone: json['phone'] as String?,
        active: json['active'] as bool? ?? true,
        emailVerified: json['emailVerified'] as bool? ?? false,
        roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      );
}
