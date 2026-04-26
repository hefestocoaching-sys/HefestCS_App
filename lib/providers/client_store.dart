import 'package:flutter/foundation.dart';
import 'package:hefestocs/models/client.dart';
import 'package:hefestocs/models/client_snapshot.dart';
import 'package:hefestocs/services/client_data_service.dart';
import 'package:hefestocs/services/session_service.dart';
import 'package:hefestocs/utils/app_logger.dart';

/// Store centralizado para datos del cliente
/// Evita múltiples queries y sirve como fuente de verdad única
class ClientStore extends ChangeNotifier {
  final ClientDataService _clientDataService = ClientDataService();
  final SessionService _sessionService = SessionService();

  bool _isLoading = false;
  String? _error;
  Client? _client;
  Map<String, dynamic>? _rawData;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Client? get client => _client;
  Map<String, dynamic>? get rawData => _rawData;

  /// Snapshot inmutable de datos clínicos derivados
  ClientSnapshot? get snapshot {
    if (_client == null) return null;
    return ClientSnapshot(client: _client!, rawPayload: _rawData);
  }

  /// Carga los datos del cliente desde Firestore
  /// Se puede llamar múltiples veces (ej: para refrescar)
  Future<void> load() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Obtener clientId y docPath de la sesión
      final clientId = await _sessionService.getClientId();
      final docPath = await _sessionService.getDocPath();

      if (clientId == null) {
        throw Exception('No se encontró sesión activa');
      }

      AppLogger.info('[ClientStore] Cargando cliente: $clientId');
      if (docPath != null) {
        AppLogger.info('[ClientStore] Usando docPath directo: $docPath');
      }

      // Cargar datos del cliente (con docPath si está disponible)
      final client = await _clientDataService.loadClientData(
        clientId,
        docPath: docPath,
      );

      // Cargar el documento completo (payload) si tenemos docPath
      if (docPath != null) {
        try {
          _rawData = await _clientDataService.getFullDocument(docPath);
          AppLogger.info('[ClientStore] Payload completo cargado');
        } catch (e) {
          AppLogger.warn(
              '[ClientStore] No se pudo cargar payload completo: $e');
          _rawData = null;
        }
      }

      _client = client;
      _isLoading = false;
      _error = null;

      AppLogger.info('[ClientStore] Cliente cargado: ${client.fullName}');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(
        '[ClientStore] Error al cargar cliente',
        error: e,
        stackTrace: stackTrace,
      );

      final errorText = e.toString();
      if (_isPermissionDeniedError(errorText)) {
        _error = 'No hay permisos para leer tu expediente (Firestore). '
            'Cierra sesión e ingresa de nuevo con tu código. '
            'Si continúa, solicita al coach/admin revisar reglas de Firestore.';
      } else {
        _error = errorText;
      }
      _isLoading = false;
      _client = null;

      notifyListeners();
    }
  }

  /// Limpia el estado del store (ej: al hacer logout)
  void clear() {
    _client = null;
    _rawData = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Refresca los datos (alias de load para claridad)
  Future<void> refresh() => load();

  /// Actualiza el payload del cliente (ej: agregar log de entrenamiento)
  Future<void> updatePayload(Map<String, dynamic> updates) async {
    try {
      final docPath = await _sessionService.getDocPath();
      if (docPath == null) {
        throw Exception('No se encontró docPath en la sesión');
      }

      AppLogger.info('[ClientStore] Actualizando payload...');
      await _clientDataService.updatePayload(
        docPath: docPath,
        updates: updates,
      );

      // Recargar datos después de actualizar
      await refresh();
      AppLogger.info('[ClientStore] Payload actualizado y datos refrescados');
    } catch (e, stackTrace) {
      AppLogger.error(
        '[ClientStore] Error al actualizar payload',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  bool _isPermissionDeniedError(String errorText) {
    final normalized = errorText.toLowerCase();
    return normalized.contains('permission-denied') ||
        normalized.contains('permission_denied') ||
        normalized.contains('missing or insufficient permissions');
  }
}
