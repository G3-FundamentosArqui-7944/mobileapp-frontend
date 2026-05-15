// Modelos del bounded context Videos (subida y análisis con IA).

class TechnicalFeedback {
  final int id;
  final String aspect;
  final String message;
  final String severity;
  final int? timestampSeconds;

  const TechnicalFeedback({
    required this.id,
    required this.aspect,
    required this.message,
    required this.severity,
    this.timestampSeconds,
  });

  factory TechnicalFeedback.fromJson(Map<String, dynamic> json) => TechnicalFeedback(
        id: (json['id'] as num).toInt(),
        aspect: json['aspect'] as String,
        message: json['message'] as String,
        severity: json['severity'] as String,
        timestampSeconds: (json['timestampSeconds'] as num?)?.toInt(),
      );
}

class VideoAnalysis {
  final int id;
  final String? summary;
  final num? overallScore;
  final String? aiModelVersion;
  final DateTime? analyzedAt;
  final List<TechnicalFeedback> feedbackItems;

  const VideoAnalysis({
    required this.id,
    this.summary,
    this.overallScore,
    this.aiModelVersion,
    this.analyzedAt,
    required this.feedbackItems,
  });

  factory VideoAnalysis.fromJson(Map<String, dynamic> json) => VideoAnalysis(
        id: (json['id'] as num).toInt(),
        summary: json['summary'] as String?,
        overallScore: json['overallScore'] as num?,
        aiModelVersion: json['aiModelVersion'] as String?,
        analyzedAt: json['analyzedAt'] == null ? null : DateTime.tryParse(json['analyzedAt'] as String),
        feedbackItems: (json['feedbackItems'] as List<dynamic>?)
                ?.map((e) => TechnicalFeedback.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class ExerciseVideo {
  final int id;
  final int userId;
  final String exerciseName;
  final String? description;
  final String? storageUrl;
  final int sizeBytes;
  final String? contentType;
  final int? durationSeconds;
  final String status;
  final String? failureReason;
  final VideoAnalysis? analysis;

  const ExerciseVideo({
    required this.id,
    required this.userId,
    required this.exerciseName,
    this.description,
    this.storageUrl,
    required this.sizeBytes,
    this.contentType,
    this.durationSeconds,
    required this.status,
    this.failureReason,
    this.analysis,
  });

  factory ExerciseVideo.fromJson(Map<String, dynamic> json) => ExerciseVideo(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        exerciseName: json['exerciseName'] as String,
        description: json['description'] as String?,
        storageUrl: json['storageUrl'] as String?,
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
        contentType: json['contentType'] as String?,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
        status: json['status'] as String,
        failureReason: json['failureReason'] as String?,
        analysis: json['analysis'] == null
            ? null
            : VideoAnalysis.fromJson(json['analysis'] as Map<String, dynamic>),
      );

  bool get isCompleted => status == 'COMPLETED' || status == 'ANALYZED';
  bool get isProcessing => status == 'PROCESSING' || status == 'PENDING';
  bool get isFailed => status == 'FAILED';
}
