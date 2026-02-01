import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _keyClientId = 'client_id';
  static const String _keyCoachId = 'coach_id';
  static const String _keyDisplayName = 'display_name';
  static const String _keyDocPath = 'client_doc_path';

  /// Guarda la sesión del cliente
  Future<void> saveSession({
    required String clientId,
    String? coachId,
    required String displayName,
    String? docPath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyClientId, clientId);
      if (coachId != null) {
        await prefs.setString(_keyCoachId, coachId);
      }
      await prefs.setString(_keyDisplayName, displayName);
      if (docPath != null) {
        await prefs.setString(_keyDocPath, docPath);
      }
      debugPrint(
          '✅ Sesión guardada: $clientId | $coachId | $displayName | $docPath');
    } catch (e) {
      debugPrint('❌ Error guardando sesión: $e');
    }
  }

  /// Obtiene el clientId guardado
  Future<String?> getClientId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyClientId);
    } catch (e) {
      debugPrint('❌ Error obteniendo clientId: $e');
      return null;
    }
  }

  /// Obtiene el coachId guardado
  Future<String?> getCoachId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyCoachId);
    } catch (e) {
      debugPrint('❌ Error obteniendo coachId: $e');
      return null;
    }
  }

  /// Obtiene el displayName guardado
  Future<String?> getDisplayName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyDisplayName);
    } catch (e) {
      debugPrint('❌ Error obteniendo displayName: $e');
      return null;
    }
  }

  /// Obtiene el docPath guardado
  Future<String?> getDocPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyDocPath);
    } catch (e) {
      debugPrint('❌ Error obteniendo docPath: $e');
      return null;
    }
  }

  /// Verifica si hay una sesión activa
  Future<bool> hasSession() async {
    final clientId = await getClientId();
    return clientId != null && clientId.isNotEmpty;
  }

  /// Limpia la sesión
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyClientId);
      await prefs.remove(_keyCoachId);
      await prefs.remove(_keyDisplayName);
      await prefs.remove(_keyDocPath);
      debugPrint('🚪 Sesión eliminada');
    } catch (e) {
      debugPrint('❌ Error limpiando sesión: $e');
    }
  }
}
