import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../data/api/api_client.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/coaches_repository.dart';
import '../data/repositories/connection_requests_repository.dart';
import '../data/repositories/membership_repository.dart';
import '../data/repositories/nutrition_repository.dart';
import '../data/repositories/profiles_repository.dart';
import '../data/repositories/training_repository.dart';
import '../data/repositories/training_sessions_repository.dart';
import '../data/repositories/videos_repository.dart';
import '../data/storage/token_manager.dart';

/// Marcadores de tipo para distinguir los dos clientes HTTP en el árbol de
/// providers. Provider los indexa por tipo, así que un alias por subclase es
/// la forma más simple de inyectar dos `ApiClient` distintos.
class MicroservicesApiClient extends ApiClient {
  MicroservicesApiClient({required super.tokenManager})
      : super(baseUrl: AppConfig.microservicesBaseUrl);
}

class MonolithApiClient extends ApiClient {
  MonolithApiClient({required super.tokenManager})
      : super(
          baseUrl: AppConfig.monolithBaseUrl,
          refreshBaseUrl: AppConfig.refreshBaseUrl,
        );
}

/// Composición de dependencias raíz.
///
/// Todos los repositorios resuelven contra el gateway de microservicios
/// (`:8080`), que rutea por `Path` a cada servicio (`iam-service`,
/// `matchmaking-service`, `membership-service`, `nutrition-service`,
/// `training-service`, `videos-service`).
///
/// El [MonolithApiClient] se mantiene declarado por compatibilidad histórica,
/// pero ya no tiene consumidores.
class DependencyProvider extends StatelessWidget {
  final Widget child;

  const DependencyProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TokenManager>(create: (_) => TokenManager()),

        // Clientes HTTP — uno por backend.
        ProxyProvider<TokenManager, MicroservicesApiClient>(
          update: (_, tokens, previous) =>
              previous ?? MicroservicesApiClient(tokenManager: tokens),
          dispose: (_, client) => client.dispose(),
        ),
        ProxyProvider<TokenManager, MonolithApiClient>(
          update: (_, tokens, previous) =>
              previous ?? MonolithApiClient(tokenManager: tokens),
          dispose: (_, client) => client.dispose(),
        ),

        // ───── IAM ─────
        ProxyProvider2<MicroservicesApiClient, TokenManager, AuthRepository>(
          update: (_, api, tokens, __) => AuthRepository(api: api, tokens: tokens),
        ),

        // ───── Videos ─────
        ProxyProvider<MicroservicesApiClient, VideosRepository>(
          update: (_, api, __) => VideosRepository(api: api),
        ),

        // ───── Matchmaking (athletes / coaches / connections / sessions) ─────
        ProxyProvider<MicroservicesApiClient, ProfilesRepository>(
          update: (_, api, __) => ProfilesRepository(api: api),
        ),
        ProxyProvider<MicroservicesApiClient, CoachesRepository>(
          update: (_, api, __) => CoachesRepository(api: api),
        ),
        ProxyProvider<MicroservicesApiClient, ConnectionRequestsRepository>(
          update: (_, api, __) => ConnectionRequestsRepository(api: api),
        ),
        ProxyProvider<MicroservicesApiClient, TrainingSessionsRepository>(
          update: (_, api, __) => TrainingSessionsRepository(api: api),
        ),

        // ───── Training ─────
        ProxyProvider<MicroservicesApiClient, TrainingRepository>(
          update: (_, api, __) => TrainingRepository(api: api),
        ),

        // ───── Nutrition ─────
        ProxyProvider<MicroservicesApiClient, NutritionRepository>(
          update: (_, api, __) => NutritionRepository(api: api),
        ),

        // ───── Membership ─────
        ProxyProvider<MicroservicesApiClient, MembershipRepository>(
          update: (_, api, __) => MembershipRepository(api: api),
        ),
      ],
      child: child,
    );
  }
}
