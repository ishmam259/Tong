// Stub implementation of Socket Service
// To use actual Socket.IO functionality, add socket_io_client to pubspec.yaml

class SocketService {
  bool _isInitialized = false;
  bool _isConnected = false;

  // ignore: unused_field
  String? _serverUrl;
  // ignore: unused_field
  Function(Map<String, dynamic>)? _messageHandler;

  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    print("Socket Service: Stub implementation - Socket.IO not available");
    print(
      "To enable Socket.IO: Add 'socket_io_client: ^2.0.3' to pubspec.yaml",
    );
    _isInitialized = true;
  }

  Future<bool> connect(
    String serverUrl, {
    Map<String, dynamic>? options,
  }) async {
    try {
      print("Socket Service: Connect attempt to $serverUrl (stub) - will fail");
      _serverUrl = serverUrl;
      return false; // Stub always fails to connect
    } catch (e) {
      print('Error connecting to socket server: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      print("Socket Service: Disconnect (stub)");
      _isConnected = false;
    } catch (e) {
      print('Error disconnecting from socket server: $e');
    }
  }

  Future<bool> sendMessage(Map<String, dynamic> message) async {
    try {
      print("Socket Service: Send message (stub) - message not sent: $message");
      return false; // Stub always fails to send
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  void setMessageHandler(Function(Map<String, dynamic>) handler) {
    _messageHandler = handler;
    print("Socket Service: Message handler set (stub)");
  }

  void joinRoom(String roomId) {
    print("Socket Service: Join room $roomId (stub) - no action taken");
  }

  void leaveRoom(String roomId) {
    print("Socket Service: Leave room $roomId (stub) - no action taken");
  }

  void dispose() {
    print("Socket Service: Disposing (stub)");
    disconnect();
    _isInitialized = false;
  }
}
