import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? _socket;
  bool _isInitialized = false;
  bool _isConnected = false;

  String? _serverUrl;
  Function(Map<String, dynamic>)? _messageHandler;

  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    _isInitialized = true;
  }

  Future<bool> connect(
    String serverUrl, {
    Map<String, dynamic>? options,
  }) async {
    try {
      _serverUrl = serverUrl;

      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders(options ?? {})
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        print('Connected to server: $serverUrl');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        print('Disconnected from server');
      });

      _socket!.on('message', (data) {
        if (_messageHandler != null) {
          _messageHandler!(data);
        }
      });

      _socket!.on('chat_message', (data) {
        if (_messageHandler != null) {
          _messageHandler!(data);
        }
      });

      _socket!.connect();

      // Wait a bit for connection to establish
      await Future.delayed(const Duration(seconds: 2));

      return _isConnected;
    } catch (e) {
      print('Error connecting to socket server: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
    } catch (e) {
      print('Error disconnecting from socket server: $e');
    }
  }

  Future<bool> sendMessage(Map<String, dynamic> message) async {
    try {
      if (_socket != null && _isConnected) {
        _socket!.emit('chat_message', message);
        return true;
      }
      return false;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  void setMessageHandler(Function(Map<String, dynamic>) handler) {
    _messageHandler = handler;
  }

  void joinRoom(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join_room', {'room': roomId});
    }
  }

  void leaveRoom(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave_room', {'room': roomId});
    }
  }

  void dispose() {
    disconnect();
    _isInitialized = false;
  }
}
