# 🔍 Debug: Validación de Código de Invitación

## Objetivo
Detectar por qué el código `HCS-DTNT-APZN` se marca como inválido cuando debería ser válido.

## Cambios Implementados

### ✅ InvitationCodeService.validateCode()

**Normalización conservadora:**
- ✅ `trim()` - Elimina espacios al inicio/final
- ✅ `toUpperCase()` - Convierte a mayúsculas
- ❌ **NO** se quitan guiones (`-`)
- ❌ **NO** se usa `toLowerCase()`

**Logs agregados:**
```dart
🔎 RAW INPUT: "[código tal como se ingresó]"
🧹 NORMALIZED: "[código normalizado]"
📦 DOCS FOUND: [número de documentos encontrados]
📄 DOC DATA: [datos del primer documento si existe]
```

## Pasos de Prueba

### 1️⃣ Probar con código válido

1. Ejecutar la app en modo debug
2. Ingresar el código: `HCS-DTNT-APZN`
3. Presionar "Acceder"
4. Revisar la consola de debug

**Salida esperada:**
```
🔎 RAW INPUT: "HCS-DTNT-APZN"
🧹 NORMALIZED: "HCS-DTNT-APZN"
📦 DOCS FOUND: 1
📄 DOC DATA: {fullName: ..., invitationCode: HCS-DTNT-APZN, ...}
✅ Código válido → clientId: "...", path: "..."
```

**Si DOCS FOUND = 0:**
- El código no existe en Firestore con ese formato exacto
- Verificar que en Firestore el campo sea exactamente `HCS-DTNT-APZN` (mayúsculas, con guiones)

### 2️⃣ Probar variaciones (opcional)

Probar ingresando:
- `hcs-dtnt-apzn` (minúsculas) → debe normalizarse a `HCS-DTNT-APZN`
- ` HCS-DTNT-APZN ` (con espacios) → debe normalizarse a `HCS-DTNT-APZN`
- `HCS-DTNT-APZN` (exacto) → debe funcionar directamente

### 3️⃣ Activar prueba de aislamiento (si es necesario)

Si `DOCS FOUND = 0`, descomentar el bloque en `InvitationCodeService`:

```dart
// En validateCode(), después de "Código no encontrado"
final test = await _firestore
  .collectionGroup('clients')
  .limit(5)
  .get();
debugPrint('🧪 EXISTING CODES: ${test.docs.map((d)=>d['invitationCode']).toList()}');
```

Esto mostrará los primeros 5 códigos reales en Firestore para comparar formato.

**Salida esperada:**
```
🧪 EXISTING CODES: [HCS-XXXX-YYYY, HCS-AAAA-BBBB, ...]
```

## Posibles Problemas y Soluciones

### ❌ Problema: DOCS FOUND = 0

**Causas posibles:**
1. El código en Firestore está en minúsculas: `hcs-dtnt-apzn`
   - **Solución:** Actualizar el código en Firestore a mayúsculas
   
2. El código en Firestore no tiene guiones: `HCSDTNTAPZN`
   - **Solución:** Actualizar el código en Firestore con guiones
   
3. El código tiene espacios o caracteres extra en Firestore: `HCS-DTNT-APZN `
   - **Solución:** Limpiar el código en Firestore
   
4. El campo no se llama `invitationCode` en Firestore
   - **Solución:** Verificar nombre del campo

### ❌ Problema: Error de índice

**Mensaje de error:**
```
The query requires an index. You can create it here: [URL]
```

**Solución:**
- Hacer clic en la URL proporcionada
- Esperar 2-5 minutos a que se cree el índice
- Reintentar la query

### ✅ Problema resuelto

Si `DOCS FOUND = 1` y se muestra el documento:
1. Eliminar todos los `debugPrint` de InvitationCodeService (excepto los de error)
2. Comentar nuevamente el bloque de prueba de aislamiento
3. El código está funcionando correctamente

## Limpieza Final

Una vez confirmado que funciona, eliminar/simplificar logs:

```dart
// Mantener solo:
debugPrint('✅ Access OK → $clientId | ${result.coachId} | ${result.displayName}');

// En caso de error:
debugPrint('❌ Error validando código de invitación: $e');
```

## Verificación en Firestore

Para confirmar el formato correcto del código en Firebase Console:

1. Ir a Firebase Console → Firestore Database
2. Navegar a: `coaches/{coachId}/clients/{clientId}`
3. Verificar que el campo `invitationCode` tenga el valor exacto: `HCS-DTNT-APZN`
4. Verificar que no haya espacios, mayúsculas/minúsculas incorrectas

---

**Nota:** Este documento es temporal para debugging. Eliminar una vez resuelto el problema.
