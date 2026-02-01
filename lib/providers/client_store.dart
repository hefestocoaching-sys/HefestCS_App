import 'package:flutter/foundation.dart';
import 'package:hefestocs/models/client.dart';
import 'package:hefestocs/models/client_snapshot.dart';
import 'package:hefestocs/services/client_data_service.dart';
import 'package:hefestocs/services/session_service.dart';

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

      print('📦 [ClientStore] Cargando cliente: $clientId');
      if (docPath != null) {
        print('⚡ [ClientStore] Usando docPath directo: $docPath');
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
          print('✅ [ClientStore] Payload completo cargado');
        } catch (e) {
          print('⚠️ [ClientStore] No se pudo cargar payload completo: $e');
          _rawData = null;
        }
      }

      _client = client;
      _isLoading = false;
      _error = null;

      print('✅ [ClientStore] Cliente cargado: ${client.fullName}');
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ [ClientStore] Error al cargar cliente: $e');
      print('Stack trace: $stackTrace');

      _error = e.toString();
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

      print('💾 [ClientStore] Actualizando payload...');
      await _clientDataService.updatePayload(
        docPath: docPath,
        updates: updates,
      );

      // Recargar datos después de actualizar
      await refresh();
      print('✅ [ClientStore] Payload actualizado y datos refrescados');
    } catch (e, stackTrace) {
      print('❌ [ClientStore] Error al actualizar payload: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
