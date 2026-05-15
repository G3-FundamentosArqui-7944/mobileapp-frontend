// Modelos del bounded context Training (sesiones, métricas, progreso).

class ExerciseExecution {
  final int id;
  final String exerciseName;
  final int sets;
  final int reps;
  final num? load;
  final String? loadUnit;
  final int? durationSeconds;
  final int? restSeconds;
  final String? notes;

  const ExerciseExecution({
    required this.id,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.load,
    this.loadUnit,
    this.durationSeconds,
    this.restSeconds,
    this.notes,
  });

  factory ExerciseExecution.fromJson(Map<String, dynamic> json) => ExerciseExecution(
        id: (json['id'] as num).toInt(),
        exerciseName: json['exerciseName'] as String,
        sets: (json['sets'] as num).toInt(),
        reps: (json['reps'] as num).toInt(),
        load: json['load'] as num?,
        loadUnit: json['loadUnit'] as String?,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
        restSeconds: (json['restSeconds'] as num?)?.toInt(),
        notes: json['notes'] as String?,
      );
}

class WorkoutSession {
  final int id;
  final int userId;
  final String title;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String status;
  final String? notes;
  final int totalVolume;
  final List<ExerciseExecution> exercises;

  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.notes,
    required this.totalVolume,
    required this.exercises,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        title: json['title'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: json['completedAt'] == null ? null : DateTime.tryParse(json['completedAt'] as String),
        status: json['status'] as String,
        notes: json['notes'] as String?,
        totalVolume: (json['totalVolume'] as num?)?.toInt() ?? 0,
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map((e) => ExerciseExecution.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class StartWorkoutSessionRequest {
  final int userId;
  final String title;
  final DateTime startedAt;
  final String? notes;

  const StartWorkoutSessionRequest({
    required this.userId,
    required this.title,
    required this.startedAt,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'title': title,
        'startedAt': startedAt.toUtc().toIso8601String(),
        if (notes != null) 'notes': notes,
      };
}

class AddExerciseExecutionRequest {
  final String exerciseName;
  final int sets;
  final int reps;
  final num? load;
  final String? loadUnit;
  final int? durationSeconds;
  final int? restSeconds;
  final String? notes;

  const AddExerciseExecutionRequest({
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.load,
    this.loadUnit,
    this.durationSeconds,
    this.restSeconds,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'exerciseName': exerciseName,
        'sets': sets,
        'reps': reps,
        if (load != null) 'load': load,
        if (loadUnit != null) 'loadUnit': loadUnit,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (restSeconds != null) 'restSeconds': restSeconds,
        if (notes != null) 'notes': notes,
      };
}

class PerformanceMetric {
  final int id;
  final int userId;
  final String metricType;
  final num value;
  final String? unit;
  final DateTime recordedAt;

  const PerformanceMetric({
    required this.id,
    required this.userId,
    required this.metricType,
    required this.value,
    this.unit,
    required this.recordedAt,
  });

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) => PerformanceMetric(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        metricType: json['metricType'] as String,
        value: json['value'] as num,
        unit: json['unit'] as String?,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
      );
}

class RecordPerformanceMetricRequest {
  final int userId;
  final String metricType;
  final num value;
  final String? unit;
  final DateTime recordedAt;

  const RecordPerformanceMetricRequest({
    required this.userId,
    required this.metricType,
    required this.value,
    this.unit,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'metricType': metricType,
        'value': value,
        if (unit != null) 'unit': unit,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
      };
}

class ProgressRecord {
  final int id;
  final int userId;
  final String milestone;
  final String? description;
  final DateTime achievedAt;

  const ProgressRecord({
    required this.id,
    required this.userId,
    required this.milestone,
    this.description,
    required this.achievedAt,
  });

  factory ProgressRecord.fromJson(Map<String, dynamic> json) => ProgressRecord(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        milestone: json['milestone'] as String,
        description: json['description'] as String?,
        achievedAt: DateTime.parse(json['achievedAt'] as String),
      );
}

class TrainingAnalytics {
  final int totalWorkouts;
  final int completedWorkouts;
  final int abandonedWorkouts;
  final int totalExerciseExecutions;
  final int totalVolume;
  final double averageVolumePerSession;
  final double completionRate;

  const TrainingAnalytics({
    required this.totalWorkouts,
    required this.completedWorkouts,
    required this.abandonedWorkouts,
    required this.totalExerciseExecutions,
    required this.totalVolume,
    required this.averageVolumePerSession,
    required this.completionRate,
  });

  factory TrainingAnalytics.fromJson(Map<String, dynamic> json) => TrainingAnalytics(
        totalWorkouts: (json['totalWorkouts'] as num?)?.toInt() ?? 0,
        completedWorkouts: (json['completedWorkouts'] as num?)?.toInt() ?? 0,
        abandonedWorkouts: (json['abandonedWorkouts'] as num?)?.toInt() ?? 0,
        totalExerciseExecutions: (json['totalExerciseExecutions'] as num?)?.toInt() ?? 0,
        totalVolume: (json['totalVolume'] as num?)?.toInt() ?? 0,
        averageVolumePerSession: (json['averageVolumePerSession'] as num?)?.toDouble() ?? 0.0,
        completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      );
}
