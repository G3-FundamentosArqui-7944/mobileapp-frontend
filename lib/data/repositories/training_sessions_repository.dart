import '../api/api_client.dart';
import '../models/matchmaking_models.dart';

/// Sesiones de entrenamiento agendadas entre atleta y coach.
class TrainingSessionsRepository {
  final ApiClient _api;

  TrainingSessionsRepository({required ApiClient api}) : _api = api;

  Future<TrainingSession> schedule(ScheduleTrainingSessionRequest req) async {
    final json = await _api.post('/training-sessions', body: req.toJson())
        as Map<String, dynamic>;
    return TrainingSession.fromJson(json);
  }

  Future<TrainingSession> complete(int sessionId, {String? coachNotes}) async {
    final json = await _api.put(
      '/training-sessions/$sessionId/complete',
      body: {'coachNotes': coachNotes ?? ''},
    ) as Map<String, dynamic>;
    return TrainingSession.fromJson(json);
  }

  Future<TrainingSession> cancel(int sessionId) async {
    final json = await _api.delete('/training-sessions/$sessionId') as Map<String, dynamic>;
    return TrainingSession.fromJson(json);
  }

  Future<List<TrainingSession>> byAthlete(int athleteId) async {
    final list = await _api.get('/training-sessions/athlete/$athleteId') as List<dynamic>;
    return list.map((e) => TrainingSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TrainingSession>> byCoach(int coachId) async {
    final list = await _api.get('/training-sessions/coach/$coachId') as List<dynamic>;
    return list.map((e) => TrainingSession.fromJson(e as Map<String, dynamic>)).toList();
  }
}
