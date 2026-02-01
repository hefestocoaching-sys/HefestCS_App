// DDL para TrainingSessionLogV2 - Referencia Documentation
//
// Este archivo es SOLO documentación, no código Dart ejecutable.
// Para integración, copiar el SQL a DatabaseHelper._onCreate()

/*
 * TABLA: training_session_logs
 * 
 * Propósito:
 * - Almacenar sesiones de entrenamiento completadas por usuario
 * - Tracking para sincronización offline-first con Firebase
 * - Auditoría clínica de ejecución de planes
 * 
 * Integración pendiente:
 * 1. Copiar CREATE TABLE a DatabaseHelper._onCreate()
 * 2. Crear TrainingSessionRepository para CRUD
 * 3. Extender SyncService.syncAllData() para incluir training logs
 */

const String trainingSessionLogDdl = '''
CREATE TABLE training_session_logs (
  -- Identidad
  id TEXT PRIMARY KEY,
  clientId TEXT NOT NULL,
  trainingPlanId TEXT NOT NULL,
  
  -- Secuencia en plan
  sessionNumber INTEGER NOT NULL,
  trainingPhase INTEGER NOT NULL,
  
  -- Control de tiempo
  startedAt TEXT NOT NULL,
  completedAt TEXT,
  
  -- Contenido (JSON arrays)
  exercises TEXT NOT NULL,
  sessionNotes TEXT,
  
  -- Metadatos de sincronización
  completionPercentage INTEGER NOT NULL DEFAULT 0,
  isSynced INTEGER NOT NULL DEFAULT 0,
  checksumSHA256 TEXT,
  
  -- Auditoría
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  
  -- Restricción de integridad
  FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
);
''';

const String trainingSessionLogIndexes = '''
CREATE INDEX idx_training_logs_clientId ON training_session_logs(clientId);
CREATE INDEX idx_training_logs_trainingPlanId ON training_session_logs(trainingPlanId);
CREATE INDEX idx_training_logs_isSynced ON training_session_logs(isSynced);
CREATE INDEX idx_training_logs_startedAt ON training_session_logs(startedAt);
''';

// METODOS A IMPLEMENTAR EN TrainingSessionRepository (FUTURO)
//
// class TrainingSessionRepository {
//   final DatabaseHelper _dbHelper = DatabaseHelper.instance;
//
//   Future<void> insertLog(TrainingSessionLogV2 log) async { ... }
//   Future<TrainingSessionLogV2?> getLog(String id) async { ... }
//   Future<List<TrainingSessionLogV2>> getByClient(String clientId) async { ... }
//   Future<List<TrainingSessionLogV2>> getUnsynced() async { ... }
//   Future<void> markSynced(String id) async { ... }
//   Future<void> update(TrainingSessionLogV2 log) async { ... }
//   Future<void> delete(String id) async { ... }
// }
