import 'package:hefestocs/models/client.dart';

/// Snapshot inmutable de datos clínicos del cliente
/// Lectura de payload completo desde Firestore sin lógica modificable
/// Centraliza reglas de extracción (ej: último registro por fecha)
class ClientSnapshot {
  final Client client;
  final Map<String, dynamic>? rawPayload;

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
  int get kcalTarget => client.kcalTarget;

  /// Proteína objetivo en gramos
  int get proteinG => client.proteinG;

  /// Carbohidratos objetivo en gramos
  int get carbG => client.carbG;

  /// Grasa objetivo en gramos
  int get fatG => client.fatG;

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
