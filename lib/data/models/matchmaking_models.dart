// Modelos del bounded context Matchmaking (atletas, coaches, conexiones, sesiones).

class AthleteProfile {
  final int id;
  final int userId;
  final String trainingLevel;
  final List<String> goals;
  final String? preferences;

  const AthleteProfile({
    required this.id,
    required this.userId,
    required this.trainingLevel,
    required this.goals,
    this.preferences,
  });

  factory AthleteProfile.fromJson(Map<String, dynamic> json) => AthleteProfile(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        trainingLevel: json['trainingLevel'] as String,
        goals: (json['goals'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        preferences: json['preferences'] as String?,
      );
}

class CreateAthleteProfileRequest {
  final int userId;
  final String trainingLevel;
  final List<String> goals;
  final String? preferences;

  const CreateAthleteProfileRequest({
    required this.userId,
    required this.trainingLevel,
    required this.goals,
    this.preferences,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'trainingLevel': trainingLevel,
        'goals': goals,
        if (preferences != null) 'preferences': preferences,
      };
}

class AvailabilitySlot {
  final int id;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final bool active;

  const AvailabilitySlot({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.active,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) => AvailabilitySlot(
        id: (json['id'] as num).toInt(),
        dayOfWeek: json['dayOfWeek'] as String,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        active: json['active'] as bool? ?? true,
      );
}

class CoachProfile {
  final int id;
  final int userId;
  final String? biography;
  final int yearsOfExperience;
  final num hourlyRate;
  final String currency;
  final List<String> specialties;
  final bool acceptingClients;
  final num averageRating;
  final int totalReviews;
  final List<AvailabilitySlot> availabilitySlots;

  const CoachProfile({
    required this.id,
    required this.userId,
    this.biography,
    required this.yearsOfExperience,
    required this.hourlyRate,
    required this.currency,
    required this.specialties,
    required this.acceptingClients,
    required this.averageRating,
    required this.totalReviews,
    required this.availabilitySlots,
  });

  factory CoachProfile.fromJson(Map<String, dynamic> json) => CoachProfile(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        biography: json['biography'] as String?,
        yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt() ?? 0,
        hourlyRate: (json['hourlyRate'] as num?) ?? 0,
        currency: json['currency'] as String? ?? 'PEN',
        specialties: (json['specialties'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        acceptingClients: json['acceptingClients'] as bool? ?? false,
        averageRating: (json['averageRating'] as num?) ?? 0,
        totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
        availabilitySlots: (json['availabilitySlots'] as List<dynamic>?)
                ?.map((e) => AvailabilitySlot.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class CreateCoachProfileRequest {
  final int userId;
  final String? biography;
  final int yearsOfExperience;
  final num hourlyRate;
  final String currency;
  final List<String> specialties;

  const CreateCoachProfileRequest({
    required this.userId,
    this.biography,
    required this.yearsOfExperience,
    required this.hourlyRate,
    required this.currency,
    required this.specialties,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        if (biography != null) 'biography': biography,
        'yearsOfExperience': yearsOfExperience,
        'hourlyRate': hourlyRate,
        'currency': currency,
        'specialties': specialties,
      };
}

class AddAvailabilityRequest {
  final String dayOfWeek;
  final String startTime;
  final String endTime;

  const AddAvailabilityRequest({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
      };
}

class ConnectionRequest {
  final int id;
  final int athleteId;
  final int coachId;
  final String? message;
  final String status;
  final DateTime? respondedAt;
  final String? responseNote;

  const ConnectionRequest({
    required this.id,
    required this.athleteId,
    required this.coachId,
    this.message,
    required this.status,
    this.respondedAt,
    this.responseNote,
  });

  factory ConnectionRequest.fromJson(Map<String, dynamic> json) => ConnectionRequest(
        id: (json['id'] as num).toInt(),
        athleteId: (json['athleteId'] as num).toInt(),
        coachId: (json['coachId'] as num).toInt(),
        message: json['message'] as String?,
        status: json['status'] as String,
        respondedAt: json['respondedAt'] == null ? null : DateTime.tryParse(json['respondedAt'] as String),
        responseNote: json['responseNote'] as String?,
      );
}

class CreateConnectionRequest {
  final int athleteId;
  final int coachId;
  final String? message;

  const CreateConnectionRequest({
    required this.athleteId,
    required this.coachId,
    this.message,
  });

  Map<String, dynamic> toJson() => {
        'athleteId': athleteId,
        'coachId': coachId,
        if (message != null) 'message': message,
      };
}

class RespondConnectionRequest {
  final bool approve;
  final String? responseNote;

  const RespondConnectionRequest({required this.approve, this.responseNote});

  Map<String, dynamic> toJson() => {
        'approve': approve,
        if (responseNote != null) 'responseNote': responseNote,
      };
}

class TrainingSession {
  final int id;
  final int athleteId;
  final int coachId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? location;
  final String? notes;
  final String status;
  final DateTime? completedAt;

  const TrainingSession({
    required this.id,
    required this.athleteId,
    required this.coachId,
    required this.scheduledAt,
    required this.durationMinutes,
    this.location,
    this.notes,
    required this.status,
    this.completedAt,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) => TrainingSession(
        id: (json['id'] as num).toInt(),
        athleteId: (json['athleteId'] as num).toInt(),
        coachId: (json['coachId'] as num).toInt(),
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        location: json['location'] as String?,
        notes: json['notes'] as String?,
        status: json['status'] as String,
        completedAt: json['completedAt'] == null ? null : DateTime.tryParse(json['completedAt'] as String),
      );
}

class ScheduleTrainingSessionRequest {
  final int athleteId;
  final int coachId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? location;
  final String? notes;

  const ScheduleTrainingSessionRequest({
    required this.athleteId,
    required this.coachId,
    required this.scheduledAt,
    required this.durationMinutes,
    this.location,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'athleteId': athleteId,
        'coachId': coachId,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'durationMinutes': durationMinutes,
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
      };
}
