import 'dart:convert';

class Client {
  final String id;
  final String fullName;
  final int? age;
  final String? gender;
  final double? initialHeightCm;
  final double? currentWeightKg;
  final double? kcalTarget;
  final double? proteinG;
  final double? fatG;
  final double? carbG;
  final double? tmb;
  final double? totalEnergyExpenditure;
  final String? goal;
  final String? status;
  final DateTime? lastUpdate;

  final List<AnthropometryRecord>? anthropometryHistory;
  final List<BioChemistryRecord>? biochemistryHistory;
  final DailyMacroSettings? dailyMacros;

  Client({
    required this.id,
    required this.fullName,
    this.age,
    this.gender,
    this.initialHeightCm,
    this.currentWeightKg,
    this.kcalTarget,
    this.proteinG,
    this.fatG,
    this.carbG,
    this.tmb,
    this.totalEnergyExpenditure,
    this.goal,
    this.status,
    this.lastUpdate,
    this.anthropometryHistory,
    this.biochemistryHistory,
    this.dailyMacros,
  });

  Client copyWith({
    String? id,
    String? fullName,
    int? age,
    String? gender,
    double? initialHeightCm,
    double? currentWeightKg,
    double? kcalTarget,
    double? proteinG,
    double? fatG,
    double? carbG,
    double? tmb,
    double? totalEnergyExpenditure,
    String? goal,
    String? status,
    DateTime? lastUpdate,
    List<AnthropometryRecord>? anthropometryHistory,
    List<BioChemistryRecord>? biochemistryHistory,
    DailyMacroSettings? dailyMacros,
  }) {
    return Client(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      initialHeightCm: initialHeightCm ?? this.initialHeightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      kcalTarget: kcalTarget ?? this.kcalTarget,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      carbG: carbG ?? this.carbG,
      tmb: tmb ?? this.tmb,
      totalEnergyExpenditure:
          totalEnergyExpenditure ?? this.totalEnergyExpenditure,
      goal: goal ?? this.goal,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      anthropometryHistory: anthropometryHistory ?? this.anthropometryHistory,
      biochemistryHistory: biochemistryHistory ?? this.biochemistryHistory,
      dailyMacros: dailyMacros ?? this.dailyMacros,
    );
  }

  factory Client.fromMap(Map<String, dynamic> data) {
    return Client(
      id: data['id'] ?? '',
      fullName: data['fullName'] ?? '',
      age: data['age'],
      gender: data['gender'],
      initialHeightCm: (data['initialHeightCm'] as num?)?.toDouble(),
      currentWeightKg: (data['currentWeightKg'] as num?)?.toDouble(),
      kcalTarget: (data['kcalTarget'] as num?)?.toDouble(),
      proteinG: (data['proteinG'] as num?)?.toDouble(),
      fatG: (data['fatG'] as num?)?.toDouble(),
      carbG: (data['carbG'] as num?)?.toDouble(),
      tmb: (data['tmb'] as num?)?.toDouble(),
      totalEnergyExpenditure:
          (data['totalEnergyExpenditure'] as num?)?.toDouble(),
      goal: data['goal'],
      status: data['status'],
      lastUpdate: data['lastUpdate'] != null
          ? DateTime.tryParse(data['lastUpdate'])
          : null,
      anthropometryHistory: (data['anthropometryHistory'] as List?)
          ?.map(
              (e) => AnthropometryRecord.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      biochemistryHistory: (data['biochemistryHistory'] as List?)
          ?.map((e) => BioChemistryRecord.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      dailyMacros: data['dailyMacros'] != null
          ? DailyMacroSettings.fromMap(
              Map<String, dynamic>.from(data['dailyMacros']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'initialHeightCm': initialHeightCm,
      'currentWeightKg': currentWeightKg,
      'kcalTarget': kcalTarget,
      'proteinG': proteinG,
      'fatG': fatG,
      'carbG': carbG,
      'tmb': tmb,
      'totalEnergyExpenditure': totalEnergyExpenditure,
      'goal': goal,
      'status': status,
      'lastUpdate': lastUpdate?.toIso8601String(),
      'anthropometryHistory':
          anthropometryHistory?.map((e) => e.toMap()).toList(),
      'biochemistryHistory':
          biochemistryHistory?.map((e) => e.toMap()).toList(),
      'dailyMacros': dailyMacros?.toMap(),
    };
  }

  String toJson() => json.encode(toMap());

  factory Client.fromJson(String source) =>
      Client.fromMap(json.decode(source) as Map<String, dynamic>);
}

class AnthropometryRecord {
  final DateTime date;
  final double? weightKg;
  final double? heightCm;
  final double? bmi;
  final double? bodyFatPercentage;
  final double? leanBodyMassKg;
  final double? musclePercentage;

  AnthropometryRecord({
    required this.date,
    this.weightKg,
    this.heightCm,
    this.bmi,
    this.bodyFatPercentage,
    this.leanBodyMassKg,
    this.musclePercentage,
  });

  AnthropometryRecord copyWith({
    DateTime? date,
    double? weightKg,
    double? heightCm,
    double? bmi,
    double? bodyFatPercentage,
    double? leanBodyMassKg,
    double? musclePercentage,
  }) {
    return AnthropometryRecord(
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      bmi: bmi ?? this.bmi,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      leanBodyMassKg: leanBodyMassKg ?? this.leanBodyMassKg,
      musclePercentage: musclePercentage ?? this.musclePercentage,
    );
  }

  factory AnthropometryRecord.fromMap(Map<String, dynamic> data) {
    final dateStr = data['date'] as String?;
    if (dateStr == null || dateStr.isEmpty) {
      throw FormatException(
        '[AnthropometryRecord] Campo "date" requerido y no puede estar vacío. '
        'Recibido: $dateStr. Esto indica corrupción de datos clínicos.',
      );
    }
    final parsedDate = DateTime.tryParse(dateStr);
    if (parsedDate == null) {
      throw FormatException(
          '[AnthropometryRecord] Formato de fecha inválido: "$dateStr". '
          'Use formato ISO8601: YYYY-MM-DD o YYYY-MM-DDTHH:mm:ss.');
    }
    return AnthropometryRecord(
      date: parsedDate,
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      bmi: (data['bmi'] as num?)?.toDouble(),
      bodyFatPercentage: (data['bodyFatPercentage'] as num?)?.toDouble(),
      leanBodyMassKg: (data['leanBodyMassKg'] as num?)?.toDouble(),
      musclePercentage: (data['musclePercentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'heightCm': heightCm,
        'bmi': bmi,
        'bodyFatPercentage': bodyFatPercentage,
        'leanBodyMassKg': leanBodyMassKg,
        'musclePercentage': musclePercentage,
      };

  String toJson() => json.encode(toMap());

  factory AnthropometryRecord.fromJson(String source) =>
      AnthropometryRecord.fromMap(json.decode(source) as Map<String, dynamic>);
}

class BioChemistryRecord {
  final DateTime date;
  final Map<String, double?> values;

  BioChemistryRecord({
    required this.date,
    required this.values,
  });

  BioChemistryRecord copyWith({
    DateTime? date,
    Map<String, double?>? values,
  }) {
    return BioChemistryRecord(
      date: date ?? this.date,
      values: values ?? this.values,
    );
  }

  factory BioChemistryRecord.fromMap(Map<String, dynamic> data) {
    final dateStr = data['date'] as String?;
    if (dateStr == null || dateStr.isEmpty) {
      throw FormatException(
        '[BioChemistryRecord] Campo "date" requerido y no puede estar vacío. '
        'Recibido: $dateStr. Esto indica corrupción de datos clínicos.',
      );
    }
    final parsedDate = DateTime.tryParse(dateStr);
    if (parsedDate == null) {
      throw FormatException(
          '[BioChemistryRecord] Formato de fecha inválido: "$dateStr". '
          'Use formato ISO8601: YYYY-MM-DD o YYYY-MM-DDTHH:mm:ss.');
    }
    return BioChemistryRecord(
      date: parsedDate,
      values: (data['values'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num?)?.toDouble()),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'values': values,
      };

  String toJson() => json.encode(toMap());

  factory BioChemistryRecord.fromJson(String source) =>
      BioChemistryRecord.fromMap(json.decode(source) as Map<String, dynamic>);
}

class DailyMacroSettings {
  final double? kcal;
  final double? protein;
  final double? fats;
  final double? carbs;

  DailyMacroSettings({
    this.kcal,
    this.protein,
    this.fats,
    this.carbs,
  });

  DailyMacroSettings copyWith({
    double? kcal,
    double? protein,
    double? fats,
    double? carbs,
  }) {
    return DailyMacroSettings(
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      fats: fats ?? this.fats,
      carbs: carbs ?? this.carbs,
    );
  }

  factory DailyMacroSettings.fromMap(Map<String, dynamic> data) {
    return DailyMacroSettings(
      kcal: (data['kcal'] as num?)?.toDouble(),
      protein: (data['protein'] as num?)?.toDouble(),
      fats: (data['fats'] as num?)?.toDouble(),
      carbs: (data['carbs'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'kcal': kcal,
        'protein': protein,
        'fats': fats,
        'carbs': carbs,
      };

  String toJson() => json.encode(toMap());

  factory DailyMacroSettings.fromJson(String source) =>
      DailyMacroSettings.fromMap(json.decode(source) as Map<String, dynamic>);
}
