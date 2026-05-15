import '../api/api_client.dart';
import '../models/training_models.dart';

class TrainingRepository {
  final ApiClient _api;

  TrainingRepository({required ApiClient api}) : _api = api;

  // Workout sessions
  Future<WorkoutSession> startSession(StartWorkoutSessionRequest req) async {
    final json = await _api.post('/workout-sessions', body: req.toJson()) as Map<String, dynamic>;
    return WorkoutSession.fromJson(json);
  }

  Future<WorkoutSession> addExercise(int sessionId, AddExerciseExecutionRequest req) async {
    final json = await _api.post('/workout-sessions/$sessionId/exercises', body: req.toJson())
        as Map<String, dynamic>;
    return WorkoutSession.fromJson(json);
  }

  Future<WorkoutSession> completeSession(int sessionId) async {
    final json = await _api.put('/workout-sessions/$sessionId/complete')
        as Map<String, dynamic>;
    return WorkoutSession.fromJson(json);
  }

  Future<WorkoutSession> getSession(int sessionId) async {
    final json = await _api.get('/workout-sessions/$sessionId') as Map<String, dynamic>;
    return WorkoutSession.fromJson(json);
  }

  Future<List<WorkoutSession>> sessionsByUser(int userId) async {
    final list = await _api.get('/workout-sessions/user/$userId') as List<dynamic>;
    return list.map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Performance metrics
  Future<PerformanceMetric> recordMetric(RecordPerformanceMetricRequest req) async {
    final json = await _api.post('/training-metrics/metrics', body: req.toJson())
        as Map<String, dynamic>;
    return PerformanceMetric.fromJson(json);
  }

  Future<List<PerformanceMetric>> metricsByUser(int userId, {String? type}) async {
    final list = await _api.get(
      '/training-metrics/metrics/user/$userId',
      query: {if (type != null) 'type': type},
    ) as List<dynamic>;
    return list.map((e) => PerformanceMetric.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Progress
  Future<ProgressRecord> registerProgress({
    required int userId,
    required String milestone,
    String? description,
    required DateTime achievedAt,
  }) async {
    final json = await _api.post('/training-metrics/progress', body: {
      'userId': userId,
      'milestone': milestone,
      if (description != null) 'description': description,
      'achievedAt': achievedAt.toUtc().toIso8601String(),
    }) as Map<String, dynamic>;
    return ProgressRecord.fromJson(json);
  }

  Future<List<ProgressRecord>> progressByUser(int userId) async {
    final list = await _api.get('/training-metrics/progress/user/$userId') as List<dynamic>;
    return list.map((e) => ProgressRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TrainingAnalytics> analyticsForUser(int userId) async {
    final json = await _api.get('/training-metrics/analytics/user/$userId') as Map<String, dynamic>;
    return TrainingAnalytics.fromJson(json);
  }
}
