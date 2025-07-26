// DEPRECATED: This file is no longer used
// The app now uses local_auth_service.dart for local authentication
// This file is kept for reference but should not be imported

/*
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:firebase_auth/firebase_auth.dart';  // Commented out - Firebase removed
// import 'package:cloud_firestore/cloud_firestore.dart';  // Commented out - Firebase removed
import '../models/user_model.dart';

// DEPRECATED: Use LocalAuthService instead
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Firebase instances commented out
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // Initialize auth service
  Future<void> initialize() async {
    try {
      // Listen to auth state changes only if Firebase is initialized
      _auth.authStateChanges().listen(_onAuthStateChanged);

      // Check if user is already logged in
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await _loadUserData(firebaseUser.uid);
      }
    } catch (e) {
      print('Auth service initialization failed: $e');
      // Continue without Firebase auth for development
    }
  }

  // Handle auth state changes
  void _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser.uid);
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson({'id': userId, ...doc.data()!});

        // Update last active time
        await _updateLastActive();
      }
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Register new user
  Future<String?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create user account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Create user document in Firestore
        final userModel = UserModel(
          id: user.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          isOnline: true,
          deviceInfo: await _getDeviceInfo(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toJson());

        _currentUser = userModel;
        notifyListeners();

        return null; // Success
      }
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return 'Registration failed';
  }

  // Login user
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserData(credential.user!.uid);
        return null; // Success
      }
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return 'Login failed';
  }

  // Logout user
  Future<void> logout() async {
    try {
      if (_currentUser != null) {
        // Update online status
        await _firestore.collection('users').doc(_currentUser!.id).update({
          'isOnline': false,
          'lastActiveAt': DateTime.now().toIso8601String(),
        });
      }

      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Reset password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  // Update user profile
  Future<String?> updateProfile({
    String? displayName,
    String? profileImageUrl,
  }) async {
    try {
      if (_currentUser == null) return 'No user logged in';

      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(_currentUser!.id)
            .update(updates);

        _currentUser = _currentUser!.copyWith(
          displayName: displayName,
          profileImageUrl: profileImageUrl,
        );
        notifyListeners();
      }

      return null; // Success
    } catch (e) {
      return 'Failed to update profile: $e';
    }
  }

  // Update last active time
  Future<void> _updateLastActive() async {
    try {
      if (_currentUser != null) {
        await _firestore.collection('users').doc(_currentUser!.id).update({
          'lastActiveAt': DateTime.now().toIso8601String(),
          'isOnline': true,
        });
      }
    } catch (e) {
      print('Error updating last active: $e');
    }
  }

  // Get device info
  Future<String> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      } else if (Platform.isWindows) {
        return 'Windows Device';
      } else if (Platform.isMacOS) {
        return 'macOS Device';
      } else if (Platform.isLinux) {
        return 'Linux Device';
      }
    } catch (e) {
      print('Error getting device info: $e');
    }
    return 'Unknown Device';
  }

  // Get user-friendly error messages
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  // Get all users (for finding friends)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
          .where((user) => user.id != _currentUser?.id) // Exclude current user
          .toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  // Search users by email or display name
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .where('displayName', isGreaterThanOrEqualTo: query)
              .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
              .get();

      final emailSnapshot =
          await _firestore
              .collection('users')
              .where('email', isGreaterThanOrEqualTo: query)
              .where('email', isLessThanOrEqualTo: '$query\uf8ff')
              .get();

      final users = <UserModel>[];
      final seenIds = <String>{};

      for (final doc in [...snapshot.docs, ...emailSnapshot.docs]) {
        if (!seenIds.contains(doc.id) && doc.id != _currentUser?.id) {
          seenIds.add(doc.id);
          users.add(UserModel.fromJson({'id': doc.id, ...doc.data()}));
        }
      }

      return users;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
*/

// END OF DEPRECATED FILE
// Use LocalAuthService from local_auth_service.dart instead
