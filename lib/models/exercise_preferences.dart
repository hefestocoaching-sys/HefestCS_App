import 'dart:collection';

/// IMPORTANTE: Todas las keys en ExercisePreferencesByMuscle deben estar
/// normalizadas a claves canónicas del motor usando
/// ExercisePreferenceMuscleKeyMapper.toCanonicalKey() antes de almacenar.
///
/// FLUJO DE NORMALIZACIÓN:
/// 1. UI recolecta preferencias con 3 opciones: Frecuente / Preferido / Evitar
/// 2. Persistencia en extra[TrainingExtraKeys.exercisePreferencesByMuscle]
///    almacena SOLO keys canónicas
/// 3. Coach app consulta directamente con claves canónicas

class ExercisePreferenceBucket {
  final Set<String> frequent;
  final Set<String> preferred;
  final Set<String> avoid;

  const ExercisePreferenceBucket({
    this.frequent = const <String>{},
    this.preferred = const <String>{},
    this.avoid = const <String>{},
  });

  bool get hasAny =>
      frequent.isNotEmpty || preferred.isNotEmpty || avoid.isNotEmpty;

  Map<String, dynamic> toJson() {
    List<String> sorted(Set<String> values) => (values.toList()..sort());
    return <String, dynamic>{
      'frequent': sorted(frequent),
      'preferred': sorted(preferred),
      'avoid': sorted(avoid),
    };
  }

  factory ExercisePreferenceBucket.fromDynamic(dynamic raw) {
    if (raw is! Map) return const ExercisePreferenceBucket();
    Set<String> toSet(dynamic value) {
      if (value is! List) return <String>{};
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet();
    }

    return ExercisePreferenceBucket(
      frequent: toSet(raw['frequent']),
      preferred: toSet(raw['preferred']),
      avoid: toSet(raw['avoid']),
    );
  }

  ExercisePreferenceBucket copyWith({
    Set<String>? frequent,
    Set<String>? preferred,
    Set<String>? avoid,
  }) {
    return ExercisePreferenceBucket(
      frequent: frequent ?? this.frequent,
      preferred: preferred ?? this.preferred,
      avoid: avoid ?? this.avoid,
    );
  }
}

class ExercisePreferenceGroup {
  final String id;
  final String label;
  final List<String> persistMuscleKeys;

  const ExercisePreferenceGroup({
    required this.id,
    required this.label,
    required this.persistMuscleKeys,
  });
}

const List<ExercisePreferenceGroup> kExercisePreferenceGroups =
    <ExercisePreferenceGroup>[
      ExercisePreferenceGroup(
        id: 'pectoral',
        label: 'Pectoral',
        persistMuscleKeys: <String>['pectorals'],
      ),
      ExercisePreferenceGroup(
        id: 'dorsal',
        label: 'Dorsal',
        persistMuscleKeys: <String>['lats'],
      ),
      ExercisePreferenceGroup(
        id: 'espalda_alta',
        label: 'Espalda Alta',
        persistMuscleKeys: <String>['upper_back'],
      ),
      ExercisePreferenceGroup(
        id: 'cuadriceps',
        label: 'Cuádriceps',
        persistMuscleKeys: <String>['quads'],
      ),
      ExercisePreferenceGroup(
        id: 'isquios',
        label: 'Isquios',
        persistMuscleKeys: <String>['hamstrings'],
      ),
      ExercisePreferenceGroup(
        id: 'gluteos',
        label: 'Glúteos',
        persistMuscleKeys: <String>['glutes'],
      ),
      ExercisePreferenceGroup(
        id: 'deltoides',
        label: 'Deltoides',
        persistMuscleKeys: <String>[
          'delts_front',
          'delts_lateral',
          'delts_rear',
        ],
      ),
      ExercisePreferenceGroup(
        id: 'biceps',
        label: 'Bíceps',
        persistMuscleKeys: <String>['biceps'],
      ),
      ExercisePreferenceGroup(
        id: 'triceps',
        label: 'Tríceps',
        persistMuscleKeys: <String>['triceps'],
      ),
      ExercisePreferenceGroup(
        id: 'pantorrillas',
        label: 'Pantorrillas',
        persistMuscleKeys: <String>['calves'],
      ),
      ExercisePreferenceGroup(
        id: 'abdomen',
        label: 'Abdomen',
        persistMuscleKeys: <String>['abs'],
      ),
      ExercisePreferenceGroup(
        id: 'traps',
        label: 'Trapecios',
        persistMuscleKeys: <String>['traps'],
      ),
    ];

class ExercisePreferencesByMuscle {
  final Map<String, ExercisePreferenceBucket> byMuscle;

  const ExercisePreferencesByMuscle({
    this.byMuscle = const <String, ExercisePreferenceBucket>{},
  });

  bool get hasMinimumData => byMuscle.values.any((bucket) => bucket.hasAny);

  static ExercisePreferencesByMuscle fromDynamic(dynamic raw) {
    if (raw is! Map) return const ExercisePreferencesByMuscle();
    final mapped = <String, ExercisePreferenceBucket>{};
    raw.forEach((key, value) {
      final muscleKey = key.toString().trim();
      if (muscleKey.isEmpty) return;
      final bucket = ExercisePreferenceBucket.fromDynamic(value);
      if (bucket.hasAny) {
        mapped[muscleKey] = bucket;
      }
    });
    return ExercisePreferencesByMuscle(byMuscle: UnmodifiableMapView(mapped));
  }

  ExercisePreferenceBucket bucketForGroup(ExercisePreferenceGroup group) {
    final frequent = <String>{};
    final preferred = <String>{};
    final avoid = <String>{};

    for (final key in group.persistMuscleKeys) {
      final bucket = byMuscle[key];
      if (bucket == null) continue;
      frequent.addAll(bucket.frequent);
      preferred.addAll(bucket.preferred);
      avoid.addAll(bucket.avoid);
    }

    return ExercisePreferenceBucket(
      frequent: frequent,
      preferred: preferred,
      avoid: avoid,
    );
  }

  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{};
    final entries = byMuscle.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      if (entry.value.hasAny) {
        out[entry.key] = entry.value.toJson();
      }
    }
    return out;
  }
}
