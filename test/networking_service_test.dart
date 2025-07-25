import 'package:flutter_test/flutter_test.dart';
import 'package:tong/services/networking_service.dart';

void main() {
  group('NetworkingService Tests', () {
    late NetworkingService networkingService;

    setUp(() {
      networkingService = NetworkingService();
    });

    tearDown(() {
      networkingService.dispose();
    });

    test('NetworkingService initializes correctly', () {
      expect(networkingService.isConnected, false);
      expect(networkingService.connectedDevice, null);
      expect(networkingService.connectedPeers, isEmpty);
    });

    test('Can start server', () async {
      final result = await networkingService.startServer(port: 9999);
      expect(result, true);

      // Clean up
      networkingService.disconnect();
    });

    test('Can get local IP address', () async {
      final ip = await networkingService.getLocalIPAddress();
      // IP might be null in test environment, so just check it doesn't crash
      expect(ip, isA<String?>());
    });

    test('NetworkMessage serialization works', () {
      final message = NetworkMessage(
        id: 'test123',
        senderId: 'user1',
        senderName: 'Test User',
        content: 'Hello World',
        timestamp: DateTime.now(),
      );

      final json = message.toJson();
      expect(json['id'], 'test123');
      expect(json['senderId'], 'user1');
      expect(json['senderName'], 'Test User');
      expect(json['content'], 'Hello World');
      expect(json['type'], 'text');

      final recreated = NetworkMessage.fromJson(json);
      expect(recreated.id, message.id);
      expect(recreated.senderId, message.senderId);
      expect(recreated.senderName, message.senderName);
      expect(recreated.content, message.content);
      expect(recreated.type, message.type);
    });

    test('Message handler can be set', () {
      bool handlerCalled = false;

      networkingService.setMessageHandler((message) {
        handlerCalled = true;
      });

      // Handler should be set without errors
      expect(handlerCalled, false); // Not called yet
    });

    test('Disconnect works without connection', () {
      // Should not throw error when disconnecting without connection
      expect(() => networkingService.disconnect(), returnsNormally);
    });
  });
}
