import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hefestocs/data/database_helper.dart';
import 'package:hefestocs/models/client_model.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> syncAllData(String clientId) async {
    await _downloadDataFromServer(clientId);
    await _uploadClientData(clientId);
  }

  Future<void> _downloadDataFromServer(String clientId) async {
    final docRef = _firestore.collection('clients').doc(clientId);
    DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await docRef.get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return;
      }
      rethrow;
    }

    if (doc.exists) {
      final serverData = doc.data() as Map<String, dynamic>;
      final localClient = await _dbHelper.getClient(clientId);

      final serverLastUpdate =
          (serverData['lastUpdate'] as Timestamp?)?.toDate();

      if (localClient == null ||
          serverLastUpdate == null ||
          (localClient.lastUpdate != null &&
              serverLastUpdate.isAfter(localClient.lastUpdate!))) {
        final client = Client.fromMap(serverData);
        await _dbHelper.saveClientData(client);
      }
    }
  }

  Future<void> _uploadClientData(String clientId) async {
    await _uploadBiochemistry(clientId);
    await _uploadProfilePicture(clientId);
  }

  /// No usar: escribe en colección raíz `/clients/{clientId}` y no respeta docPath.
  ///
  /// Reemplazo recomendado (capa de datos nueva):
  /// - `ClientDataService.upsertBiochemistryForDay(...)` bajo
  ///   `coaches/{coachId}/clients/{clientId}/biochemistry_records/{YYYY-MM-DD}`
  @Deprecated(
      'Usar ClientDataService.upsertBiochemistryForDay con subcolecciones bajo docPath')
  Future<void> _uploadBiochemistry(String clientId) async {
    final unsyncedRecords = await _dbHelper.getUnsyncedBiochemistry(clientId);
    if (unsyncedRecords.isEmpty) return;

    final clientRef = _firestore.collection('clients').doc(clientId);
    final batch = _firestore.batch();

    final recordIdsToMark = <int>[];

    for (final recordMap in unsyncedRecords) {
      final record = BioChemistryRecord.fromMap({
        'date': recordMap['date'],
        'values': recordMap['values'] is String
            ? jsonDecode(recordMap['values'])
            : recordMap['values'],
      });

      batch.update(clientRef, {
        'biochemistryHistory': FieldValue.arrayUnion([record.toMap()])
      });
      recordIdsToMark.add(recordMap['id'] as int);
    }

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return;
      }
      rethrow;
    }
    await _dbHelper.markBiochemistryAsSynced(recordIdsToMark);
  }

  /// No usar: escribe en colección raíz `/clients/{clientId}` y no respeta docPath.
  ///
  /// Reemplazo recomendado (capa de datos nueva):
  /// - Registrar metadatos como foto de progreso con
  ///   `ClientDataService.createProgressPhoto(...)` bajo
  ///   `coaches/{coachId}/clients/{clientId}/progress_photos/{autoId}`
  @Deprecated(
      'Usar ClientDataService.createProgressPhoto con subcolección bajo docPath')
  Future<void> _uploadProfilePicture(String clientId) async {
    final pictureData = await _dbHelper.getUnsyncedProfilePicture(clientId);
    if (pictureData == null) return;

    final localPath = pictureData['localPath'] as String;
    final file = File(localPath);

    if (await file.exists()) {
      try {
        final ref = _storage
            .ref('profile_pictures/$clientId/${file.path.split('/').last}');
        final uploadTask = await ref.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        try {
          await _firestore.collection('clients').doc(clientId).update({
            'profilePictureUrl': downloadUrl,
            'lastUpdate': FieldValue.serverTimestamp(),
          });
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied') {
            return;
          }
          rethrow;
        }

        await _dbHelper.clearUnsyncedProfilePicture(clientId);
      } catch (e) {
        // Handle upload error, maybe log it or notify user
      }
    }
  }

  Future<void> updateLocalBiochemistry(
      String clientId, BioChemistryRecord record) async {
    await _dbHelper.addLocalBiochemistry(clientId, record);
  }

  Future<void> updateLocalProfilePicture(
      String clientId, String imagePath) async {
    await _dbHelper.saveProfilePicturePath(clientId, imagePath);
  }

  /// Escucha cambios de conectividad
  void listenForConnectivityChanges() {
    // Implementación de escucha de cambios de conectividad
    // Se puede expandir según necesidades
  }

  /// Inicia sincronización manual
  Future<void> startSync() async {
    // Se puede implementar sincronización de todos los clientes
    // o lógica de sincronización selectiva
  }
}
