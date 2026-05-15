/// Excepción base para errores que vienen de la capa HTTP.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic body;

  ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Lanzada cuando el refresh-token también es rechazado por el backend.
/// El AuthBloc debe escucharla para forzar logout.
class SessionExpiredException extends ApiException {
  SessionExpiredException([super.message = 'Sesión expirada'])
      : super(statusCode: 401);
}

/// Lanzada cuando no hay conectividad o el host no responde.
class NetworkException extends ApiException {
  NetworkException(super.message);
}
