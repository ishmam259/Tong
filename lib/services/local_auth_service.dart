import 'dart:async';
import 'dart:io'; // For Platform detection
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';

class LocalAuthService extends ChangeNotifier {
  static final LocalAuthService _instance = LocalAuthService._internal();
  factory LocalAuthService() => _instance;
  LocalAuthService._internal();

  Database? _database;
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // Initialize local auth service
  Future<void> initialize() async {
    try {
      await _initializeDatabase();
      await _loadLastLoggedInUser();
    } catch (e) {
      print('Local auth service initialization failed: $e');
    }
  }

  // Initialize SQLite database
  Future<void> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'local_auth.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            display_name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            last_active_at TEXT NOT NULL,
            is_online INTEGER DEFAULT 0,
            device_info TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE user_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            created_at TEXT NOT NULL,
            is_active INTEGER DEFAULT 1,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');
      },
    );
  }

  // Load last logged in user
  Future<void> _loadLastLoggedInUser() async {
    try {
      final sessions = await _database!.query(
        'user_sessions',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (sessions.isNotEmpty) {
        final userId = sessions.first['user_id'] as String;
        await _loadUserData(userId);
      }
    } catch (e) {
      print('Error loading last logged in user: $e');
    }
  }

  // Load user data from local database
  Future<void> _loadUserData(String userId) async {
    try {
      final users = await _database!.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (users.isNotEmpty) {
        final userData = users.first;
        _currentUser = UserModel(
          id: userData['id'] as String,
          email: userData['email'] as String,
          displayName: userData['display_name'] as String,
          createdAt: DateTime.parse(userData['created_at'] as String),
          lastActiveAt: DateTime.parse(userData['last_active_at'] as String),
          isOnline: userData['is_online'] == 1,
          deviceInfo: (userData['device_info'] as String?) ?? 'Local Device',
        );

        // Update last active time
        await _updateLastActive();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Register new user locally
  Future<String?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if user already exists
      final existingUsers = await _database!.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (existingUsers.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
        return 'User with this email already exists';
      }

      // Hash password
      final passwordHash = _hashPassword(password);
      final userId = _generateUserId();
      final now = DateTime.now().toIso8601String();

      // Create user record
      await _database!.insert('users', {
        'id': userId,
        'email': email,
        'password_hash': passwordHash,
        'display_name': displayName,
        'created_at': now,
        'last_active_at': now,
        'is_online': 1,
        'device_info': await _getDeviceInfo(),
      });

      // Create session
      await _createSession(userId);

      // Load user data
      await _loadUserData(userId);

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Registration failed: $e';
    }
  }

  // Sign in user locally
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Find user by email
      final users = await _database!.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (users.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return 'No user found with this email';
      }

      final userData = users.first;
      final storedHash = userData['password_hash'] as String;
      final inputHash = _hashPassword(password);

      if (storedHash != inputHash) {
        _isLoading = false;
        notifyListeners();
        return 'Invalid password';
      }

      // Create new session
      await _createSession(userData['id'] as String);

      // Load user data
      await _loadUserData(userData['id'] as String);

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Sign in failed: $e';
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      if (_currentUser != null) {
        // Deactivate current session
        await _database!.update(
          'user_sessions',
          {'is_active': 0},
          where: 'user_id = ? AND is_active = ?',
          whereArgs: [_currentUser!.id, 1],
        );

        _currentUser = null;
        notifyListeners();
      }
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Update last active time
  Future<void> _updateLastActive() async {
    try {
      if (_currentUser != null) {
        await _database!.update(
          'users',
          {'last_active_at': DateTime.now().toIso8601String(), 'is_online': 1},
          where: 'id = ?',
          whereArgs: [_currentUser!.id],
        );
      }
    } catch (e) {
      print('Error updating last active: $e');
    }
  }

  // Create user session
  Future<void> _createSession(String userId) async {
    try {
      // Deactivate old sessions
      await _database!.update(
        'user_sessions',
        {'is_active': 0},
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // Create new session
      await _database!.insert('user_sessions', {
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': 1,
      });
    } catch (e) {
      print('Error creating session: $e');
    }
  }

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode('${password}salt_tong_app');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate unique user ID
  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000)).round()}';
  }

  // Get device info (supported platforms only)
  Future<String> _getDeviceInfo() async {
    try {
      // Only support Android, iOS, and Windows
      if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      } else if (Platform.isWindows) {
        return 'Windows Device';
      } else {
        // Unsupported platform
        return 'Unsupported Platform';
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }

  // Update user profile
  Future<String?> updateProfile({String? displayName, String? email}) async {
    try {
      if (_currentUser == null) return 'No user logged in';

      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (email != null) {
        // Check if email is already taken
        final existingUsers = await _database!.query(
          'users',
          where: 'email = ? AND id != ?',
          whereArgs: [email, _currentUser!.id],
        );
        if (existingUsers.isNotEmpty) {
          return 'Email is already taken';
        }
        updates['email'] = email;
      }

      if (updates.isNotEmpty) {
        await _database!.update(
          'users',
          updates,
          where: 'id = ?',
          whereArgs: [_currentUser!.id],
        );

        // Reload user data
        await _loadUserData(_currentUser!.id);
      }

      return null; // Success
    } catch (e) {
      return 'Failed to update profile: $e';
    }
  }

  // Change password
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentUser == null) return 'No user logged in';

      // Verify current password
      final users = await _database!.query(
        'users',
        where: 'id = ?',
        whereArgs: [_currentUser!.id],
      );

      if (users.isEmpty) return 'User not found';

      final storedHash = users.first['password_hash'] as String;
      final currentHash = _hashPassword(currentPassword);

      if (storedHash != currentHash) {
        return 'Current password is incorrect';
      }

      // Update password
      final newHash = _hashPassword(newPassword);
      await _database!.update(
        'users',
        {'password_hash': newHash},
        where: 'id = ?',
        whereArgs: [_currentUser!.id],
      );

      return null; // Success
    } catch (e) {
      return 'Failed to change password: $e';
    }
  }
}
