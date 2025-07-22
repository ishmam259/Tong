import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_space.dart';
import '../models/message.dart';
import '../services/service_locator.dart';
import '../services/storage/local_storage_service.dart';
import '../services/encryption/encryption_service.dart';
import 'networking_provider.dart';
import 'identity_provider.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatSpace> _chatSpaces = [];
  final Map<String, List<Message>> _messages = {};
  ChatSpace? _currentChatSpace;
  bool _isInitialized = false;
  Timer? _cleanupTimer;

  List<ChatSpace> get chatSpaces => _chatSpaces;
  ChatSpace? get currentChatSpace => _currentChatSpace;
  bool get isInitialized => _isInitialized;

  List<Message> getCurrentMessages() {
    if (_currentChatSpace == null) return [];
    return _messages[_currentChatSpace!.id] ?? [];
  }

  List<Message> getMessagesForChatSpace(String chatSpaceId) {
    return _messages[chatSpaceId] ?? [];
  }

  Future<void> initialize() async {
    try {
      await _loadChatSpaces();
      await _loadMessages();
      _startCleanupTimer();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing chat provider: $e');
    }
  }

  Future<void> _loadChatSpaces() async {
    try {
      _chatSpaces = await getIt<LocalStorageService>().getChatSpaces();
    } catch (e) {
      debugPrint('Error loading chat spaces: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      for (final chatSpace in _chatSpaces) {
        final messages = await getIt<LocalStorageService>().getMessages(
          chatSpaceId: chatSpace.id,
        );
        _messages[chatSpace.id] = messages;
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Future<ChatSpace> createTemporaryGroup({
    required String name,
    String? description,
    Duration? timeout,
    bool isEncrypted = false,
  }) async {
    try {
      final identity = getIt<IdentityProvider>().currentIdentity;
      if (identity == null) throw Exception('No current identity');

      final chatSpace = ChatSpace.temporary(
        name: name,
        createdBy: identity.id,
        timeout: timeout,
        description: description,
        isEncrypted: isEncrypted,
      );

      await _saveChatSpace(chatSpace);
      _chatSpaces.add(chatSpace);
      _messages[chatSpace.id] = [];

      // Add system message
      final systemMessage = Message.system(
        content:
            'Temporary group "$name" created. ${timeout != null ? "Auto-delete in ${timeout.inHours} hours." : ""}',
        chatSpaceId: chatSpace.id,
      );
      await _addMessage(systemMessage);

      notifyListeners();
      return chatSpace;
    } catch (e) {
      debugPrint('Error creating temporary group: $e');
      rethrow;
    }
  }

  Future<ChatSpace> createPermanentForum({
    required String name,
    String? description,
    bool isPublic = false,
    bool isEncrypted = false,
    String? password,
  }) async {
    try {
      final identity = getIt<IdentityProvider>().currentIdentity;
      if (identity == null) throw Exception('No current identity');

      final chatSpace = ChatSpace.permanent(
        name: name,
        createdBy: identity.id,
        description: description,
        isPublic: isPublic,
        isEncrypted: isEncrypted,
        password: password,
      );

      await _saveChatSpace(chatSpace);
      _chatSpaces.add(chatSpace);
      _messages[chatSpace.id] = [];

      // Add system message
      final systemMessage = Message.system(
        content: 'Forum "$name" created.',
        chatSpaceId: chatSpace.id,
      );
      await _addMessage(systemMessage);

      notifyListeners();
      return chatSpace;
    } catch (e) {
      debugPrint('Error creating permanent forum: $e');
      rethrow;
    }
  }

  Future<ChatSpace> createNoticeBoard({
    required String name,
    String? description,
    bool isPublic = true,
  }) async {
    try {
      final identity = getIt<IdentityProvider>().currentIdentity;
      if (identity == null) throw Exception('No current identity');

      final chatSpace = ChatSpace.noticeBoard(
        name: name,
        createdBy: identity.id,
        description: description,
        isPublic: isPublic,
      );

      await _saveChatSpace(chatSpace);
      _chatSpaces.add(chatSpace);
      _messages[chatSpace.id] = [];

      // Add system message
      final systemMessage = Message.system(
        content:
            'Notice board "$name" created. Announcement mode - no replies allowed.',
        chatSpaceId: chatSpace.id,
      );
      await _addMessage(systemMessage);

      notifyListeners();
      return chatSpace;
    } catch (e) {
      debugPrint('Error creating notice board: $e');
      rethrow;
    }
  }

  Future<void> joinChatSpace(String chatSpaceId, {String? password}) async {
    try {
      final identity = getIt<IdentityProvider>().currentIdentity;
      if (identity == null) throw Exception('No current identity');

      final chatSpace = _chatSpaces.firstWhere((cs) => cs.id == chatSpaceId);

      // Check password if required
      if (chatSpace.password != null && chatSpace.password != password) {
        throw Exception('Invalid password');
      }

      // Check if already a participant
      if (chatSpace.participants.contains(identity.id)) {
        setCurrentChatSpace(chatSpace);
        return;
      }

      // Add user to chat space
      chatSpace.addParticipant(identity.id);
      await _saveChatSpace(chatSpace);

      // Add system message
      final systemMessage = Message.system(
        content: '${identity.nickname} joined the chat.',
        chatSpaceId: chatSpace.id,
      );
      await _addMessage(systemMessage);

      setCurrentChatSpace(chatSpace);
      notifyListeners();
    } catch (e) {
      debugPrint('Error joining chat space: $e');
      rethrow;
    }
  }

  Future<void> leaveChatSpace(String chatSpaceId) async {
    try {
      final identity = getIt<IdentityProvider>().currentIdentity;
      if (identity == null) throw Exception('No current identity');

      final chatSpace = _chatSpaces.firstWhere((cs) => cs.id == chatSpaceId);

      // Remove user from chat space
      chatSpace.removeParticipant(identity.id);
      await _saveChatSpace(chatSpace);

      // Add system message
      final systemMessage = Message.system(
        content: '${identity.nickname} left the chat.',
        chatSpaceId: chatSpace.id,
      );
      await _addMessage(systemMessage);

      if (_currentChatSpace?.id == chatSpaceId) {
        _currentChatSpace = null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error leaving chat space: $e');
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String content,
    String? replyToId,
    MessageType type = MessageType.text,
  }) async {
    try {
      if (_currentChatSpace == null) throw Exception('No current chat space');

      final identity = getIt<IdentityProvider>().currentIdentity;
      if (identity == null) throw Exception('No current identity');

      // Check permissions
      if (!_currentChatSpace!.hasPermission(
        identity.id,
        PermissionType.write,
      )) {
        throw Exception('No write permission');
      }

      // Check if replies are allowed (for notice boards)
      if (!_currentChatSpace!.allowReplies && replyToId != null) {
        throw Exception('Replies not allowed in this space');
      }

      final message = Message.text(
        senderId: identity.id,
        senderNickname: identity.nickname,
        content: content,
        chatSpaceId: _currentChatSpace!.id,
        replyToId: replyToId,
      );

      // Encrypt if required
      if (_currentChatSpace!.isEncrypted) {
        message.isEncrypted = true;
        message.content = getIt<EncryptionService>().encrypt(content);
      }

      await _addMessage(message);

      // Send over network if connected
      final networkingProvider = getIt<NetworkingProvider>();
      if (networkingProvider.hasActiveConnection) {
        await networkingProvider.sendMessage(message);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> _addMessage(Message message) async {
    try {
      await getIt<LocalStorageService>().saveMessage(message);

      if (_messages[message.chatSpaceId] == null) {
        _messages[message.chatSpaceId] = [];
      }

      _messages[message.chatSpaceId]!.add(message);
      _messages[message.chatSpaceId]!.sort(
        (a, b) => a.timestamp.compareTo(b.timestamp),
      );
    } catch (e) {
      debugPrint('Error adding message: $e');
    }
  }

  Future<void> _saveChatSpace(ChatSpace chatSpace) async {
    try {
      await getIt<LocalStorageService>().saveChatSpace(chatSpace);
    } catch (e) {
      debugPrint('Error saving chat space: $e');
    }
  }

  void setCurrentChatSpace(ChatSpace? chatSpace) {
    _currentChatSpace = chatSpace;
    notifyListeners();
  }

  Future<void> addReaction(String messageId, String reaction) async {
    try {
      if (_currentChatSpace == null) return;

      final identity = getIt<IdentityProvider>().currentIdentity;
      if (identity == null) return;

      // Check permissions
      if (!_currentChatSpace!.hasPermission(
        identity.id,
        PermissionType.react,
      )) {
        throw Exception('No react permission');
      }

      final messages = _messages[_currentChatSpace!.id] ?? [];
      final messageIndex = messages.indexWhere((m) => m.id == messageId);

      if (messageIndex >= 0) {
        messages[messageIndex].addReaction(reaction);
        await getIt<LocalStorageService>().saveMessage(messages[messageIndex]);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding reaction: $e');
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _cleanupExpiredChatSpaces();
    });
  }

  Future<void> _cleanupExpiredChatSpaces() async {
    try {
      final expiredSpaces = _chatSpaces.where((cs) => cs.isExpired()).toList();

      for (final chatSpace in expiredSpaces) {
        await getIt<LocalStorageService>().deleteChatSpace(chatSpace.id);
        _chatSpaces.removeWhere((cs) => cs.id == chatSpace.id);
        _messages.remove(chatSpace.id);

        if (_currentChatSpace?.id == chatSpace.id) {
          _currentChatSpace = null;
        }
      }

      if (expiredSpaces.isNotEmpty) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error cleaning up expired chat spaces: $e');
    }
  }

  void reset() {
    _chatSpaces.clear();
    _messages.clear();
    _currentChatSpace = null;
    _isInitialized = false;
    _cleanupTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }
}
