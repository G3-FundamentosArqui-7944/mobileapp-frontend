import '../api/api_client.dart';
import '../models/matchmaking_models.dart';

/// Acceso a los endpoints de perfiles de atleta y coach.
class ProfilesRepository {
  final ApiClient _api;

  ProfilesRepository({required ApiClient api}) : _api = api;

  // Athletes — /api/v1/athletes
  Future<AthleteProfile> createAthleteProfile(CreateAthleteProfileRequest request) async {
    final json = await _api.post('/athletes', body: request.toJson()) as Map<String, dynamic>;
    return AthleteProfile.fromJson(json);
  }

  Future<AthleteProfile?> getAthleteByUserId(int userId) async {
    try {
      final json = await _api.get('/athletes/$userId') as Map<String, dynamic>;
      return AthleteProfile.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // Coaches — /api/v1/coaches
  Future<CoachProfile> createCoachProfile(CreateCoachProfileRequest request) async {
    final json = await _api.post('/coaches', body: request.toJson()) as Map<String, dynamic>;
    return CoachProfile.fromJson(json);
  }

  Future<CoachProfile?> getCoachByUserId(int userId) async {
    try {
      final json = await _api.get('/coaches/$userId') as Map<String, dynamic>;
      return CoachProfile.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}
