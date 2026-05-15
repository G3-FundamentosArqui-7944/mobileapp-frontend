import '../api/api_client.dart';
import '../models/matchmaking_models.dart';

/// Búsqueda, recomendaciones y gestión de disponibilidad de coaches.
class CoachesRepository {
  final ApiClient _api;

  CoachesRepository({required ApiClient api}) : _api = api;

  Future<List<CoachProfile>> search({
    List<String>? specialties,
    int? minYearsOfExperience,
    num? maxHourlyRate,
    num? minRating,
    bool onlyAccepting = true,
  }) async {
    final query = <String, dynamic>{
      if (specialties != null && specialties.isNotEmpty) 'specialties': specialties.join(','),
      if (minYearsOfExperience != null) 'minYearsOfExperience': minYearsOfExperience,
      if (maxHourlyRate != null) 'maxHourlyRate': maxHourlyRate,
      if (minRating != null) 'minRating': minRating,
      'onlyAccepting': onlyAccepting,
    };
    final list = await _api.get('/coaches/search', query: query) as List<dynamic>;
    return list.map((e) => CoachProfile.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CoachProfile>> recommendationsFor(int athleteId, {int limit = 10}) async {
    final list = await _api.get(
      '/coaches/recommendations/$athleteId',
      query: {'limit': limit},
    ) as List<dynamic>;
    return list.map((e) => CoachProfile.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CoachProfile> addAvailability(int coachId, AddAvailabilityRequest req) async {
    final json = await _api.post('/coaches/$coachId/availability', body: req.toJson())
        as Map<String, dynamic>;
    return CoachProfile.fromJson(json);
  }
}
