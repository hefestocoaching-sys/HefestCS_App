import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hefestocs/models/client_model.dart';

/// 🔐 DatabaseHelper CANÓNICO Y CONSOLIDADO
///
/// Esta clase es el ÚNICO punto de acceso a la base de datos de la app móvil.
/// Consolidación de lib/database/database_helper.dart y lib/data/database_helper.dart
///
/// Rol:
/// - Persistencia LOCAL de datos clínicos (offline-first)
/// - Control de sincronización con Firebase
/// - Auditoría de cambios (isSynced flags)
/// - Ningún cálculo, solo CRUD
///
/// Patrón Singleton:
/// - Acceso via DatabaseHelper.instance (compatible con DataRepository)
/// - Factory constructor DatabaseHelper() también funciona
///
/// DB Name: 'hefesto.db'
/// Version: 1
///
/// Tablas:
/// 1. clients - Datos clínicos principales (READ/WRITE by mobile)
/// 2. anthropometry_records - Historiales antropométricos (READ/WRITE)
/// 3. biochemistry_records - Bioquímica con sync flag (READ/WRITE + SYNC)
/// 4. daily_macros - Macros diarios (READ from server, WRITE local)
/// 5. profile_picture_sync - Tracking de fotos de progreso (WRITE + SYNC)
class DatabaseHelper {
  /// SINGLETON: Patrón dual compatible
  /// - DatabaseHelper.instance (usado por DataRepository)
  /// - DatabaseHelper() (usado por SyncService)
  static final DatabaseHelper _instance = DatabaseHelper._init();
  static final DatabaseHelper instance = _instance;

  static Database? _database;

  DatabaseHelper._init();
  factory DatabaseHelper() => _instance;

  /// Acceso lazy a la BD
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  /// Inicialización de la BD
  /// Path: getApplicationDocumentsDirectory()/hefesto.db
  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'hefesto.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// [DDL] Creación inicial de tablas (version 1)
  ///
  /// Schema Notes:
  /// - clients.profilePictureUrl: Sincronizado desde Firebase
  /// - clients.dailyMacros: JSON string (serializado)
  /// - biochemistry_records.isSynced: Flag para control de sincronización
  /// - profile_picture_sync: Tracking de fotos locales sin sincronizar
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        age INTEGER,
        gender TEXT,
        initialHeightCm REAL,
        currentWeightKg REAL,
        kcalTarget REAL,
        proteinG REAL,
        fatG REAL,
        carbG REAL,
        tmb REAL,
        totalEnergyExpenditure REAL,
        goal TEXT,
        status TEXT,
        lastUpdate TEXT,
        profilePictureUrl TEXT,
        dailyMacros TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE anthropometry_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId TEXT NOT NULL,
        date TEXT NOT NULL,
        weightKg REAL,
        heightCm REAL,
        bmi REAL,
        bodyFatPercentage REAL,
        leanBodyMassKg REAL,
        musclePercentage REAL,
        FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE biochemistry_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId TEXT NOT NULL,
        date TEXT NOT NULL,
        values TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_macros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId TEXT NOT NULL,
        kcal REAL,
        protein REAL,
        fats REAL,
        carbs REAL,
        FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE profile_picture_sync (
        clientId TEXT PRIMARY KEY,
        localPath TEXT NOT NULL,
        FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');
  }

  /// [DDL] Migraciones futuras (versiones > 1)
  ///
  /// Esta función será invocada si la versión de BD aumenta.
  /// Implementar migraciones progresivas y NUNCA destructivas.
  /// Ej: ALTER TABLE, CREATE INDEX, etc.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Placeholder para migraciones futuras
    // Estructura: if (oldVersion < 2) { ... migraciones v1->v2 ... }
  }

  // ============================================================
  // CLIENTE CRUD (compatible con ambas versiones antiguas)
  // ============================================================

  /// Inserta o reemplaza un cliente (desde servidor o local)
  ///
  /// Rol: Lectura desde Firebase (downgrade)
  /// Transacción: NO (llamado por SyncService en transacción)
  /// Side effects: Borra antigos registros del cliente si existen
  Future<void> insertClient(Client client) async {
    final db = await database;
    await db.insert(
      'clients',
      client.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene cliente + historiales por ID
  ///
  /// Rol: Lectura para UI (offline)
  /// Retorna: Client completo con historia
  /// Notas: Sin flag isSynced (datos de servidor ya sincronizados)
  Future<Client?> getClientById(String id) async {
    final db = await database;

    final clientMap =
        await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (clientMap.isEmpty) return null;

    final anthropometryMaps = await db
        .query('anthropometry_records', where: 'clientId = ?', whereArgs: [id]);
    final biochemistryMaps = await db
        .query('biochemistry_records', where: 'clientId = ?', whereArgs: [id]);
    final dailyMacrosMaps =
        await db.query('daily_macros', where: 'clientId = ?', whereArgs: [id]);

    return Client(
      id: clientMap.first['id'] as String,
      fullName: clientMap.first['fullName'] as String,
      age: clientMap.first['age'] as int?,
      gender: clientMap.first['gender'] as String?,
      initialHeightCm: clientMap.first['initialHeightCm'] as double?,
      currentWeightKg: clientMap.first['currentWeightKg'] as double?,
      kcalTarget: clientMap.first['kcalTarget'] as double?,
      proteinG: clientMap.first['proteinG'] as double?,
      fatG: clientMap.first['fatG'] as double?,
      carbG: clientMap.first['carbG'] as double?,
      tmb: clientMap.first['tmb'] as double?,
      totalEnergyExpenditure:
          clientMap.first['totalEnergyExpenditure'] as double?,
      goal: clientMap.first['goal'] as String?,
      status: clientMap.first['status'] as String?,
      lastUpdate: clientMap.first['lastUpdate'] != null
          ? DateTime.tryParse(clientMap.first['lastUpdate'] as String)
          : null,
      anthropometryHistory:
          anthropometryMaps.map((e) => AnthropometryRecord.fromMap(e)).toList(),
      biochemistryHistory:
          biochemistryMaps.map((e) => BioChemistryRecord.fromMap(e)).toList(),
      dailyMacros: dailyMacrosMaps.isNotEmpty
          ? DailyMacroSettings.fromMap(dailyMacrosMaps.first)
          : null,
    );
  }

  /// Obtiene TODOS los clientes sincronizados
  ///
  /// Rol: Offline-first, para listar clientes locales
  /// Retorna: `List&lt;Client&gt;` con historiales completos
  Future<List<Client>> getAllClients() async {
    final db = await database;
    final clients = await db.query('clients');
    List<Client> list = [];

    for (var clientMap in clients) {
      final clientId = clientMap['id'] as String;
      final anthropometryMaps = await db.query(
        'anthropometry_records',
        where: 'clientId = ?',
        whereArgs: [clientId],
      );
      final biochemistryMaps = await db.query(
        'biochemistry_records',
        where: 'clientId = ?',
        whereArgs: [clientId],
      );
      final dailyMacrosMaps = await db.query(
        'daily_macros',
        where: 'clientId = ?',
        whereArgs: [clientId],
      );

      list.add(Client(
        id: clientMap['id'] as String,
        fullName: clientMap['fullName'] as String,
        age: clientMap['age'] as int?,
        gender: clientMap['gender'] as String?,
        initialHeightCm: clientMap['initialHeightCm'] as double?,
        currentWeightKg: clientMap['currentWeightKg'] as double?,
        kcalTarget: clientMap['kcalTarget'] as double?,
        proteinG: clientMap['proteinG'] as double?,
        fatG: clientMap['fatG'] as double?,
        carbG: clientMap['carbG'] as double?,
        tmb: clientMap['tmb'] as double?,
        totalEnergyExpenditure: clientMap['totalEnergyExpenditure'] as double?,
        goal: clientMap['goal'] as String?,
        status: clientMap['status'] as String?,
        lastUpdate: clientMap['lastUpdate'] != null
            ? DateTime.tryParse(clientMap['lastUpdate'] as String)
            : null,
        anthropometryHistory: anthropometryMaps
            .map((e) => AnthropometryRecord.fromMap(e))
            .toList(),
        biochemistryHistory:
            biochemistryMaps.map((e) => BioChemistryRecord.fromMap(e)).toList(),
        dailyMacros: dailyMacrosMaps.isNotEmpty
            ? DailyMacroSettings.fromMap(dailyMacrosMaps.first)
            : null,
      ));
    }
    return list;
  }

  /// Elimina cliente y todos sus historiales
  ///
  /// Rol: Limpieza local (cascade en FOREIGN KEY)
  /// Retorna: Número de filas eliminadas
  Future<int> deleteClient(String id) async {
    final db = await database;
    return await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // SYNC CONTROL (bioquímica y fotos de progreso)
  // ============================================================

  /// Guarda cliente desde servidor (transaccional)
  ///
  /// Rol: SyncService - descarga desde Firebase
  /// Garantías: Transacción ACID, reemplaza datos no-synced
  /// Nota: Borra bioquímica con isSynced=0 (local no enviado) y reinserta sincronizada
  Future<void> saveClientData(Client client) async {
    final db = await database;
    await db.transaction((txn) async {
      final clientMap = client.toMap();
      clientMap.remove('anthropometryHistory');
      clientMap.remove('biochemistryHistory');
      clientMap['dailyMacros'] = client.dailyMacros != null
          ? jsonEncode(client.dailyMacros!.toMap())
          : null;

      await txn.insert('clients', clientMap,
          conflictAlgorithm: ConflictAlgorithm.replace);

      // Reemplaza antropometría completamente
      await txn.delete('anthropometry_records',
          where: 'clientId = ?', whereArgs: [client.id]);
      if (client.anthropometryHistory != null) {
        for (final record in client.anthropometryHistory!) {
          await txn.insert('anthropometry_records',
              {'clientId': client.id, ...record.toMap()});
        }
      }

      // Reemplaza bioquímica sincronizada, mantiene local no-enviada
      await txn.delete('biochemistry_records',
          where: 'clientId = ? AND isSynced = 1', whereArgs: [client.id]);
      if (client.biochemistryHistory != null) {
        for (final record in client.biochemistryHistory!) {
          await txn.insert('biochemistry_records', {
            'clientId': client.id,
            'date': record.date.toIso8601String(),
            'values': jsonEncode(record.values),
            'isSynced': 1,
          });
        }
      }
    });
  }

  /// Añade registro bioquímico LOCAL (no sincronizado)
  ///
  /// Rol: App móvil - captura local de datos clínicos
  /// Flag: isSynced=0 (pendiente de envío)
  /// Notas: SyncService luego enviará a Firebase
  Future<void> addLocalBiochemistry(
      String clientId, BioChemistryRecord record) async {
    final db = await database;
    await db.insert('biochemistry_records', {
      'clientId': clientId,
      'date': record.date.toIso8601String(),
      'values': jsonEncode(record.values),
      'isSynced': 0,
    });
  }

  /// Obtiene bioquímica LOCAL SIN SINCRONIZAR
  ///
  /// Rol: SyncService - prepara para upload a Firebase
  /// Retorna: Registros con isSynced=0
  /// Garantía: No retorna datos ya sincronizados
  Future<List<Map<String, dynamic>>> getUnsyncedBiochemistry(
      String clientId) async {
    final db = await database;
    return await db.query(
      'biochemistry_records',
      where: 'clientId = ? AND isSynced = 0',
      whereArgs: [clientId],
    );
  }

  /// Marca registros como sincronizados
  ///
  /// Rol: SyncService - post-upload a Firebase
  /// Precondición: IDs deben ser válidos
  /// Notas: Bulk update para eficiencia
  Future<void> markBiochemistryAsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    await db.update(
      'biochemistry_records',
      {'isSynced': 1},
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  /// Guarda path local de foto de progreso (para upload)
  ///
  /// Rol: ProgressPhotosProvider - captura local
  /// Notas: SyncService luego sube a Firebase Storage
  Future<void> saveProfilePicturePath(String clientId, String path) async {
    final db = await database;
    await db.insert(
      'profile_picture_sync',
      {'clientId': clientId, 'localPath': path},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene foto de progreso LOCAL SIN SINCRONIZAR
  ///
  /// Rol: SyncService - prepara para upload a Firebase Storage
  /// Retorna: Map con {clientId, localPath} o null
  Future<Map<String, dynamic>?> getUnsyncedProfilePicture(
      String clientId) async {
    final db = await database;
    final res = await db.query(
      'profile_picture_sync',
      where: 'clientId = ?',
      whereArgs: [clientId],
    );
    return res.isNotEmpty ? res.first : null;
  }

  /// Limpia tracking de foto una vez sincronizada
  ///
  /// Rol: SyncService - post-upload a Firebase Storage
  /// Notas: Foto ya está en servidor
  Future<void> clearUnsyncedProfilePicture(String clientId) async {
    final db = await database;
    await db.delete(
      'profile_picture_sync',
      where: 'clientId = ?',
      whereArgs: [clientId],
    );
  }

  /// Obtiene cliente CON datos de sync (usado por SyncService)
  ///
  /// Rol: SyncService - obtiene datos locales para merge
  /// Retorna: Client completo desde BD local
  /// Notas: Restaura JSON de dailyMacros y bioquímica
  Future<Client?> getClient(String clientId) async {
    final db = await database;
    final res =
        await db.query('clients', where: 'id = ?', whereArgs: [clientId]);

    if (res.isEmpty) return null;

    final clientData = Map<String, dynamic>.from(res.first);

    final anthropometryMaps = await db.query(
      'anthropometry_records',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC',
    );
    clientData['anthropometryHistory'] = anthropometryMaps;

    final biochemistryMaps = await db.query(
      'biochemistry_records',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC',
    );
    clientData['biochemistryHistory'] = biochemistryMaps.map((record) {
      final decodedRecord = Map<String, dynamic>.from(record);
      decodedRecord['values'] = jsonDecode(record['values'] as String);
      return decodedRecord;
    }).toList();

    if (clientData['dailyMacros'] != null) {
      clientData['dailyMacros'] =
          jsonDecode(clientData['dailyMacros'] as String);
    }

    return Client.fromMap(clientData);
  }

  /// Cierra la conexión a BD (cleanup)
  ///
  /// Rol: App lifecycle (puede no ser necesario en Flutter)
  /// Notas: Llamar en disposed si es necesario
  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
  }
}
