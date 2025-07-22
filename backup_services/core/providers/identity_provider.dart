import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_identity.dart';
import '../services/service_locator.dart';
import '../services/storage/local_storage_service.dart';

class IdentityProvider extends ChangeNotifier {
  static const String _currentIdentityKey = 'current_identity';

  UserIdentity? _currentIdentity;
  List<UserIdentity> _savedIdentities = [];
  bool _isInitialized = false;

  UserIdentity? get currentIdentity => _currentIdentity;
  List<UserIdentity> get savedIdentities => _savedIdentities;
  bool get isInitialized => _isInitialized;
  bool get hasIdentity => _currentIdentity != null;

  Future<void> initialize() async {
    try {
      await _loadCurrentIdentity();
      await _loadSavedIdentities();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing identity provider: $e');
    }
  }

  Future<void> _loadCurrentIdentity() async {
    try {
      final prefs = getIt<SharedPreferences>();
      final identityJson = prefs.getString(_currentIdentityKey);

      if (identityJson != null) {
        final identityMap = Map<String, dynamic>.from(
          await getIt<LocalStorageService>().decodeJson(identityJson),
        );
        _currentIdentity = UserIdentity.fromJson(identityMap);
      }
    } catch (e) {
      debugPrint('Error loading current identity: $e');
    }
  }

  Future<void> _loadSavedIdentities() async {
    try {
      _savedIdentities = await getIt<LocalStorageService>().getIdentities();
    } catch (e) {
      debugPrint('Error loading saved identities: $e');
    }
  }

  Future<void> createAnonymousIdentity({String? customNickname}) async {
    try {
      final identity = UserIdentity.anonymous(customNickname: customNickname);
      await _setCurrentIdentity(identity);

      if (!identity.isSystemGenerated) {
        await _saveIdentity(identity);
      }
    } catch (e) {
      debugPrint('Error creating anonymous identity: $e');
    }
  }

  Future<void> createRegisteredIdentity({
    required String nickname,
    String? avatar,
    bool isPermanent = true,
  }) async {
    try {
      final identity = UserIdentity.registered(
        nickname: nickname,
        avatar: avatar,
        isPermanent: isPermanent,
      );

      await _setCurrentIdentity(identity);
      await _saveIdentity(identity);
    } catch (e) {
      debugPrint('Error creating registered identity: $e');
    }
  }

  Future<void> switchToIdentity(UserIdentity identity) async {
    try {
      await _setCurrentIdentity(identity);
    } catch (e) {
      debugPrint('Error switching identity: $e');
    }
  }

  Future<void> _setCurrentIdentity(UserIdentity identity) async {
    try {
      final prefs = getIt<SharedPreferences>();
      final identityJson = await getIt<LocalStorageService>().encodeJson(
        identity.toJson(),
      );
      await prefs.setString(_currentIdentityKey, identityJson);

      _currentIdentity = identity;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting current identity: $e');
    }
  }

  Future<void> _saveIdentity(UserIdentity identity) async {
    try {
      await getIt<LocalStorageService>().saveIdentity(identity);
      await _loadSavedIdentities();
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving identity: $e');
    }
  }

  Future<void> regenerateSession() async {
    if (_currentIdentity != null) {
      try {
        _currentIdentity!.regenerateSession();
        await _setCurrentIdentity(_currentIdentity!);

        if (_savedIdentities.any((id) => id.id == _currentIdentity!.id)) {
          await _saveIdentity(_currentIdentity!);
        }
      } catch (e) {
        debugPrint('Error regenerating session: $e');
      }
    }
  }

  Future<void> updateNickname(String newNickname) async {
    if (_currentIdentity != null) {
      try {
        _currentIdentity!.nickname = newNickname;
        await _setCurrentIdentity(_currentIdentity!);

        if (_savedIdentities.any((id) => id.id == _currentIdentity!.id)) {
          await _saveIdentity(_currentIdentity!);
        }
      } catch (e) {
        debugPrint('Error updating nickname: $e');
      }
    }
  }

  Future<void> deleteIdentity(String identityId) async {
    try {
      await getIt<LocalStorageService>().deleteIdentity(identityId);
      _savedIdentities.removeWhere((id) => id.id == identityId);

      if (_currentIdentity?.id == identityId) {
        _currentIdentity = null;
        final prefs = getIt<SharedPreferences>();
        await prefs.remove(_currentIdentityKey);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting identity: $e');
    }
  }

  void logout() {
    _currentIdentity = null;
    notifyListeners();
  }

  void reset() {
    _currentIdentity = null;
    _savedIdentities.clear();
    _isInitialized = false;
    notifyListeners();
  }
}
