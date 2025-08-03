import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FirebaseAuthService extends ChangeNotifier {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  bool _isLoading = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  // User model for app
  TongUser? get currentTongUser {
    if (_currentUser == null) return null;
    return TongUser(
      id: _currentUser!.uid,
      email: _currentUser!.email ?? '',
      displayName: _currentUser!.displayName ?? 'User',
    );
  }

  /// Initialize Firebase Auth
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Listen to auth state changes
      _auth.authStateChanges().listen((User? user) {
        _currentUser = user;
        notifyListeners();
      });

      // Get current user
      _currentUser = _auth.currentUser;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Firebase Auth initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with email and password
  Future<String?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    try {
      // Create user account
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      await _createUserDocument(userCredential.user!, displayName);

      // Reload user to get updated info
      await userCredential.user?.reload();
      _currentUser = _auth.currentUser;
      notifyListeners();

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'An unexpected error occurred: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email and password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _currentUser = _auth.currentUser;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'An unexpected error occurred: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Sign out error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<String?> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in';

      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update user document in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await user.reload();
      _currentUser = _auth.currentUser;
      notifyListeners();

      return null; // Success
    } catch (e) {
      if (kDebugMode) print('Update profile error: $e');
      return 'Failed to update profile: ${e.toString()}';
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(User user, String displayName) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print('Error creating user document: $e');
    }
  }

  /// Update user's last seen timestamp
  Future<void> updateLastSeen() async {
    if (_currentUser == null) return;

    try {
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print('Error updating last seen: $e');
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      if (kDebugMode) print('Error getting user data: $e');
      return null;
    }
  }

  /// Reset password
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

  /// Convert Firebase Auth errors to user-friendly messages
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
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

/// Simple user model for the app
class TongUser {
  final String id;
  final String email;
  final String displayName;

  TongUser({required this.id, required this.email, required this.displayName});

  Map<String, dynamic> toMap() {
    return {'id': id, 'email': email, 'displayName': displayName};
  }

  factory TongUser.fromMap(Map<String, dynamic> map) {
    return TongUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'User',
    );
  }
}
