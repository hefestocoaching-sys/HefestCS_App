import 'package:hefestocs/models/client.dart';

/// Snapshot inmutable de datos clínicos del cliente
/// Lectura de payload completo desde Firestore sin lógica modificable
/// Centraliza reglas de extracción (ej: último registro por fecha)
class ClientSnapshot {
  final Client client;
  final Map<String, dynamic>? rawPayload;

  static const Map<String, double> _groupKcalFactors = {
    'verduras': 25,
    'frutas': 60,
    'cereales': 70,
    'cereales_sin_grasa': 70,
    'cereales_con_grasa': 115,
    'leguminosas': 120,
    'aoa_muy_bajo': 40,
    'aoa_bajo': 55,
    'aoa_moderado': 75,
    'aoa_alto': 100,
    'leche_descremada': 95,
    'leche_semidescremada': 110,
    'leche_entera': 150,
    'yogurt': 120,
    'aceites_sin_proteina': 45,
    'aceites_con_proteina': 70,
    'azucares_sin_grasa': 40,
    'azucares_con_grasa': 85,
    'libres': 0,
    'alcohol': 140,
  };

  static const Map<String, String> _weekdayPrettyName = {
    'monday': 'Lunes',
    'tuesday': 'Martes',
    'wednesday': 'Miércoles',
    'thursday': 'Jueves',
    'friday': 'Viernes',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
    'lunes': 'Lunes',
    'martes': 'Martes',
    'miercoles': 'Miércoles',
    'miércoles': 'Miércoles',
    'jueves': 'Jueves',
    'viernes': 'Viernes',
    'sabado': 'Sábado',
    'sábado': 'Sábado',
    'domingo': 'Domingo',
  };

  static const Map<String, String> _mealPrettyName = {
    'breakfast': 'Desayuno',
    'snack_am': 'Colación AM',
    'lunch': 'Comida',
    'snack_pm': 'Colación PM',
    'dinner': 'Cena',
    'desayuno': 'Desayuno',
    'colacion_am': 'Colación AM',
    'colación_am': 'Colación AM',
    'comida': 'Comida',
    'colacion_pm': 'Colación PM',
    'colación_pm': 'Colación PM',
    'cena': 'Cena',
  };

  ClientSnapshot({
    required this.client,
    this.rawPayload,
  });

  /// Nombre completo del cliente
  String get fullName => client.fullName;

  /// Objetivo del cliente (texto legible)
  String get goalText {
    if (client.goal == null || client.goal!.isEmpty) {
      return 'Sin objetivo definido';
    }
    return client.goal!;
  }

  /// Objetivo calórico desde Client (estructura principal)
  double get kcalTarget => client.kcalTarget;

  /// Proteína objetivo en gramos
  double get proteinG => client.proteinG;

  /// Carbohidratos objetivo en gramos
  double get carbG => client.carbG;

  /// Grasa objetivo en gramos
  double get fatG => client.fatG;

  Map<String, Map<String, double>> get smaeEquivalentsByDay =>
      client.smaeEquivalentsByDay;

  Map<String, int> get mealsPerDay => client.mealsPerDay;

  Map<String, Map<String, Map<String, double>>> get smaeMealsByDay =>
      client.smaeMealsByDay;

  bool get hasSmaePlan =>
      smaeEquivalentsByDay.isNotEmpty || smaeMealsByDay.isNotEmpty;

  List<String> get smaeDays {
    final keys = <String>{
      ...smaeEquivalentsByDay.keys,
      ...smaeMealsByDay.keys,
      ...mealsPerDay.keys,
    }.toList();

    keys.sort((a, b) => _weekdayOrder(a).compareTo(_weekdayOrder(b)));
    return keys;
  }

  String prettyDayName(String day) {
    final key = day.toLowerCase().trim();
    return _weekdayPrettyName[key] ?? _capitalize(day);
  }

  String prettyMealName(String meal) {
    final key = meal.toLowerCase().trim();
    return _mealPrettyName[key] ?? _capitalize(meal.replaceAll('_', ' '));
  }

  String prettyGroupName(String group) {
    final base = group.replaceAll('_', ' ').trim();
    if (base.isEmpty) return group;
    return _capitalize(base);
  }

  Map<String, double> equivalentsForDay(String day) =>
      smaeEquivalentsByDay[day] ?? const {};

  Map<String, Map<String, double>> mealsForDay(String day) =>
      smaeMealsByDay[day] ?? const {};

  double calculatedKcalForDay(String day) {
    final byGroup = equivalentsForDay(day);
    if (byGroup.isEmpty) return 0;

    double total = 0;
    byGroup.forEach((group, qty) {
      final factor = _kcalFactorForGroup(group);
      total += qty * factor;
    });
    return total;
  }

  Map<String, double> kcalByGroupForDay(String day) {
    final byGroup = equivalentsForDay(day);
    final result = <String, double>{};

    byGroup.forEach((group, qty) {
      result[group] = qty * _kcalFactorForGroup(group);
    });

    return result;
  }

  double get averageCalculatedKcal {
    if (smaeDays.isEmpty) return 0;
    final total = smaeDays
        .map(calculatedKcalForDay)
        .fold<double>(0, (sum, dayKcal) => sum + dayKcal);
    return total / smaeDays.length;
  }

  double kcalDeltaForDay(String day) => calculatedKcalForDay(day) - kcalTarget;

  double coveragePercentForDay(String day) {
    if (kcalTarget <= 0) return 0;
    return (calculatedKcalForDay(day) / kcalTarget) * 100;
  }

  String coverageLevelForDay(String day) {
    final delta = kcalDeltaForDay(day).abs();
    if (delta <= 80) return 'green';
    if (delta <= 180) return 'orange';
    return 'red';
  }

  bool isCoverageMissingForDay(String day) {
    final meals = mealsForDay(day);
    final eq = equivalentsForDay(day);
    return meals.isEmpty || eq.isEmpty || calculatedKcalForDay(day) <= 0;
  }

  List<String> planWarningsForDay(String day) {
    final warnings = <String>[];

    if (!hasSmaePlan) {
      warnings.add('⚠️ Plan SMAE no configurado todavía.');
      return warnings;
    }

    if (isCoverageMissingForDay(day)) {
      warnings.add(
          '🟠 Cobertura incompleta en $day: faltan equivalentes o comidas.');
      return warnings;
    }

    final delta = kcalDeltaForDay(day);
    if (delta.abs() > 180) {
      final sign = delta > 0 ? '+' : '';
      warnings.add(
        '🔴 Delta kcal alto ($sign${delta.toStringAsFixed(0)} kcal) en ${prettyDayName(day)}.',
      );
    } else if (delta.abs() > 80) {
      final sign = delta > 0 ? '+' : '';
      warnings.add(
        '🟠 Ajuste recomendado ($sign${delta.toStringAsFixed(0)} kcal) en ${prettyDayName(day)}.',
      );
    }

    return warnings;
  }

  List<String> get globalSmaeWarnings {
    if (!hasSmaePlan) {
      return const ['⚠️ Plan de equivalentes no configurado por el coach.'];
    }

    final warnings = <String>[];
    for (final day in smaeDays) {
      warnings.addAll(planWarningsForDay(day));
    }
    return warnings;
  }

  /// Última medición antropométrica (más reciente por fecha)
  Map<String, dynamic>? get latestAnthropometry {
    if (client.anthropometryHistory.isEmpty) return null;
    return _latestByDate(client.anthropometryHistory, 'date');
  }

  /// Penúltima medición antropométrica (segunda más reciente)
  Map<String, dynamic>? get previousAnthropometry {
    if (client.anthropometryHistory.length < 2) return null;
    final sorted = _sortedByDateDesc(client.anthropometryHistory, 'date');
    return sorted.length >= 2 ? sorted[1] : null;
  }

  /// Historial de antropometría ordenado por fecha ascendente (más antiguo primero)
  List<Map<String, dynamic>> get anthropometryHistorySorted {
    if (client.anthropometryHistory.isEmpty) return [];
    return _sortedByDateAsc(client.anthropometryHistory, 'date');
  }

  /// Verifica si hay registros de bioquímica disponibles en rawPayload
  bool get hasBiochemistry {
    final biochemRecords = rawPayload?['biochemistry_records'] as List?;
    return biochemRecords != null && biochemRecords.isNotEmpty;
  }

  /// Último estudio bioquímico (más reciente por fecha)
  Map<String, dynamic>? get latestBiochemistry {
    final biochemRecords = rawPayload?['biochemistry_records'] as List?;
    if (biochemRecords == null || biochemRecords.isEmpty) return null;

    final records = biochemRecords.cast<Map<String, dynamic>>();
    return _latestByDate(records, 'date');
  }

  /// Verifica si hay registros de nutrición disponibles
  bool get hasNutritionRecords {
    final nutritionRecords = rawPayload?['nutrition_records'] as List?;
    return nutritionRecords != null && nutritionRecords.isNotEmpty;
  }

  /// Verifica si hay plan de entrenamiento disponible
  bool get hasTrainingPlan {
    final trainingRecords = rawPayload?['training_records'] as List?;
    return trainingRecords != null && trainingRecords.isNotEmpty;
  }

  /// Texto profesional del estado calórico
  String get deficitOrSurplusText {
    final indicator = _calculateCalorieIndicator();
    switch (indicator) {
      case 'deficit':
        return 'Déficit (Pérdida)';
      case 'surplus':
        return 'Superávit (Ganancia)';
      case 'maintenance':
        return 'Mantenimiento';
      default:
        return 'No definido';
    }
  }

  /// Nivel de actividad
  String? get activityLevel => client.activityLevel;

  /// Peso actual (del último anthropometry)
  double? get currentWeight => latestAnthropometry?['weight']?.toDouble();

  /// Porcentaje de grasa corporal (del último anthropometry)
  String get bodyFatPercentage {
    final value = latestAnthropometry?['bodyFatPercentage'];
    if (value == null) return '-%';
    return '$value%';
  }

  /// Porcentaje de masa muscular (del último anthropometry)
  String get muscleMassPercentage {
    final value = latestAnthropometry?['muscleMassPercentage'];
    if (value == null) return '-%';
    return '$value%';
  }

  /// Fecha de la última medición antropométrica
  DateTime? get latestMeasurementDate {
    final dateStr = latestAnthropometry?['date'] as String?;
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  // ========== HELPERS PRIVADOS ==========

  /// Obtiene el elemento más reciente de una lista ordenándola por fecha (descendente)
  Map<String, dynamic>? _latestByDate(
    List<Map<String, dynamic>> list,
    String dateKey,
  ) {
    if (list.isEmpty) return null;
    final sorted = _sortedByDateDesc(list, dateKey);
    return sorted.first;
  }

  /// Ordena una lista de mapas por fecha descendente (más reciente primero)
  List<Map<String, dynamic>> _sortedByDateDesc(
    List<Map<String, dynamic>> list,
    String dateKey,
  ) {
    final sorted = List<Map<String, dynamic>>.from(list);
    sorted.sort((a, b) {
      try {
        final dateA = DateTime.parse(a[dateKey] as String);
        final dateB = DateTime.parse(b[dateKey] as String);
        return dateB.compareTo(dateA); // Descendente (más reciente primero)
      } catch (e) {
        return 0;
      }
    });
    return sorted;
  }

  double _kcalFactorForGroup(String group) {
    final normalized = group.toLowerCase().trim();
    if (_groupKcalFactors.containsKey(normalized)) {
      return _groupKcalFactors[normalized]!;
    }
    for (final entry in _groupKcalFactors.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return 0;
  }

  int _weekdayOrder(String day) {
    final normalized = day.toLowerCase().trim();
    const order = {
      'monday': 1,
      'lunes': 1,
      'tuesday': 2,
      'martes': 2,
      'wednesday': 3,
      'miercoles': 3,
      'miércoles': 3,
      'thursday': 4,
      'jueves': 4,
      'friday': 5,
      'viernes': 5,
      'saturday': 6,
      'sabado': 6,
      'sábado': 6,
      'sunday': 7,
      'domingo': 7,
    };
    return order[normalized] ?? 99;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Ordena una lista de mapas por fecha ascendente (más antiguo primero)
  List<Map<String, dynamic>> _sortedByDateAsc(
    List<Map<String, dynamic>> list,
    String dateKey,
  ) {
    final sorted = List<Map<String, dynamic>>.from(list);
    sorted.sort((a, b) {
      try {
        final dateA = DateTime.parse(a[dateKey] as String);
        final dateB = DateTime.parse(b[dateKey] as String);
        return dateA.compareTo(dateB); // Ascendente (más antiguo primero)
      } catch (e) {
        return 0;
      }
    });
    return sorted;
  }

  /// Calcula el indicador de déficit/superávit calórico
  String _calculateCalorieIndicator() {
    final weight = currentWeight ?? 70.0;

    // Estimación de TMB: TMB ≈ 24 * peso
    final estimatedTMB = 24 * weight;

    // Factor de actividad (multiplicador de TMB)
    double activityMultiplier = 1.5; // Moderadamente activo por defecto

    if (activityLevel != null) {
      switch (activityLevel!.toLowerCase()) {
        case 'sedentario':
        case 'sedentary':
          activityMultiplier = 1.2;
          break;
        case 'ligero':
        case 'light':
          activityMultiplier = 1.375;
          break;
        case 'moderado':
        case 'moderate':
          activityMultiplier = 1.55;
          break;
        case 'activo':
        case 'active':
          activityMultiplier = 1.725;
          break;
        case 'muy activo':
        case 'very active':
          activityMultiplier = 1.9;
          break;
      }
    }

    final estimatedTDEE = estimatedTMB * activityMultiplier;

    // Calcular diferencia
    final difference = kcalTarget - estimatedTDEE;

    if (difference < -200) {
      return 'deficit';
    } else if (difference > 200) {
      return 'surplus';
    } else {
      return 'maintenance';
    }
  }
}
