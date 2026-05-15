// Modelos del bounded context Nutrition (planes, comidas, análisis IA).

class MacroSummary {
  final num calories;
  final num proteinGrams;
  final num carbohydratesGrams;
  final num fatGrams;
  final num fiberGrams;

  const MacroSummary({
    required this.calories,
    required this.proteinGrams,
    required this.carbohydratesGrams,
    required this.fatGrams,
    required this.fiberGrams,
  });

  factory MacroSummary.fromJson(Map<String, dynamic> json) => MacroSummary(
        calories: (json['calories'] as num?) ?? 0,
        proteinGrams: (json['proteinGrams'] as num?) ?? 0,
        carbohydratesGrams: (json['carbohydratesGrams'] as num?) ?? 0,
        fatGrams: (json['fatGrams'] as num?) ?? 0,
        fiberGrams: (json['fiberGrams'] as num?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'proteinGrams': proteinGrams,
        'carbohydratesGrams': carbohydratesGrams,
        'fatGrams': fatGrams,
        'fiberGrams': fiberGrams,
      };

  static const empty = MacroSummary(
    calories: 0,
    proteinGrams: 0,
    carbohydratesGrams: 0,
    fatGrams: 0,
    fiberGrams: 0,
  );
}

class FoodDetection {
  final int id;
  final String foodName;
  final num portionGrams;
  final MacroSummary macros;
  final num? confidence;

  const FoodDetection({
    required this.id,
    required this.foodName,
    required this.portionGrams,
    required this.macros,
    this.confidence,
  });

  factory FoodDetection.fromJson(Map<String, dynamic> json) => FoodDetection(
        id: (json['id'] as num).toInt(),
        foodName: json['foodName'] as String,
        portionGrams: json['portionGrams'] as num,
        macros: MacroSummary.fromJson(json['macros'] as Map<String, dynamic>),
        confidence: json['confidence'] as num?,
      );
}

class NutritionAnalysis {
  final int id;
  final int userId;
  final String? imageStorageUrl;
  final String? summary;
  final MacroSummary totalMacros;
  final String status;
  final String? failureReason;
  final String? aiModelVersion;
  final DateTime? analyzedAt;
  final List<FoodDetection> detectedFoods;

  const NutritionAnalysis({
    required this.id,
    required this.userId,
    this.imageStorageUrl,
    this.summary,
    required this.totalMacros,
    required this.status,
    this.failureReason,
    this.aiModelVersion,
    this.analyzedAt,
    required this.detectedFoods,
  });

  factory NutritionAnalysis.fromJson(Map<String, dynamic> json) => NutritionAnalysis(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        imageStorageUrl: json['imageStorageUrl'] as String?,
        summary: json['summary'] as String?,
        totalMacros: json['totalMacros'] == null
            ? MacroSummary.empty
            : MacroSummary.fromJson(json['totalMacros'] as Map<String, dynamic>),
        status: json['status'] as String,
        failureReason: json['failureReason'] as String?,
        aiModelVersion: json['aiModelVersion'] as String?,
        analyzedAt: json['analyzedAt'] == null ? null : DateTime.tryParse(json['analyzedAt'] as String),
        detectedFoods: (json['detectedFoods'] as List<dynamic>?)
                ?.map((e) => FoodDetection.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class NutritionPlan {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final MacroSummary dailyTargets;
  final DateTime startDate;
  final DateTime? endDate;
  final bool active;

  const NutritionPlan({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.dailyTargets,
    required this.startDate,
    this.endDate,
    required this.active,
  });

  factory NutritionPlan.fromJson(Map<String, dynamic> json) => NutritionPlan(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        name: json['name'] as String,
        description: json['description'] as String?,
        dailyTargets: MacroSummary.fromJson(json['dailyTargets'] as Map<String, dynamic>),
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] == null ? null : DateTime.tryParse(json['endDate'] as String),
        active: json['active'] as bool? ?? true,
      );
}

class CreateNutritionPlanRequest {
  final int userId;
  final String name;
  final String? description;
  final MacroSummary dailyTargets;
  final DateTime startDate;
  final DateTime? endDate;

  const CreateNutritionPlanRequest({
    required this.userId,
    required this.name,
    this.description,
    required this.dailyTargets,
    required this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        if (description != null) 'description': description,
        'dailyTargets': dailyTargets.toJson(),
        'startDate': startDate.toUtc().toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toUtc().toIso8601String(),
      };
}

class MealRecord {
  final int id;
  final int userId;
  final String mealType;
  final String? description;
  final MacroSummary macros;
  final DateTime consumedAt;
  final int? sourceAnalysisId;

  const MealRecord({
    required this.id,
    required this.userId,
    required this.mealType,
    this.description,
    required this.macros,
    required this.consumedAt,
    this.sourceAnalysisId,
  });

  factory MealRecord.fromJson(Map<String, dynamic> json) => MealRecord(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        mealType: json['mealType'] as String,
        description: json['description'] as String?,
        macros: MacroSummary.fromJson(json['macros'] as Map<String, dynamic>),
        consumedAt: DateTime.parse(json['consumedAt'] as String),
        sourceAnalysisId: (json['sourceAnalysisId'] as num?)?.toInt(),
      );
}

class LogMealRequest {
  final int userId;
  final String mealType;
  final String? description;
  final MacroSummary macros;
  final DateTime consumedAt;
  final int? sourceAnalysisId;

  const LogMealRequest({
    required this.userId,
    required this.mealType,
    this.description,
    required this.macros,
    required this.consumedAt,
    this.sourceAnalysisId,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'mealType': mealType,
        if (description != null) 'description': description,
        'macros': macros.toJson(),
        'consumedAt': consumedAt.toUtc().toIso8601String(),
        if (sourceAnalysisId != null) 'sourceAnalysisId': sourceAnalysisId,
      };
}
