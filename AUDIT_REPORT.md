# 🔴 AUDITORÍA FORENSE - HefestoCS Mobile App
**Fecha:** 31 de diciembre de 2025  
**Auditor:** Arquitecto Senior Flutter + Ingeniero Clínico Forense  
**Estado:** CRÍTICO - Hallazgos P0 Bloqueantes

---

## 📋 RESUMEN EJECUTIVO

La app móvil HefestoCS presenta **FALLOS ARQUITECTÓNICOS CRÍTICOS** que comprometer la integridad de datos clínicos:

- ✗ **2 DatabaseHelper duplicados** creando estados inconsistentes
- ✗ **Imports mixtos** (`../` vs `package:`) crean ambigüedad
- ✗ **DateTime.now() fallbacks silenciosos** en parseo de clínicos
- ✗ **SyncService usa DatabaseHelper() sin singleton**
- ✗ **DataRepository usa DatabaseHelper.instance** (incompatible)
- ✗ **Riesgo de pérdida de datos** en sincronización offline
- ✗ **Sin contrato clínico congelado** (preparación incompleta para v1.0.0)

---

## 🔍 HALLAZGOS DETALLADOS

### **P0 - CRÍTICO: Duplicación DatabaseHelper**

#### Ubicación 1: `lib/database/database_helper.dart` (235 líneas)
```dart
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();  // Singleton .instance
  DatabaseHelper._init();
}
```
- **Patrón:** `.instance` getter
- **DB Name:** `'hcs_client_data.db'`
- **Tablas:** clients, anthropometry_records, biochemistry_records, daily_macros
- **Métodos:** insertClient, getClientById (NO: getAllClients, saveClientData)
- **Riesgo:** Incompleto, no soporta sync

#### Ubicación 2: `lib/data/database_helper.dart` (177 líneas)
```dart
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;  // Factory constructor
  DatabaseHelper._internal();
}
```
- **Patrón:** Factory constructor con `()`
- **DB Name:** `'hefesto.db'`
- **Tablas:** clients, anthropometry_records, biochemistry_records, profile_picture_sync
- **Métodos:** saveClientData, getUnsyncedBiochemistry, markBiochemistryAsSynced, **más completo**
- **Riesgo:** Usado por SyncService, incompatible con DataRepository

#### **Incompatibilidades Críticas:**
| Función | `lib/database/` | `lib/data/` | Usado por |
|---------|-------|-------|----------|
| `getClient(id)` | ✓ | ✗ | SyncService |
| `getAllClients()` | ✗ | ✗ (Fallido) | DataRepository |
| `saveClientData()` | ✗ | ✓ | SyncService |
| `insertClient()` | ✓ | ✗ | DataRepository |
| `getUnsyncedBiochemistry()` | ✗ | ✓ | SyncService |
| `markBiochemistryAsSynced()` | ✗ | ✓ | SyncService |
| Patrón Singleton | `.instance` | `()` | CONFLICTO |

---

### **P0 - CRÍTICO: Incompatibilidad de Imports**

#### `lib/repository/data_repository.dart`
```dart
import '../database/database_helper.dart';  // ← Usa v1 (incompleta)

class DataRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;  // Patrón .instance
  // Llama: insertClient(), getAllClients(), getClientById()
}
```

#### `lib/services/sync_service.dart`
```dart
import '../data/database_helper.dart';  // ← Usa v2 (completa)

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper();  // Patrón factory
  // Llama: getClient(), saveClientData(), getUnsyncedBiochemistry(), etc.
}
```

**Problema:** `DatabaseHelper()` factory y `DatabaseHelper.instance` son CLASES DIFERENTES en memoria.

---

### **P1 - ALTO: DateTime Fallbacks Peligrosos**

#### `lib/models/client_model.dart` líneas 194, 241
```dart
// AnthropometryRecord.fromMap()
date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),  // ✗ PELIGROSO

// BioChemistryRecord.fromMap()
date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),  // ✗ PELIGROSO
```

**Riesgo Clínico:**
- Si `date` es `null` en BD, inventa una fecha actual
- Datos históricos se pierden/corrupen
- Bitácora clínica quedará con fechas falsas
- Auditoría forense imposible

---

### **P1 - ALTO: Side Effects en Providers**

#### `lib/providers/progress_photos_provider.dart` línea 144
```dart
createdAt: DateTime.now(),  // Aceptable en UI, pero no documentado
```

**Riesgo:** Inconsistencia entre timestamp local y sincronización.

---

### **P2 - MEJORA: Imports Relativos**

Encontrados en:
- `lib/services/sync_service.dart` línea 5-6: `import '../data/database_helper.dart'`
- `lib/repository/data_repository.dart` línea 3-5: `import '../database/database_helper.dart'`
- `lib/database/database_helper.dart` línea 4: `import '../models/client_model.dart'`
- `lib/data/database_helper.dart` línea 5: `import '../models/client_model.dart'`

**Riesgo:** App no es resiliente a movimientos de carpeta.

---

### **P1 - ALTO: Gallery I/O Side Effect**

#### `lib/utils/gallery_io.dart` línea 39
```dart
final name = 'progreso_${DateTime.now().millisecondsSinceEpoch}.png';
```

**Riesgo:** Timestamp local, sin sincronización con servidor. Colisiones posibles en multisincronización.

---

### **P2 - MEJORA: Documentación Ausente**

No existe documentación clara sobre:
- Rol de app móvil vs desktop
- Qué datos genera vs solo lee la app móvil
- Contrato clínico congelado v1.0.0
- Flujo offline-first
- Reglas de sincronización

---

## 🎯 CRITERIOS DE ACEPTACIÓN

### Antes de Consolidación
```bash
$ grep "class DatabaseHelper" lib/**/*.dart
# Resultado ACTUAL: 2 archivos ✗
# Resultado ESPERADO: 1 archivo ✓
```

### Después de Consolidación
```bash
$ grep -r "database_helper" lib/ | grep import
# Todos importan: package:hefestocs/data/database_helper.dart ✓
```

### Validación Clínica
```bash
$ flutter analyze          # Debe pasar sin P0
$ flutter test             # Debe pasar 100%
$ grep "DateTime.now()" lib/models/ lib/repository/ lib/services/
# Solo permitido en UI (lib/features/, lib/screens/, lib/providers/)
```

---

## 📊 TABLA DE HALLAZGOS

| ID | Severidad | Archivo | Línea | Problema | Impacto |
|----|-----------|---------|-------|----------|---------|
| F001 | P0 | lib/database/database_helper.dart | 6-10 | DatabaseHelper v1 incompleto | Fallo de sync |
| F002 | P0 | lib/data/database_helper.dart | 7-11 | DatabaseHelper v2 duplicado | Estado inconsistente |
| F003 | P0 | lib/repository/data_repository.dart | 3 | Import a DatabaseHelper v1 | Incompatible con v2 |
| F004 | P0 | lib/services/sync_service.dart | 5 | Import a DatabaseHelper v2 | Incompatible con v1 |
| F005 | P1 | lib/models/client_model.dart | 194 | DateTime.now() fallback | Datos falsos |
| F006 | P1 | lib/models/client_model.dart | 241 | DateTime.now() fallback | Datos falsos |
| F007 | P2 | lib/utils/gallery_io.dart | 39 | DateTime.now() timestamp | Colisiones sync |
| F008 | P2 | lib/providers/progress_photos_provider.dart | 144 | DateTime.now() UI | Side effect no documentado |
| F009 | P2 | Múltiples | N/A | Imports relativos (../) | Frágil a refactor |
| F010 | P2 | N/A | N/A | Sin documentación de rol | Arquitectura ambigua |

---

## ✅ PLAN DE REMEDIACIÓN (7 PASOS)

1. **Consolidar DatabaseHelper**
   - Mantener: `lib/data/database_helper.dart` (completo, con sync)
   - Eliminar: `lib/database/database_helper.dart`
   - Merged schema con ambas versiones

2. **Actualizar Imports**
   - DataRepository: `import '../database/database_helper.dart'` → `import 'package:hefestocs/data/database_helper.dart'`
   - SyncService: Ya correcto pero cambiar a `package:`
   - Todos: Relativos → `package:hefestocs/...`

3. **Endurecer Modelos**
   - Eliminar `DateTime.now()` fallbacks
   - Usar `throw FormatException` si parse falla
   - Documentar cada fecha como "desde servidor" o "local"

4. **Normalizar SyncService**
   - Asegurar uso de singleton
   - Definir qué datos son R/O (read-only) vs R/W
   - Documentar contrato de sincronización

5. **Validar DataRepository**
   - Asegurar métodos `getAllClients()`, `getClientById()` existen
   - Implementar falta de `updateLocalBiochemistry()`

6. **Preparar TrainingSessionLogV2**
   - Crear `lib/models/training_session_log_v2.dart` (contrato, NO lógica)
   - Crear `lib/database/training_logs_table.dart` (DDL, NO cálculos)
   - Puntos de extensión documentados

7. **Validación Final**
   - `flutter analyze` → 0 errores P0
   - `flutter test` → 100% pass
   - Compatibilidad backward con desktop confirmada

---

## 🔐 RESTRICCIONES DE SEGURIDAD

❌ No generar fechas si parse falla  
❌ No modificar datos que solo lee la app móvil  
❌ No calcular progresiones (solo motor desktop)  
❌ No ejecutar lógica clínica en móvil  
❌ No usar imports mixtos  
❌ No romper compatibilidad v1.0.0  
✅ Offline-first con sincronización determinista  
✅ Auditoría longitudinal de cambios  
✅ Rol claro INPUT vs CÁLCULO  

---

**Auditor Firmado:** Sistema de Arquitectura Clínica  
**Riesgo General:** 🔴 CRÍTICO  
**Bloqueador para Producción:** SÍ  
