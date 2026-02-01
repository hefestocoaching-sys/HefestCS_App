import 'dart:convert';

/// 📋 TrainingSessionLogV2 v1.0.0 - CONGELADO
///
/// CONTRATO CLÍNICO para bitácora de entrenamiento.
///
/// ⚠️ RESTRICCIONES ABSOLUTAS:
/// - SIN lógica de cálculo (solo app desktop)
/// - SIN cambios de schema sin versionado
/// - SIN decisiones clínicas (solo entrada)
/// - Cambios: Requerir aprobación médica y versionado nuevo
///
/// Rol de app móvil:
/// - LECTURA: planes desde Firebase (generados por desktop)
/// - ESCRITURA: sesiones de entrenamiento completadas (local)
/// - SINCRONIZACIÓN: offline-first a Firebase

/// Unidad atómica: un ejercicio dentro de una sesión de entrenamiento
class ExerciseLog {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final int setsCompleted;
  final List<int> repsPerSet;
  final double weightKg;
  final String? userNotes;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool wasModified;

  ExerciseLog({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.setsCompleted,
    required this.repsPerSet,
    required this.weightKg,
    this.userNotes,
    required this.startedAt,
    this.completedAt,
    required this.wasModified,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      setsCompleted: json['setsCompleted'] as int,
      repsPerSet: List<int>.from(json['repsPerSet'] as List),
      weightKg: (json['weightKg'] as num).toDouble(),
      userNotes: json['userNotes'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      wasModified: json['wasModified'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'setsCompleted': setsCompleted,
        'repsPerSet': repsPerSet,
        'weightKg': weightKg,
        'userNotes': userNotes,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'wasModified': wasModified,
      };

  ExerciseLog copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    int? setsCompleted,
    List<int>? repsPerSet,
    double? weightKg,
    String? userNotes,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? wasModified,
  }) {
    return ExerciseLog(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      setsCompleted: setsCompleted ?? this.setsCompleted,
      repsPerSet: repsPerSet ?? this.repsPerSet,
      weightKg: weightKg ?? this.weightKg,
      userNotes: userNotes ?? this.userNotes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      wasModified: wasModified ?? this.wasModified,
    );
  }
}

/// Sesión de entrenamiento completada (o en progreso)
class TrainingSessionLogV2 {
  final String id;
  final String clientId;
  final String trainingPlanId;
  final int sessionNumber;
  final int trainingPhase;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<ExerciseLog> exercises;
  final String? sessionNotes;
  final int completionPercentage;
  final bool isSynced;
  final String? checksumSHA256;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainingSessionLogV2({
    required this.id,
    required this.clientId,
    required this.trainingPlanId,
    required this.sessionNumber,
    required this.trainingPhase,
    required this.startedAt,
    this.completedAt,
    required this.exercises,
    this.sessionNotes,
    required this.completionPercentage,
    required this.isSynced,
    this.checksumSHA256,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainingSessionLogV2.fromJson(Map<String, dynamic> json) {
    return TrainingSessionLogV2(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      trainingPlanId: json['trainingPlanId'] as String,
      sessionNumber: json['sessionNumber'] as int,
      trainingPhase: json['trainingPhase'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      exercises: (json['exercises'] as List)
          .map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      sessionNotes: json['sessionNotes'] as String?,
      completionPercentage: json['completionPercentage'] as int,
      isSynced: json['isSynced'] as bool,
      checksumSHA256: json['checksumSHA256'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'trainingPlanId': trainingPlanId,
        'sessionNumber': sessionNumber,
        'trainingPhase': trainingPhase,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'sessionNotes': sessionNotes,
        'completionPercentage': completionPercentage,
        'isSynced': isSynced,
        'checksumSHA256': checksumSHA256,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  TrainingSessionLogV2 copyWith({
    String? id,
    String? clientId,
    String? trainingPlanId,
    int? sessionNumber,
    int? trainingPhase,
    DateTime? startedAt,
    DateTime? completedAt,
    List<ExerciseLog>? exercises,
    String? sessionNotes,
    int? completionPercentage,
    bool? isSynced,
    String? checksumSHA256,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainingSessionLogV2(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      trainingPlanId: trainingPlanId ?? this.trainingPlanId,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      trainingPhase: trainingPhase ?? this.trainingPhase,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      exercises: exercises ?? this.exercises,
      sessionNotes: sessionNotes ?? this.sessionNotes,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      isSynced: isSynced ?? this.isSynced,
      checksumSHA256: checksumSHA256 ?? this.checksumSHA256,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Valida integridad del log (sin cálculos clínicos)
  void validate() {
    if (completedAt != null && completedAt!.isBefore(startedAt)) {
      throw ArgumentError(
        '[TrainingSessionLogV2] completedAt no puede ser anterior a startedAt',
      );
    }

    if (exercises.isEmpty) {
      throw ArgumentError(
        '[TrainingSessionLogV2] exercises no puede estar vacío',
      );
    }

    final expectedCompletion = exercises.isNotEmpty
        ? ((exercises.where((e) => e.completedAt != null).length /
                    exercises.length) *
                100)
            .toInt()
        : 0;

    if (completionPercentage != expectedCompletion) {
      throw ArgumentError(
        '[TrainingSessionLogV2] completionPercentage no coincide con exercises completados',
      );
    }
  }

  String toJsonString() => jsonEncode(toJson());

  factory TrainingSessionLogV2.fromJsonString(String source) =>
      TrainingSessionLogV2.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

/// Estado de sesión
enum TrainingSessionStatus {
  notStarted,
  inProgress,
  completed,
  incomplete,
  synced,
  syncPending,
}

extension TrainingSessionStatusExt on TrainingSessionLogV2 {
  TrainingSessionStatus getStatus() {
    if (completedAt == null) {
      if (startedAt.isBefore(DateTime.now())) {
        return TrainingSessionStatus.inProgress;
      }
      return TrainingSessionStatus.notStarted;
    }

    if (completionPercentage == 100) {
      return isSynced
          ? TrainingSessionStatus.synced
          : TrainingSessionStatus.syncPending;
    }

    return TrainingSessionStatus.incomplete;
  }
}
