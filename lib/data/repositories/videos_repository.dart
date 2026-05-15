import 'dart:io';

import '../api/api_client.dart';
import '../models/videos_models.dart';

class VideosRepository {
  final ApiClient _api;

  VideosRepository({required ApiClient api}) : _api = api;

  /// Sube un video (multipart). El backend procesa de forma asíncrona.
  Future<ExerciseVideo> upload({
    required int userId,
    required String exerciseName,
    String? description,
    int? durationSeconds,
    required File file,
  }) async {
    final fields = <String, String>{
      'userId': userId.toString(),
      'exerciseName': exerciseName,
      if (description != null) 'description': description,
      if (durationSeconds != null) 'durationSeconds': durationSeconds.toString(),
    };
    final json = await _api.uploadMultipart(
      path: '/exercise-videos',
      fields: fields,
      file: file,
    ) as Map<String, dynamic>;
    return ExerciseVideo.fromJson(json);
  }

  /// Dispara el análisis IA sobre un video previamente subido.
  Future<ExerciseVideo> analyze(int videoId) async {
    final json = await _api.post('/exercise-videos/$videoId/analyze') as Map<String, dynamic>;
    return ExerciseVideo.fromJson(json);
  }

  Future<ExerciseVideo> getById(int videoId) async {
    final json = await _api.get('/exercise-videos/$videoId') as Map<String, dynamic>;
    return ExerciseVideo.fromJson(json);
  }

  Future<List<ExerciseVideo>> byUser(int userId) async {
    final list = await _api.get('/exercise-videos/user/$userId') as List<dynamic>;
    return list.map((e) => ExerciseVideo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ExerciseVideo>> analyzedByUser(int userId) async {
    final list = await _api.get('/exercise-videos/user/$userId/analyzed') as List<dynamic>;
    return list.map((e) => ExerciseVideo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> delete(int videoId) async {
    await _api.delete('/exercise-videos/$videoId');
  }
}
