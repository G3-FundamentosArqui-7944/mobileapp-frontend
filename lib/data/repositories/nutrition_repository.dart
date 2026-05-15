import 'dart:io';

import '../api/api_client.dart';
import '../models/nutrition_models.dart';

class NutritionRepository {
  final ApiClient _api;

  NutritionRepository({required ApiClient api}) : _api = api;

  // Plans
  Future<NutritionPlan> createPlan(CreateNutritionPlanRequest req) async {
    final json = await _api.post('/nutrition/plans', body: req.toJson()) as Map<String, dynamic>;
    return NutritionPlan.fromJson(json);
  }

  Future<NutritionPlan?> activePlanForUser(int userId) async {
    try {
      final json = await _api.get('/nutrition/plans/user/$userId/active') as Map<String, dynamic>;
      return NutritionPlan.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<NutritionPlan> deactivatePlan(int planId) async {
    final json = await _api.delete('/nutrition/plans/$planId') as Map<String, dynamic>;
    return NutritionPlan.fromJson(json);
  }

  // Analyses (subir foto y obtener detección IA)
  Future<NutritionAnalysis> analyzeImage({required int userId, required File image}) async {
    final json = await _api.uploadMultipart(
      path: '/nutrition/analyses',
      fields: {'userId': userId.toString()},
      file: image,
    ) as Map<String, dynamic>;
    return NutritionAnalysis.fromJson(json);
  }

  Future<NutritionAnalysis> getAnalysis(int analysisId) async {
    final json = await _api.get('/nutrition/analyses/$analysisId') as Map<String, dynamic>;
    return NutritionAnalysis.fromJson(json);
  }

  Future<List<NutritionAnalysis>> analysesByUser(int userId) async {
    final list = await _api.get('/nutrition/analyses/user/$userId') as List<dynamic>;
    return list.map((e) => NutritionAnalysis.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Meals
  Future<MealRecord> logMeal(LogMealRequest req) async {
    final json = await _api.post('/nutrition/meals', body: req.toJson()) as Map<String, dynamic>;
    return MealRecord.fromJson(json);
  }

  Future<List<MealRecord>> mealsByUser(int userId, {DateTime? from, DateTime? to}) async {
    final list = await _api.get(
      '/nutrition/meals/user/$userId',
      query: {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
    ) as List<dynamic>;
    return list.map((e) => MealRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MacroSummary> dailySummary(int userId, {DateTime? date}) async {
    final json = await _api.get(
      '/nutrition/meals/user/$userId/daily-summary',
      query: {
        if (date != null) 'date': date.toIso8601String().split('T').first,
      },
    ) as Map<String, dynamic>;
    return MacroSummary.fromJson(json);
  }
}
