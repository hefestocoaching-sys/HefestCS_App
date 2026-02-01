/// Modelo de datos para representar un cliente
class Client {
  final String id;
  final String fullName;
  final String invitationCode;
  final int kcalTarget;
  final int proteinG;
  final int fatG;
  final int carbG;
  final List<Map<String, dynamic>> anthropometryHistory;
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
      kcalTarget: (data['kcalTarget'] as num?)?.toInt() ?? 0,
      proteinG: (data['proteinG'] as num?)?.toInt() ?? 0,
      fatG: (data['fatG'] as num?)?.toInt() ?? 0,
      carbG: (data['carbG'] as num?)?.toInt() ?? 0,
      anthropometryHistory:
          _parseAnthropometryHistory(data['anthropometryHistory']),
      profilePictureUrl: data['profilePictureUrl'] as String?,
      goal: data['goal'] as String?,
      activityLevel: data['activityLevel'] as String?,
    );
  }

  /// Convierte una lista de Firestore a List<Map<String, dynamic>>
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
    int? kcalTarget,
    int? proteinG,
    int? fatG,
    int? carbG,
    List<Map<String, dynamic>>? anthropometryHistory,
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
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }

  @override
  String toString() {
    return 'Client(id: $id, fullName: $fullName, kcalTarget: $kcalTarget, '
        'proteinG: $proteinG, fatG: $fatG, carbG: $carbG, '
        'anthropometryHistory: ${anthropometryHistory.length} entries)';
  }
}
