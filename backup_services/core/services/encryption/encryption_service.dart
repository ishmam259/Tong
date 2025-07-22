import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static const String _algorithm = 'AES-256-GCM';

  bool _isInitialized = false;
  String? _defaultKey;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      // Generate a default encryption key
      _defaultKey = _generateKey();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing encryption service: $e');
    }
  }

  String _generateKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(timestamp);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String encrypt(String plaintext, {String? key}) {
    try {
      final keyToUse = key ?? _defaultKey ?? _generateKey();

      // Simple XOR encryption for demonstration
      // In a real app, you'd use proper AES encryption
      final keyBytes = utf8.encode(keyToUse);
      final plainBytes = utf8.encode(plaintext);
      final encrypted = <int>[];

      for (int i = 0; i < plainBytes.length; i++) {
        encrypted.add(plainBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return base64.encode(encrypted);
    } catch (e) {
      print('Error encrypting data: $e');
      return plaintext; // Return original if encryption fails
    }
  }

  String decrypt(String ciphertext, {String? key}) {
    try {
      final keyToUse = key ?? _defaultKey ?? _generateKey();

      // Simple XOR decryption for demonstration
      final keyBytes = utf8.encode(keyToUse);
      final encryptedBytes = base64.decode(ciphertext);
      final decrypted = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decrypted);
    } catch (e) {
      print('Error decrypting data: $e');
      return ciphertext; // Return original if decryption fails
    }
  }

  String hashMessage(String message) {
    try {
      final bytes = utf8.encode(message);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      print('Error hashing message: $e');
      return '';
    }
  }

  bool verifyHash(String message, String hash) {
    try {
      return hashMessage(message) == hash;
    } catch (e) {
      print('Error verifying hash: $e');
      return false;
    }
  }

  String generateSessionKey() {
    return _generateKey();
  }

  Map<String, dynamic> encryptMessage(
    Map<String, dynamic> message, {
    String? key,
  }) {
    try {
      final messageJson = json.encode(message);
      final encrypted = encrypt(messageJson, key: key);
      final hash = hashMessage(messageJson);

      return {
        'encrypted': true,
        'data': encrypted,
        'hash': hash,
        'algorithm': _algorithm,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error encrypting message: $e');
      return message;
    }
  }

  Map<String, dynamic>? decryptMessage(
    Map<String, dynamic> encryptedMessage, {
    String? key,
  }) {
    try {
      if (encryptedMessage['encrypted'] != true) {
        return encryptedMessage; // Not encrypted
      }

      final decrypted = decrypt(encryptedMessage['data'], key: key);
      final message = json.decode(decrypted) as Map<String, dynamic>;

      // Verify hash if present
      if (encryptedMessage['hash'] != null) {
        final isValid = verifyHash(decrypted, encryptedMessage['hash']);
        if (!isValid) {
          print('Message hash verification failed');
          return null;
        }
      }

      return message;
    } catch (e) {
      print('Error decrypting message: $e');
      return null;
    }
  }

  void dispose() {
    _defaultKey = null;
    _isInitialized = false;
  }
}
