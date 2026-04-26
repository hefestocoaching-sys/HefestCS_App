import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hefestocs/models/exercise_preferences.dart';

/// Provider que maneja preferencias de ejercicios:
/// - Lectura desde Firebase
/// - Escritura a Firebase
/// - Estado local con sync
class ExercisePreferencesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ExercisePreferencesByMuscle _preferences =
      const ExercisePreferencesByMuscle();
  bool _isLoading = false;
  String? _error;

  ExercisePreferencesByMuscle get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carga preferencias del cliente desde Firebase
  /// Path: /clients/{clientId}/profile/training/extra
  Future<void> loadPreferences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _error = 'No authenticated user';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final docRef = _firestore
          .collection('clients')
          .doc(user.uid)
          .collection('profile')
          .doc('training');

      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data();
        final extra = data?['extra'] as Map<String, dynamic>? ?? {};
        final rawPrefs =
            extra['exercisePreferencesByMuscle'] as Map<String, dynamic>?;

        if (rawPrefs != null) {
          _preferences = ExercisePreferencesByMuscle.fromDynamic(rawPrefs);
        } else {
          _preferences = const ExercisePreferencesByMuscle();
        }
      }
    } on FirebaseException catch (e) {
      _error = 'Firebase error: ${e.message}';
    } catch (e) {
      _error = 'Error loading preferences: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Guarda preferencias del cliente a Firebase
  /// Path: /clients/{clientId}/profile/training/extra/exercisePreferencesByMuscle
  Future<void> savePreferences(ExercisePreferencesByMuscle preferences) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _error = 'No authenticated user';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final docRef = _firestore
          .collection('clients')
          .doc(user.uid)
          .collection('profile')
          .doc('training');

      // Usar transaction para actualizar extra['exercisePreferencesByMuscle']
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final data = doc.data() ?? {};
        final extra = (data['extra'] as Map<String, dynamic>?) ?? {};

        extra['exercisePreferencesByMuscle'] = preferences.toJson();
        extra['lastUpdatedAt'] = FieldValue.serverTimestamp();

        transaction.set(docRef, {
          ...data,
          'extra': extra,
        }, SetOptions(merge: true));
      });

      // Actualizar estado local
      _preferences = preferences;
      _error = null;
    } on FirebaseException catch (e) {
      _error = 'Firebase error: ${e.message}';
    } catch (e) {
      _error = 'Error saving preferences: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Limpia preferencias (reset a vacío)
  Future<void> clearPreferences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _error = 'No authenticated user';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final docRef = _firestore
          .collection('clients')
          .doc(user.uid)
          .collection('profile')
          .doc('training');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final data = doc.data() ?? {};
        final extra = (data['extra'] as Map<String, dynamic>?) ?? {};

        extra.remove('exercisePreferencesByMuscle');
        extra['lastUpdatedAt'] = FieldValue.serverTimestamp();

        transaction.set(docRef, {
          ...data,
          'extra': extra,
        }, SetOptions(merge: true));
      });

      _preferences = const ExercisePreferencesByMuscle();
      _error = null;
    } on FirebaseException catch (e) {
      _error = 'Firebase error: ${e.message}';
    } catch (e) {
      _error = 'Error clearing preferences: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Escucha cambios en tiempo real (para cuando coach actualiza planes)
  Stream<ExercisePreferencesByMuscle> watchPreferences() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error('No authenticated user');
    }

    return _firestore
        .collection('clients')
        .doc(user.uid)
        .collection('profile')
        .doc('training')
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return const ExercisePreferencesByMuscle();
          }

          final data = doc.data();
          final extra = data?['extra'] as Map<String, dynamic>? ?? {};
          final rawPrefs =
              extra['exercisePreferencesByMuscle'] as Map<String, dynamic>?;

          return rawPrefs != null
              ? ExercisePreferencesByMuscle.fromDynamic(rawPrefs)
              : const ExercisePreferencesByMuscle();
        });
  }
}
