/// Modelo de datos para representar un cliente
class Client {
  final String id;
  final String fullName;
  final String invitationCode;
  final double kcalTarget;
  final double proteinG;
  final double fatG;
  final double carbG;
  final List<Map<String, dynamic>> anthropometryHistory;
  final Map<String, Map<String, double>> smaeEquivalentsByDay;
  final Map<String, int> mealsPerDay;
  final Map<String, Map<String, Map<String, double>>> smaeMealsByDay;
  final String? profilePictureUrl;
  final String? goal;
  final String? activityLevel;

  Client({
    required this.id,
    required this.fullName,
    required this.invitationCode,
    required this.kcalTarget,
    required this.proteinG,
    required this.fatG,
    required this.carbG,
    required this.anthropometryHistory,
    required this.smaeEquivalentsByDay,
    required this.mealsPerDay,
    required this.smaeMealsByDay,
    this.profilePictureUrl,
    this.goal,
    this.activityLevel,
  });

  /// Crea una instancia de Client desde datos de Firestore
  factory Client.fromFirestore(String docId, Map<String, dynamic> data) {
    return Client(
      id: docId,
      fullName: data['fullName'] as String? ?? 'Sin nombre',
      invitationCode: data['invitationCode'] as String? ?? '',
      kcalTarget: (data['kcalTarget'] as num?)?.toDouble() ?? 0,
      proteinG: (data['proteinG'] as num?)?.toDouble() ?? 0,
      fatG: (data['fatG'] as num?)?.toDouble() ?? 0,
      carbG: (data['carbG'] as num?)?.toDouble() ?? 0,
      anthropometryHistory:
          _parseAnthropometryHistory(data['anthropometryHistory']),
      smaeEquivalentsByDay:
          _parseSmaeEquivalentsByDay(data['smaeEquivalentsByDay']),
      mealsPerDay: _parseMealsPerDay(data['mealsPerDay']),
      smaeMealsByDay: _parseSmaeMealsByDay(data['smaeMealsByDay']),
      profilePictureUrl: data['profilePictureUrl'] as String?,
      goal: data['goal'] as String?,
      activityLevel: data['activityLevel'] as String?,
    );
  }

  /// Convierte una lista de Firestore a `List<Map<String, dynamic>>`
  static List<Map<String, dynamic>> _parseAnthropometryHistory(
      dynamic rawData) {
    if (rawData == null) return [];
    if (rawData is! List) return [];

    return rawData.map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      }
      // Si es un Map de otro tipo, convertirlo
      return Map<String, dynamic>.from(item as Map);
    }).toList();
  }

  static Map<String, Map<String, double>> _parseSmaeEquivalentsByDay(
      dynamic rawData) {
    if (rawData is! Map) return {};

    return rawData.map((day, groups) {
      final dayKey = day.toString();
      if (groups is! Map) return MapEntry(dayKey, <String, double>{});

      final parsedGroups = <String, double>{};
      groups.forEach((group, qty) {
        if (qty is num) {
          parsedGroups[group.toString()] = qty.toDouble();
        }
      });
      return MapEntry(dayKey, parsedGroups);
    });
  }

  static Map<String, int> _parseMealsPerDay(dynamic rawData) {
    if (rawData is! Map) return {};

    return rawData.map((day, count) {
      final value = (count is num) ? count.toInt() : 0;
      return MapEntry(day.toString(), value);
    });
  }

  static Map<String, Map<String, Map<String, double>>> _parseSmaeMealsByDay(
      dynamic rawData) {
    if (rawData is! Map) return {};

    final result = <String, Map<String, Map<String, double>>>{};

    rawData.forEach((day, mealsRaw) {
      if (mealsRaw is! Map) return;

      final meals = <String, Map<String, double>>{};
      mealsRaw.forEach((mealName, groupsRaw) {
        if (groupsRaw is! Map) return;

        final groups = <String, double>{};
        groupsRaw.forEach((groupName, qty) {
          if (qty is num) {
            groups[groupName.toString()] = qty.toDouble();
          }
        });

        meals[mealName.toString()] = groups;
      });

      result[day.toString()] = meals;
    });

    return result;
  }

  /// Convierte el cliente a un mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'invitationCode': invitationCode,
      'kcalTarget': kcalTarget,
      'proteinG': proteinG,
      'fatG': fatG,
      'carbG': carbG,
      'anthropometryHistory': anthropometryHistory,
      'smaeEquivalentsByDay': smaeEquivalentsByDay,
      'mealsPerDay': mealsPerDay,
      'smaeMealsByDay': smaeMealsByDay,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      if (goal != null) 'goal': goal,
      if (activityLevel != null) 'activityLevel': activityLevel,
    };
  }

  /// Crea una copia del cliente con campos actualizados
  Client copyWith({
    String? id,
    String? fullName,
    String? invitationCode,
    double? kcalTarget,
    double? proteinG,
    double? fatG,
    double? carbG,
    List<Map<String, dynamic>>? anthropometryHistory,
    Map<String, Map<String, double>>? smaeEquivalentsByDay,
    Map<String, int>? mealsPerDay,
    Map<String, Map<String, Map<String, double>>>? smaeMealsByDay,
    String? profilePictureUrl,
    String? goal,
    String? activityLevel,
  }) {
    return Client(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      invitationCode: invitationCode ?? this.invitationCode,
      kcalTarget: kcalTarget ?? this.kcalTarget,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      carbG: carbG ?? this.carbG,
      anthropometryHistory: anthropometryHistory ?? this.anthropometryHistory,
      smaeEquivalentsByDay: smaeEquivalentsByDay ?? this.smaeEquivalentsByDay,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      smaeMealsByDay: smaeMealsByDay ?? this.smaeMealsByDay,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }

  @override
  String toString() {
    return 'Client(id: $id, fullName: $fullName, kcalTarget: $kcalTarget, '
        'proteinG: $proteinG, fatG: $fatG, carbG: $carbG, '
        'anthropometryHistory: ${anthropometryHistory.length} entries, '
        'smaeDays: ${smaeEquivalentsByDay.length})';
  }
}
