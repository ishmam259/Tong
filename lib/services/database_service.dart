import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tong_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table for local caching
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        displayName TEXT NOT NULL,
        profileImageUrl TEXT,
        createdAt TEXT NOT NULL,
        lastActiveAt TEXT NOT NULL,
        isOnline INTEGER NOT NULL DEFAULT 0,
        deviceInfo TEXT,
        lastSyncAt TEXT
      )
    ''');

    // Chat messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        senderId TEXT NOT NULL,
        receiverId TEXT NOT NULL,
        content TEXT NOT NULL,
        messageType TEXT NOT NULL DEFAULT 'text',
        timestamp TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        isSent INTEGER NOT NULL DEFAULT 0,
        isDelivered INTEGER NOT NULL DEFAULT 0,
        localId TEXT,
        FOREIGN KEY (senderId) REFERENCES users (id),
        FOREIGN KEY (receiverId) REFERENCES users (id)
      )
    ''');

    // Bluetooth devices table
    await db.execute('''
      CREATE TABLE bluetooth_devices (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL UNIQUE,
        lastConnected TEXT,
        isPaired INTEGER NOT NULL DEFAULT 0,
        isAutoConnect INTEGER NOT NULL DEFAULT 0,
        deviceType TEXT,
        rssi INTEGER
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        dataType TEXT NOT NULL DEFAULT 'string',
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_messages_sender ON messages(senderId)');
    await db.execute(
      'CREATE INDEX idx_messages_receiver ON messages(receiverId)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_timestamp ON messages(timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_bluetooth_address ON bluetooth_devices(address)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  // User operations
  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      _userToMap(user),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateUser(UserModel user) async {
    final db = await database;
    await db.update(
      'users',
      _userToMap(user),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<UserModel?> getUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return _mapToUser(maps.first);
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return maps.map((map) => _mapToUser(map)).toList();
  }

  Future<void> deleteUser(String userId) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  // Message operations
  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    await db.insert(
      'messages',
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMessage(
    String messageId,
    Map<String, dynamic> updates,
  ) async {
    final db = await database;
    await db.update(
      'messages',
      updates,
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<Map<String, dynamic>>> getMessages(
    String userId1,
    String userId2, {
    int? limit,
  }) async {
    final db = await database;
    String query = '''
      SELECT * FROM messages 
      WHERE (senderId = ? AND receiverId = ?) 
         OR (senderId = ? AND receiverId = ?)
      ORDER BY timestamp DESC
    ''';

    if (limit != null) {
      query += ' LIMIT $limit';
    }

    return await db.rawQuery(query, [userId1, userId2, userId2, userId1]);
  }

  Future<void> markMessageAsRead(String messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> markMessageAsSent(String messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {'isSent': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> markMessageAsDelivered(String messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {'isDelivered': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // Bluetooth device operations
  Future<void> insertBluetoothDevice(Map<String, dynamic> device) async {
    final db = await database;
    await db.insert(
      'bluetooth_devices',
      device,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBluetoothDevice(
    String deviceId,
    Map<String, dynamic> updates,
  ) async {
    final db = await database;
    await db.update(
      'bluetooth_devices',
      updates,
      where: 'id = ?',
      whereArgs: [deviceId],
    );
  }

  Future<List<Map<String, dynamic>>> getPairedBluetoothDevices() async {
    final db = await database;
    return await db.query(
      'bluetooth_devices',
      where: 'isPaired = ?',
      whereArgs: [1],
      orderBy: 'lastConnected DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllBluetoothDevices() async {
    final db = await database;
    return await db.query('bluetooth_devices', orderBy: 'lastConnected DESC');
  }

  Future<void> deleteBluetoothDevice(String deviceId) async {
    final db = await database;
    await db.delete(
      'bluetooth_devices',
      where: 'id = ?',
      whereArgs: [deviceId],
    );
  }

  // Settings operations
  Future<void> setSetting(String key, dynamic value, String dataType) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value.toString(),
      'dataType': dataType,
      'updatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      final setting = maps.first;
      final value = setting['value'] as String;
      final dataType = setting['dataType'] as String;

      switch (dataType) {
        case 'int':
          return int.tryParse(value) as T?;
        case 'double':
          return double.tryParse(value) as T?;
        case 'bool':
          return (value.toLowerCase() == 'true') as T?;
        case 'string':
        default:
          return value as T?;
      }
    }
    return defaultValue;
  }

  Future<void> deleteSetting(String key) async {
    final db = await database;
    await db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }

  // Utility methods
  Map<String, dynamic> _userToMap(UserModel user) {
    return {
      'id': user.id,
      'email': user.email,
      'displayName': user.displayName,
      'profileImageUrl': user.profileImageUrl,
      'createdAt': user.createdAt.toIso8601String(),
      'lastActiveAt': user.lastActiveAt.toIso8601String(),
      'isOnline': user.isOnline ? 1 : 0,
      'deviceInfo': user.deviceInfo,
      'lastSyncAt': DateTime.now().toIso8601String(),
    };
  }

  UserModel _mapToUser(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      displayName: map['displayName'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      lastActiveAt: DateTime.parse(map['lastActiveAt']),
      isOnline: map['isOnline'] == 1,
      deviceInfo: map['deviceInfo'],
    );
  }

  // Database maintenance
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('users');
    await db.delete('messages');
    await db.delete('bluetooth_devices');
    await db.delete('settings');
  }

  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final userCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users'),
        ) ??
        0;

    final messageCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM messages'),
        ) ??
        0;

    final deviceCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM bluetooth_devices'),
        ) ??
        0;

    final settingCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM settings'),
        ) ??
        0;

    return {
      'users': userCount,
      'messages': messageCount,
      'bluetooth_devices': deviceCount,
      'settings': settingCount,
    };
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
