import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hefestocs/models/client.dart';
import 'package:hefestocs/services/session_service.dart';
import 'package:hefestocs/utils/app_logger.dart';

class ClientDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SessionService _sessionService = SessionService();

  /// Carga los datos del cliente desde Firestore
  /// Parámetros:
  ///  - clientId: El ID del documento del cliente
  ///  - docPath: (Opcional) Path directo al documento (coaches/{coachId}/clients/{clientId})
  ///    Si se proporciona, carga directamente el documento, mucho más eficiente
  Future<Client> loadClientData(String clientId, {String? docPath}) async {
    try {
      AppLogger.info(
        '[ClientDataService] Buscando datos del cliente: "$clientId"',
      );

      if (clientId.isEmpty) {
        throw Exception('ClientId está vacío');
      }

      DocumentSnapshot doc;

      // Si tenemos docPath, cargar directamente (mucho más eficiente)
      if (docPath != null && docPath.isNotEmpty) {
        AppLogger.info(
          '[ClientDataService] Carga directa usando docPath: $docPath',
        );

        try {
          doc = await _firestore.doc(docPath).get();

          if (!doc.exists) {
            AppLogger.warn(
              '[ClientDataService] Documento no existe en docPath, usando fallback',
            );
            // Si el path directo falla, hacer fallback a collectionGroup
            final querySnapshot =
                await _firestore.collectionGroup('clients').limit(100).get();

            final matchingDocs =
                querySnapshot.docs.where((doc) => doc.id == clientId).toList();

            if (matchingDocs.isEmpty) {
              throw Exception('Cliente no encontrado con ID: $clientId');
            }

            doc = matchingDocs.first;
          } else {
            AppLogger.info(
                '[ClientDataService] Documento cargado directamente');
          }
        } catch (e) {
          if (_isPermissionDeniedError(e)) {
            throw Exception(_permissionDeniedMessage(docPath));
          }

          AppLogger.warn('[ClientDataService] Error en carga directa: $e');
          AppLogger.info(
            '[ClientDataService] Intentando fallback a collectionGroup...',
          );

          // Fallback si hay cualquier error con el path directo
          QuerySnapshot<Map<String, dynamic>> querySnapshot;
          try {
            querySnapshot =
                await _firestore.collectionGroup('clients').limit(100).get();
          } catch (queryError) {
            if (_isPermissionDeniedError(queryError)) {
              throw Exception(_permissionDeniedMessage(docPath));
            }
            rethrow;
          }

          final matchingDocs =
              querySnapshot.docs.where((doc) => doc.id == clientId).toList();

          if (matchingDocs.isEmpty) {
            throw Exception('Cliente no encontrado con ID: $clientId');
          }

          doc = matchingDocs.first;
        }
      } else {
        // Sin docPath - probablemente sesión antigua
        AppLogger.warn('[ClientDataService] No hay docPath guardado');
        throw Exception(
          'Sesión incompatible. Por favor cierra sesión y vuelve a iniciar con tu código de invitación.',
        );
      }

      final data = _withSmaeMappings(doc.data() as Map<String, dynamic>);

      AppLogger.info(
        '[ClientDataService] Cliente encontrado: ${data['fullName'] ?? 'Sin nombre'}',
      );

      // Convertir los datos de Firestore a modelo Client
      final client = Client.fromFirestore(doc.id, data);

      // Imprimir resumen de datos cargados
      AppLogger.info('[ClientDataService] Datos cargados:');
      AppLogger.info('   - Nombre: ${client.fullName}');
      AppLogger.info(
        '   - Antropometrías: ${client.anthropometryHistory.length}',
      );
      AppLogger.info('   - Kcal objetivo: ${client.kcalTarget}');
      AppLogger.info(
        '   - Proteína: ${client.proteinG}g, Grasa: ${client.fatG}g, Carbs: ${client.carbG}g',
      );
      AppLogger.info('   - Días SMAE: ${client.smaeEquivalentsByDay.length}');

      return client;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[ClientDataService] Error al cargar cliente',
        error: e,
        stackTrace: stackTrace,
      );

      if (_isPermissionDeniedError(e)) {
        throw Exception(_permissionDeniedMessage(docPath));
      }

      rethrow;
    }
  }

  /// Stream en tiempo real de los datos del cliente
  /// Se actualiza automáticamente cuando cambian los datos en Firestore
  Stream<Client> watchClientData(String clientId) {
    AppLogger.info(
        '[ClientDataService] Iniciando stream para cliente: $clientId');

    return _firestore
        .collectionGroup('clients')
        .snapshots()
        .asyncMap((querySnapshot) async {
      try {
        AppLogger.info(
          '[ClientDataService] Stream actualizado: ${querySnapshot.docs.length} documentos',
        );

        // Filtrar manualmente por ID
        final matchingDocs =
            querySnapshot.docs.where((doc) => doc.id == clientId).toList();

        if (matchingDocs.isEmpty) {
          AppLogger.warn(
            '[ClientDataService] Cliente no encontrado en stream: $clientId',
          );
          throw Exception('Cliente no encontrado con ID: $clientId');
        }

        final doc = matchingDocs.first;
        final data = _withSmaeMappings(doc.data());

        AppLogger.info(
          '[ClientDataService] Stream - Cliente actualizado: ${data['fullName']}',
        );

        return Client.fromFirestore(doc.id, data);
      } catch (e) {
        AppLogger.error(
          '[ClientDataService] Error procesando snapshot',
          error: e,
        );
        rethrow;
      }
    }).handleError((error, stackTrace) {
      AppLogger.error(
        '[ClientDataService] Error en stream',
        error: error,
        stackTrace: stackTrace,
      );
    }, test: (error) => error is Exception);
  }

  /// Obtiene la última medición de antropometría ordenada por fecha
  Map<String, dynamic>? getLatestAnthropometry(Client client) {
    if (client.anthropometryHistory.isEmpty) {
      return null;
    }

    // Ordenar por fecha descendente (más reciente primero)
    final sortedHistory =
        List<Map<String, dynamic>>.from(client.anthropometryHistory)
          ..sort((a, b) {
            final dateA = DateTime.parse(a['date'] as String);
            final dateB = DateTime.parse(b['date'] as String);
            return dateB.compareTo(dateA); // Descendente
          });

    return sortedHistory.first;
  }

  /// Calcula el indicador de déficit/superávit calórico
  /// Retorna:
  ///  - 'deficit' si kcalTarget < TMB estimada
  ///  - 'maintenance' si está cerca de TMB
  ///  - 'surplus' si kcalTarget > TMB estimada
  String getCalorieIndicator({
    required double kcalTarget,
    required double weight,
    String? activityLevel,
  }) {
    // Estimación simple de TMB usando fórmula de Harris-Benedict simplificada
    // TMB base ≈ 10 * peso (kg) + 6.25 * altura - 5 * edad + factor
    // Para simplificar, usamos un promedio: TMB ≈ 24 * peso
    final estimatedTMB = 24 * weight;

    // Factor de actividad (multiplicador de TMB)
    double activityMultiplier = 1.5; // Moderadamente activo por defecto
    if (activityLevel != null) {
      switch (activityLevel.toLowerCase()) {
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
      return 'deficit'; // Déficit calórico
    } else if (difference > 200) {
      return 'surplus'; // Superávit calórico
    } else {
      return 'maintenance'; // Mantenimiento
    }
  }

  /// Actualiza el payload del cliente con merge
  /// Útil para agregar logs de entrenamiento sin sobreescribir otros datos
  Future<void> updatePayload({
    required String docPath,
    required Map<String, dynamic> updates,
  }) async {
    try {
      AppLogger.info('[ClientDataService] Actualizando payload en: $docPath');
      AppLogger.info(
        '[ClientDataService] Datos a actualizar: ${updates.keys.join(", ")}',
      );

      await _firestore.doc(docPath).set(
            updates,
            SetOptions(merge: true),
          );

      AppLogger.info('[ClientDataService] Payload actualizado exitosamente');
    } catch (e, stackTrace) {
      AppLogger.error(
        '[ClientDataService] Error al actualizar payload',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Obtiene el documento completo de Firestore (incluyendo payload)
  Future<Map<String, dynamic>> getFullDocument(String docPath) async {
    try {
      AppLogger.info(
        '[ClientDataService] Obteniendo documento completo: $docPath',
      );

      final doc = await _firestore.doc(docPath).get();

      if (!doc.exists) {
        throw Exception('Documento no encontrado en: $docPath');
      }

      final data = doc.data() as Map<String, dynamic>;
      AppLogger.info('[ClientDataService] Documento completo obtenido');

      return data;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[ClientDataService] Error al obtener documento',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Map<String, dynamic> _withSmaeMappings(Map<String, dynamic> source) {
    final payload = Map<String, dynamic>.from(source);

    final mealsByDay = _extractSmaeMealsByDay(payload);
    final equivalentsByDay = _extractSmaeEquivalentsByDay(payload, mealsByDay);
    final mealsPerDay = _extractMealsPerDay(payload, mealsByDay);

    payload['smaeMealsByDay'] = mealsByDay;
    payload['smaeEquivalentsByDay'] = equivalentsByDay;
    payload['mealsPerDay'] = mealsPerDay;

    return payload;
  }

  Map<String, Map<String, Map<String, double>>> _extractSmaeMealsByDay(
    Map<String, dynamic> payload,
  ) {
    final directCandidates = [
      payload['smaeMealsByDay'],
      _asMap(payload['smae'])?['mealsByDay'],
      _asMap(payload['smae_v2'])?['mealsByDay'],
      _asMap(payload['nutritionPlan'])?['smaeMealsByDay'],
      _asMap(payload['mealPlan'])?['smaeMealsByDay'],
    ];

    for (final candidate in directCandidates) {
      final parsed = _parseDirectMealsByDay(candidate);
      if (parsed.isNotEmpty) return parsed;
    }

    final roots = [
      _asMap(payload['smae']),
      _asMap(payload['smae_v2']),
      _asMap(payload['nutritionPlan']),
      _asMap(payload['mealPlan']),
      payload,
    ];

    for (final root in roots) {
      if (root == null) continue;

      final days = _asMap(root['days']) ?? _asMap(root['dias']) ?? root;
      final parsed = <String, Map<String, Map<String, double>>>{};

      days.forEach((dayKey, dayValue) {
        final dayMap = _asMap(dayValue);
        if (dayMap == null) return;

        final meals = _asMap(dayMap['meals']) ?? _asMap(dayMap['comidas']);
        if (meals == null || meals.isEmpty) return;

        final parsedMeals = <String, Map<String, double>>{};
        meals.forEach((mealName, mealValue) {
          final mealMap = _asMap(mealValue);
          if (mealMap == null) return;

          final equivalents = _asMap(mealMap['equivalents']) ??
              _asMap(mealMap['equivalentes']) ??
              _asMap(mealMap['groups']) ??
              _asMap(mealMap['grupos']) ??
              mealMap;

          final parsedGroups = <String, double>{};
          equivalents.forEach((groupName, qty) {
            if (qty is num) {
              parsedGroups[groupName.toString()] = qty.toDouble();
            }
          });

          if (parsedGroups.isNotEmpty) {
            parsedMeals[mealName.toString()] = parsedGroups;
          }
        });

        if (parsedMeals.isNotEmpty) {
          parsed[dayKey.toString()] = parsedMeals;
        }
      });

      if (parsed.isNotEmpty) return parsed;
    }

    return {};
  }

  Map<String, Map<String, double>> _extractSmaeEquivalentsByDay(
    Map<String, dynamic> payload,
    Map<String, Map<String, Map<String, double>>> mealsByDay,
  ) {
    final directCandidates = [
      payload['smaeEquivalentsByDay'],
      _asMap(payload['smae'])?['equivalentsByDay'],
      _asMap(payload['smae_v2'])?['equivalentsByDay'],
      _asMap(payload['nutritionPlan'])?['smaeEquivalentsByDay'],
      _asMap(payload['mealPlan'])?['smaeEquivalentsByDay'],
    ];

    for (final candidate in directCandidates) {
      final parsed = _parseDirectEquivalentsByDay(candidate);
      if (parsed.isNotEmpty) return parsed;
    }

    if (mealsByDay.isEmpty) return {};

    final totalsByDay = <String, Map<String, double>>{};
    mealsByDay.forEach((day, meals) {
      final totals = <String, double>{};
      meals.forEach((_, groups) {
        groups.forEach((group, qty) {
          totals[group] = (totals[group] ?? 0) + qty;
        });
      });
      totalsByDay[day] = totals;
    });

    return totalsByDay;
  }

  Map<String, int> _extractMealsPerDay(
    Map<String, dynamic> payload,
    Map<String, Map<String, Map<String, double>>> mealsByDay,
  ) {
    final directCandidates = [
      payload['mealsPerDay'],
      _asMap(payload['smae'])?['mealsPerDay'],
      _asMap(payload['smae_v2'])?['mealsPerDay'],
      _asMap(payload['nutritionPlan'])?['mealsPerDay'],
      _asMap(payload['mealPlan'])?['mealsPerDay'],
    ];

    for (final candidate in directCandidates) {
      final parsed = _parseDirectMealsPerDay(candidate);
      if (parsed.isNotEmpty) return parsed;
    }

    if (mealsByDay.isEmpty) return {};

    return mealsByDay.map((day, meals) => MapEntry(day, meals.length));
  }

  Map<String, Map<String, Map<String, double>>> _parseDirectMealsByDay(
    dynamic source,
  ) {
    if (source is! Map) return {};

    final result = <String, Map<String, Map<String, double>>>{};
    source.forEach((day, mealsRaw) {
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

        if (groups.isNotEmpty) {
          meals[mealName.toString()] = groups;
        }
      });

      if (meals.isNotEmpty) {
        result[day.toString()] = meals;
      }
    });

    return result;
  }

  Map<String, Map<String, double>> _parseDirectEquivalentsByDay(
      dynamic source) {
    if (source is! Map) return {};

    final result = <String, Map<String, double>>{};
    source.forEach((day, groupsRaw) {
      if (groupsRaw is! Map) return;

      final groups = <String, double>{};
      groupsRaw.forEach((groupName, qty) {
        if (qty is num) {
          groups[groupName.toString()] = qty.toDouble();
        }
      });

      if (groups.isNotEmpty) {
        result[day.toString()] = groups;
      }
    });

    return result;
  }

  Map<String, int> _parseDirectMealsPerDay(dynamic source) {
    if (source is! Map) return {};

    final result = <String, int>{};
    source.forEach((day, mealsCount) {
      if (mealsCount is num) {
        result[day.toString()] = mealsCount.toInt();
      }
    });
    return result;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }
    return null;
  }

  bool _isPermissionDeniedError(Object error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied';
    }

    final text = error.toString().toLowerCase();
    return text.contains('permission-denied') ||
        text.contains('missing or insufficient permissions') ||
        text.contains('permission_denied');
  }

  String _permissionDeniedMessage(String? docPath) {
    return 'No tienes permisos para leer tu expediente en Firestore '
        '(permission-denied). '
        'Cierra sesión y vuelve a ingresar con tu código de invitación. '
        'Si el problema persiste, el coach/admin debe ajustar las reglas '
        'de Firestore para permitir lectura del path: ${docPath ?? 'sin docPath'}.';
  }

  // ==========================
  //  NUEVOS MÉTODOS (Data Layer)
  //  - Basados en contrato de subcolecciones bajo docPath
  //  - SIN tocar UI / navegación
  // ==========================

  /// Agrega entradas de log de entrenamiento al documento diario en
  /// coaches/{coachId}/clients/{clientId}/training_logs/{YYYY-MM-DD}
  ///
  /// Reglas clave:
  /// - DocID por fecha en zona America/Merida (normalizado a día)
  /// - Usa transacción para leer->concatenar->escribir `entries` y evitar pérdidas por concurrencia
  /// - `createdAt` solo si el doc no existía; `updatedAt` siempre
  Future<void> appendTrainingLogForDay({
    required DateTime date,
    required List<Map<String, dynamic>> entries,
    bool? sessionCompleted,
  }) async {
    final docPath = await _sessionService.getDocPath();
    if (docPath == null || docPath.isEmpty) {
      throw Exception('No se encontró docPath en la sesión');
    }

    final dayId = _formatDayIdMerida(date);
    final docRef =
        _firestore.doc(docPath).collection('training_logs').doc(dayId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      final existing =
          (snap.data()?['entries'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];
      final combined = [...existing, ...entries];

      final data = <String, dynamic>{
        'date': dayId,
        'entries': combined,
        if (sessionCompleted != null) 'sessionCompleted': sessionCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
        'source': 'mobile',
        'schemaVersion': 1,
      };

      // Solo establecer createdAt si el documento no existía (idempotencia de creación)
      if (!snap.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      // set + merge para crear o actualizar atomícamente dentro de la transacción
      txn.set(docRef, data, SetOptions(merge: true));
    });
  }

  /// Upsert de adherencia nutricional del día en
  /// coaches/{coachId}/clients/{clientId}/nutrition_adherence/{YYYY-MM-DD}
  ///
  /// - Estructura: meals.{mealKey}.{adherence, notes?}
  /// - Calcula `overall` como promedio simple de adherencias (0–100)
  /// - Usa transacción para tomar en cuenta el estado actual y escribir un overall coherente
  Future<void> upsertNutritionAdherenceForDay({
    required DateTime date,
    required Map<String, int> mealsPercentages, // 0–100 step 20
    Map<String, String>? notes,
  }) async {
    final docPath = await _sessionService.getDocPath();
    if (docPath == null || docPath.isEmpty) {
      throw Exception('No se encontró docPath en la sesión');
    }

    final dayId = _formatDayIdMerida(date);
    final docRef =
        _firestore.doc(docPath).collection('nutrition_adherence').doc(dayId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      final currentMeals =
          Map<String, dynamic>.from((snap.data()?['meals'] as Map?) ?? {});

      // Construir estructura meals con adherencia redondeada a paso 20 y notas opcionales
      final mealsUpdate = <String, dynamic>{};
      mealsPercentages.forEach((meal, pct) {
        final rounded = _roundToNearestStep(pct, 20).clamp(0, 100);
        final mealMap = <String, dynamic>{'adherence': rounded};
        final note = notes?[meal];
        if (note != null && note.trim().isNotEmpty) {
          mealMap['notes'] = note;
        }
        mealsUpdate[meal] = mealMap;
      });

      // Merge lógico en memoria para calcular un overall correcto
      final mergedMeals = <String, dynamic>{...currentMeals, ...mealsUpdate};

      // Calcular overall (promedio simple de adherencias presentes)
      final adherences = mergedMeals.values
          .map((e) => (e is Map && e['adherence'] is num)
              ? (e['adherence'] as num).toInt()
              : null)
          .whereType<int>()
          .toList();
      final overall = adherences.isEmpty
          ? null
          : (adherences.reduce((a, b) => a + b) / adherences.length).round();

      final data = <String, dynamic>{
        'date': dayId,
        'meals': mealsUpdate, // solo lo nuevo; el merge:true preserva el resto
        if (overall != null) 'overall': overall,
        'updatedAt': FieldValue.serverTimestamp(),
        'source': 'mobile',
        'schemaVersion': 1,
      };
      if (!snap.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      txn.set(docRef, data, SetOptions(merge: true));
    });
  }

  /// Upsert de bioquímica del día en
  /// coaches/{coachId}/clients/{clientId}/biochemistry_records/{YYYY-MM-DD}
  ///
  /// - `markers` puede ser parcial; merge:true permite subir campos por partes
  /// - `notes` opcional
  Future<void> upsertBiochemistryForDay({
    required DateTime date,
    required Map<String, Map<String, dynamic>> markers,
    String? notes,
  }) async {
    final docPath = await _sessionService.getDocPath();
    if (docPath == null || docPath.isEmpty) {
      throw Exception('No se encontró docPath en la sesión');
    }

    final dayId = _formatDayIdMerida(date);
    final docRef =
        _firestore.doc(docPath).collection('biochemistry_records').doc(dayId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(docRef);

      final data = <String, dynamic>{
        'date': dayId,
        ...markers, // cada key es un marcador con {value, status}
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
        'source': 'mobile',
        'schemaVersion': 1,
      };
      if (!snap.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      txn.set(docRef, data, SetOptions(merge: true));
    });
  }

  /// Crea un documento de foto de progreso en
  /// coaches/{coachId}/clients/{clientId}/progress_photos/{autoId}
  ///
  /// - Solo escribe si `consent == true`
  /// - No maneja Storage aquí; únicamente metadatos en Firestore
  Future<void> createProgressPhoto({
    required bool consent,
    required String storagePath,
    required String photoUrl,
    String? thumbnailUrl,
    String? pose,
    String? notes,
    DateTime? capturedAt,
  }) async {
    if (consent != true) return; // seguridad: no escribir sin consentimiento

    final docPath = await _sessionService.getDocPath();
    if (docPath == null || docPath.isEmpty) {
      throw Exception('No se encontró docPath en la sesión');
    }

    final colRef = _firestore.doc(docPath).collection('progress_photos');
    final now = DateTime.now();
    final data = <String, dynamic>{
      'consent': true,
      'capturedAt': (capturedAt ?? now),
      'storagePath': storagePath,
      'photoUrl': photoUrl,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (pose != null) 'pose': pose,
      if (notes != null) 'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'source': 'mobile',
      'schemaVersion': 1,
    };

    await colRef.add(data);
  }

  // ==========================
  //  Helpers privados
  // ==========================

  /// Formatea el ID de documento diario (YYYY-MM-DD) usando zona America/Merida.
  ///
  /// Nota: Sin librería de timezones, aproximamos con offset fijo -6h.
  /// Ajustar si la política local de DST cambiara.
  String _formatDayIdMerida(DateTime date) {
    const meridaOffsetHours = -6; // America/Merida
    final localMerida =
        date.toUtc().add(const Duration(hours: meridaOffsetHours));
    final y = localMerida.year.toString().padLeft(4, '0');
    final m = localMerida.month.toString().padLeft(2, '0');
    final d = localMerida.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  int _roundToNearestStep(int value, int step) {
    final lower = (value / step).floor() * step;
    final upper = (value / step).ceil() * step;
    return (value - lower) < (upper - value) ? lower : upper;
  }
}
