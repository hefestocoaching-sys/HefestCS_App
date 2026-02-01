import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hefestocs/data/database_helper.dart';
import 'package:hefestocs/models/client_model.dart';
import 'package:hefestocs/services/sync_service.dart';

class DataRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SyncService _syncService = SyncService();

  /// Singleton pattern para acceso global
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal();

  /// Inicializa el listener de conectividad y sincronización
  void initialize() {
    _syncService.listenForConnectivityChanges();
  }

  /// Obtiene todos los clientes, eligiendo entre Firebase o SQLite según conexión
  Future<List<Client>> getAllClients() async {
    final hasConnection = await _hasInternetConnection();

    if (hasConnection) {
      final snapshot = await _firestore.collection('clients').get();
      final clients = snapshot.docs
          .map((doc) => Client.fromMap({'id': doc.id, ...doc.data()}))
          .toList();

      // Guarda copia local para modo offline
      for (var client in clients) {
        await _dbHelper.insertClient(client);
      }

      return clients;
    } else {
      return await _dbHelper.getAllClients();
    }
  }

  /// Obtiene un cliente por ID
  Future<Client?> getClientById(String id) async {
    final hasConnection = await _hasInternetConnection();

    if (hasConnection) {
      final doc = await _firestore.collection('clients').doc(id).get();

      if (doc.exists) {
        final client = Client.fromMap({'id': doc.id, ...doc.data()!});
        await _dbHelper.insertClient(client);
        return client;
      } else {
        return null;
      }
    } else {
      return await _dbHelper.getClientById(id);
    }
  }

  /// No usar para escrituras en Firestore raíz `/clients`: no respeta docPath ni subcolecciones.
  ///
  /// Reemplazo recomendado: usar métodos de `ClientDataService` que escriben bajo
  /// `coaches/{coachId}/clients/{clientId}` (docPath) y subcolecciones.
  @Deprecated(
      'Evitar escrituras en /clients. Usar ClientDataService con docPath y subcolecciones')

  /// Inserta o actualiza cliente (ambos modos)
  Future<void> upsertClient(Client client) async {
    final hasConnection = await _hasInternetConnection();
    final now = DateTime.now();

    final updatedClient = client.copyWith(lastUpdate: now);

    // Siempre guarda localmente primero (modo offline-first)
    await _dbHelper.insertClient(updatedClient);

    // Si hay conexión, también actualiza Firebase
    if (hasConnection) {
      await _firestore
          .collection('clients')
          .doc(client.id)
          .set(updatedClient.toMap());
    } else {}
  }

  /// No usar para eliminar en Firestore raíz `/clients`: no respeta docPath ni políticas de ownership.
  @Deprecated(
      'Evitar operaciones en /clients. Gestionar datos por docPath del cliente')

  /// Elimina cliente
  Future<void> deleteClient(String id) async {
    final hasConnection = await _hasInternetConnection();

    // Siempre elimina localmente
    await _dbHelper.deleteClient(id);

    // Si hay internet, elimina también de Firebase
    if (hasConnection) {
      await _firestore.collection('clients').doc(id).delete();
    } else {}
  }

  /// Fuerza sincronización manual
  Future<void> syncNow() async {
    await _syncService.startSync();
  }

  /// Comprueba conexión actual
  Future<bool> _hasInternetConnection() async {
    final results = await Connectivity().checkConnectivity();

    return results.any((r) => r != ConnectivityResult.none);
  }
}
