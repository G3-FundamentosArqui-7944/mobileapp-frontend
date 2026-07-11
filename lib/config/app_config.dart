/// Configuración del entorno BodyMatch AI.
///
/// Arquitectura híbrida:
/// - IAM y Videos viven en microservicios detrás del API Gateway (puerto 8080).
/// - El resto del dominio (matchmaking, training, nutrition, membership, profiles)
///   sigue en el monolito Spring Boot (puerto 8091).
///
/// Los repositorios eligen [microservicesBaseUrl] o [monolithBaseUrl] según
/// a qué bounded context pertenezcan; el refresh-token va siempre a microservicios
/// porque IAM emite y persiste los refresh tokens.
class AppConfig {
  static const Environment currentEnvironment = Environment.production;

  static const int _microservicesPort = 8080;
  static const int _monolithPort = 8091;

  /// Gateway de microservicios (IAM + Videos).
  static String get microservicesBaseUrl => _baseUrlFor(_microservicesPort);

  /// Monolito Spring Boot (todo el resto del dominio).
  static String get monolithBaseUrl => _baseUrlFor(_monolithPort);

  /// Endpoint contra el que se renueva el access token (siempre IAM).
  static String get refreshBaseUrl => microservicesBaseUrl;

  /// Alias histórico: ahora apunta al monolito porque era el comportamiento previo.
  /// Conservado por si algún código antiguo lo referencia.
  @Deprecated('Use microservicesBaseUrl o monolithBaseUrl según el repo.')
  static String get apiBaseUrl => monolithBaseUrl;

  static String _baseUrlFor(int port) {
    switch (currentEnvironment) {
      case Environment.androidEmulator:
        return 'http://10.0.2.2:$port/api/v1';
      case Environment.iosSimulator:
        return 'http://localhost:$port/api/v1';
      case Environment.physicalDevice:
        // Usamos adb reverse (USB), por eso el celular ve la PC como localhost.
        // Si en vez de USB usas la misma red WiFi, cambia esto por la IP LAN de la PC.
        return 'http://127.0.0.1:$port/api/v1';
      case Environment.production:
        // Túnel ngrok temporal hacia el api-gateway local mientras no hay un
        // deploy persistente en la nube. Cambia esto cuando migren a Oracle/Render.
        return 'https://untoasted-slimy-caress.ngrok-free.dev/api/v1';
    }
  }

  static bool get isDebug => currentEnvironment != Environment.production;
  static bool get enableLogs => isDebug;

  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
}

enum Environment {
  androidEmulator,
  iosSimulator,
  physicalDevice,
  production,
}
