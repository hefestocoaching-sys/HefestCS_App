# 🔗 TrainingSessionLogV2 - Puntos de Extensión

## Estado Actual
- ✅ Contrato de datos definido (lib/models/training_session/training_session_log_v2.dart)
- ✅ Schema DDL preparado (lib/database/training_logs/training_session_log_table_ddl.dart)
- ⏳ Implementación PENDIENTE (no es responsabilidad de app móvil esta versión)

## Tareas FUTURAS (cuando app desktop esté lista)

### Fase 1: Persistencia Local
1. Integrar tabla a DatabaseHelper._onCreate()
2. Crear TrainingSessionRepository con CRUD básico
3. Implementar getUnsyncedSessions() para sync

### Fase 2: Sincronización
4. Extender SyncService.syncAllData() para training logs
5. Crear TrainingLogSyncAdapter (Firebase <-> local)
6. Implementar markSessionAsSynced()

### Fase 3: Validación
7. Crear TrainingLogValidator (sin lógica clínica)
8. Verificar integridad: checksum, fechas, references
9. Pruebas end-to-end: mobile -> Firebase -> desktop

### Fase 4: Versioning
10. Si hay cambios de schema → v2.0.0
11. Mantener compatibilidad backward con v1.0.0

## Restricciones Obligatorias

❌ NO implementar:
- Cálculos de progresión
- Decisiones de cambio de carga
- Generación de planes
- Machine learning / modelos predictivos

✅ SOLO permitido:
- CRUD simple (Create, Read, Update, Delete)
- Validación de formato
- Sincronización offline-first
- Auditoría de cambios

## Puntos de Extensión

### 1. DatabaseHelper
```dart
// Ubicación: lib/data/database_helper.dart
// Añadir en _onCreate():
await db.execute(trainingSessionLogTableDDL);
```

### 2. TrainingSessionRepository (crear nuevo)
```dart
// Ubicación: lib/repository/training_session_repository.dart
// Métodos: insertLog, getLog, getByClient, getUnsync, markSynced, updateLog, deleteLog

class TrainingSessionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  // CRUD sin decisiones clínicas
}
```

### 3. SyncService
```dart
// Ubicación: lib/services/sync_service.dart
// Extender syncAllData():

Future<void> syncTrainingLogs(String clientId) async {
  // 1. Obtener logs no-sincronizados localmente
  // 2. Validar integridad (checksum)
  // 3. Subir a Firebase (batch)
  // 4. Marcar como synced en BD local
  // 5. Capturar logs nuevos del servidor
}
```

### 4. UI de Bitácora (crear futuro)
```dart
// Ubicación: lib/screens/subscreens/logbook_screen.dart
// Ya existe placeholder, implementar:
// - Listar sesiones de entrenamiento
// - Mostrar ejercicios (modo read-only del desktop)
// - Permitir anotaciones locales (notas, modificaciones)
// - Indicador de sync status
```

## Validación Clínica de Datos

```dart
// Ejemplos de validaciones PERMITIDAS:
- date es DateTime válido ✓
- exercise_id existe en plan ✓
- reps > 0 ✓
- weight > 0 ✓
- completionPercentage = ejercicios_completados / total ✓
- checksumSHA256 válido ✓

// Ejemplos que NO PERMITIR:
- Calcular max = weight * reps / 36 ✗
- Generar recomendación de aumento ✗
- Decidir cambio de ejercicio ✗
- Estimar progresión futura ✗
```

## Timeline de Implementación

### Hito 1: App Móvil Estable (ACTUAL)
- ✅ DatabaseHelper consolidado
- ✅ Sync offline-first
- ✅ Modelos reforzados

### Hito 2: TrainingSessionLog v1.0.0 (PRÓXIMO)
- ⏳ CRUD de sesiones
- ⏳ Sincronización básica
- ⏳ Validación de integridad

### Hito 3: Integración Desktop (FUTURO)
- ⏳ Descarga de planes
- ⏳ Procesamiento de logs
- ⏳ Generación de reportes

### Hito 4: Certificación Clínica (FINAL)
- ⏳ Auditoría forense
- ⏳ Validación médica
- ⏳ Liberación v1.0.0 completa

## Referencias

- [TrainingSessionLogV2 Contrato](lib/models/training_session/training_session_log_v2.dart)
- [DDL y Schema](lib/database/training_logs/training_session_log_table_ddl.dart)
- [DatabaseHelper Canónico](lib/data/database_helper.dart)
- [SyncService](lib/services/sync_service.dart)
- [Auditoría Completa](AUDIT_REPORT.md)
