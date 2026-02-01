import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hefestocs/models/client_access_result.dart';

class InvitationCodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Valida un código de invitación buscando en todos los coaches
  ///
  /// Retorna [ClientAccessResult] si el código es válido, o null si no se encuentra.
  ///
  /// [invitationCode] - Código de invitación del cliente
  Future<ClientAccessResult?> validateCode({
    required String invitationCode,
  }) async {
    try {
      // a) Loggear el input EXACTO antes de la query
      debugPrint('🔎 RAW INPUT: "$invitationCode"');

      // b) Normalizar el código de forma CONSERVADORA (no quitar guiones)
      final normalized = invitationCode.trim().toUpperCase();
      debugPrint('🧹 NORMALIZED: "$normalized"');

      // c) Ejecutar la query usando normalized
      final querySnapshot = await _firestore
          .collectionGroup('clients')
          .where('invitationCode', isEqualTo: normalized)
          .limit(1)
          .get();

      // d) Loggear resultados
      debugPrint('📦 DOCS FOUND: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isNotEmpty) {
        debugPrint('📄 DOC DATA: ${querySnapshot.docs.first.data()}');
      }

      // e) Retornar éxito SOLO si docs.isNotEmpty
      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ Código no encontrado');

        // 3) Prueba de aislamiento — temporal (comentado)
        /*
        final test = await _firestore
          .collectionGroup('clients')
          .limit(5)
          .get();
        debugPrint('🧪 EXISTING CODES: ${test.docs.map((d)=>d['invitationCode']).toList()}');
        */

        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      final clientId = doc.id;
      final docPath = doc.reference.path;

      debugPrint('✅ Código válido → clientId: "$clientId", path: "$docPath"');

      final result = ClientAccessResult.fromFirestore(clientId, docPath, data);

      debugPrint(
          '✅ Access OK → $clientId | ${result.coachId} | ${result.displayName}');

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ Error validando código de invitación: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
