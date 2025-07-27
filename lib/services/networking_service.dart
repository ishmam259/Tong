import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'bluetooth_service.dart';

class NetworkingService extends ChangeNotifier {
  static final NetworkingService _instance = NetworkingService._internal();
  factory NetworkingService() => _instance;
  NetworkingService._internal();

  bool _isConnected = false;
  String? _connectedDevice;
  final List<Map<String, dynamic>> _connectedPeers = [];
  Function(Map<String, dynamic>)? _onMessageReceived;

  // TCP networking
  ServerSocket? _serverSocket;
  Socket? _clientSocket;
  final List<Socket> _clientConnections = [];

  // Bluetooth networking
  final BluetoothService _bluetoothService = BluetoothService();

  // UDP socket for device discovery
  RawDatagramSocket? _discoverySocket;

  bool get isConnected => _isConnected || _bluetoothService.isConnected;
  String? get connectedDevice => _connectedDevice;
  List<Map<String, dynamic>> get connectedPeers => _connectedPeers;

  // Add getter for Bluetooth service
  BluetoothService get bluetoothService => _bluetoothService;

  void setMessageHandler(Function(Map<String, dynamic>) handler) {
    _onMessageReceived = handler;
    // Also set handler for Bluetooth messages
    _bluetoothService.setMessageHandler(handler);
  }

  /// Initialize all networking services
  Future<bool> initializeNetworking() async {
    try {
      // Initialize Bluetooth service
      await _bluetoothService.initialize();

      // Initialize discovery socket
      await _initializeDiscoverySocket();

      return true;
    } catch (e) {
      print('Error initializing networking: $e');
      return false;
    }
  }

  /// Initialize UDP socket for device discovery
  Future<void> _initializeDiscoverySocket() async {
    try {
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        8081, // Discovery port
      );
      _discoverySocket!.broadcastEnabled = true;

      _discoverySocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _discoverySocket!.receive();
          if (datagram != null) {
            _handleDiscoveryMessage(datagram);
          }
        }
      });

      print('Discovery socket initialized on port 8081');
    } catch (e) {
      print('Error initializing discovery socket: $e');
    }
  }

  Future<bool> startServer({int port = 8080}) async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      print(
        'Server started on ${_serverSocket!.address.address}:${_serverSocket!.port}',
      );

      _serverSocket!.listen((Socket client) {
        _clientConnections.add(client);
        _isConnected = true;
        _connectedDevice =
            '${client.remoteAddress.address}:${client.remotePort}';

        // Add to connected peers
        _connectedPeers.add({
          'address': client.remoteAddress.address,
          'port': client.remotePort,
          'type': 'TCP',
          'name': 'Device ${client.remoteAddress.address}',
        });

        notifyListeners();

        print(
          'Client connected: ${client.remoteAddress.address}:${client.remotePort}',
        );

        client.listen(
          (data) {
            final message = utf8.decode(data);
            print('Received: $message');

            try {
              final messageData = jsonDecode(message);

              // Handle discovery ping
              if (messageData['type'] == 'discovery_ping') {
                final response = jsonEncode({
                  'type': 'discovery_pong',
                  'device_name': 'Tong Messenger Device',
                  'timestamp': DateTime.now().toIso8601String(),
                });
                client.add(utf8.encode(response));
                return;
              }

              // Handle regular messages
              _onMessageReceived?.call(messageData);
            } catch (e) {
              print('Error decoding message: $e');
            }
          },
          onDone: () {
            _clientConnections.remove(client);
            _connectedPeers.removeWhere(
              (peer) =>
                  peer['address'] == client.remoteAddress.address &&
                  peer['port'] == client.remotePort,
            );

            if (_clientConnections.isEmpty) {
              _isConnected = false;
              _connectedDevice = null;
            }
            notifyListeners();
            print(
              'Client disconnected: ${client.remoteAddress.address}:${client.remotePort}',
            );
          },
          onError: (error) {
            print('Client error: $error');
          },
        );
      });

      return true;
    } catch (e) {
      print('Error starting server: $e');
      return false;
    }
  }

  /// Connect to a discovered device by ID (not IP address)
  Future<bool> connectToDiscoveredDevice(Map<String, dynamic> device) async {
    try {
      // Handle Bluetooth devices (Reactive BLE)
      if (device['type'] == 'Bluetooth') {
        final deviceId = device['address'] as String?;
        if (deviceId != null) {
          final bleSvc = BluetoothService.instance;
          bleSvc.setMessageHandler(_onMessageReceived!);
          bleSvc.scanAndConnect();
          // Give some time to connect
          await Future.delayed(Duration(seconds: 5));
          return bleSvc.isConnected;
        }
        return false;
      }
      // Handle WiFi devices (and other TCP-based connections)
      final address =
          device['_internal_address'] as String? ??
          device['address'] as String?;
      final port =
          device['_internal_port'] as int? ?? device['port'] as int? ?? 8080;
      if (address != null) {
        return await connectToDevice(address, port: port);
      }

      return false;
    } catch (e) {
      print('Error connecting to discovered device: $e');
      return false;
    }
  }

  Future<bool> connectToDevice(String address, {int port = 8080}) async {
    try {
      _clientSocket = await Socket.connect(address, port);
      _isConnected = true;
      _connectedDevice = '$address:$port';

      // Add to connected peers
      _connectedPeers.add({
        'address': address,
        'port': port,
        'type': 'TCP',
        'name': 'Device $address',
      });

      notifyListeners();

      print('Connected to server: $address:$port');

      _clientSocket!.listen(
        (data) {
          final message = utf8.decode(data);
          print('Received: $message');

          try {
            final messageData = jsonDecode(message);
            _onMessageReceived?.call(messageData);
          } catch (e) {
            print('Error decoding message: $e');
          }
        },
        onDone: () {
          _isConnected = false;
          _connectedDevice = null;
          _connectedPeers.clear();
          notifyListeners();
          print('Disconnected from server');
        },
        onError: (error) {
          print('Connection error: $error');
        },
      );

      return true;
    } catch (e) {
      print('Error connecting to device: $e');
      return false;
    }
  }

  Future<bool> sendMessage(Map<String, dynamic> message) async {
    if (!isConnected) return false;

    bool tcpSent = false;
    bool bluetoothSent = false;

    try {
      final messageJson = jsonEncode(message);
      final messageBytes = utf8.encode(messageJson);

      // Send via TCP if connected
      if (_isConnected) {
        // Send to all connected clients if we're a server
        for (final client in _clientConnections) {
          client.add(messageBytes);
        }

        // Send to server if we're a client
        if (_clientSocket != null) {
          _clientSocket!.add(messageBytes);
        }
        tcpSent = true;
      }

      // Send via Bluetooth if connected
      if (_bluetoothService.isConnected) {
        bluetoothSent = await _bluetoothService.sendMessage(message);
      }

      if (tcpSent || bluetoothSent) {
        print(
          'Message sent via ${tcpSent ? "TCP" : ""}${tcpSent && bluetoothSent ? " and " : ""}${bluetoothSent ? "Bluetooth" : ""}: $messageJson',
        );
        return true;
      }

      return false;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  void disconnect() {
    // Do nothing if already disposed
    if (_isDisposed) return;
    try {
      // Close client connections
      for (final client in _clientConnections) {
        client.close();
      }
      _clientConnections.clear();

      // Close client socket
      _clientSocket?.close();
      _clientSocket = null;

      // Close server socket
      _serverSocket?.close();
      _serverSocket = null;

      // Disconnect Bluetooth
      _bluetoothService.disconnect();

      _isConnected = false;
      _connectedDevice = null;
      _connectedPeers.clear();
      notifyListeners();

      print('Disconnected from all devices');
    } catch (e) {
      print('Error during disconnect: $e');
    }
  }

  // Track disposal to allow safe multiple calls
  bool _isDisposed = false;
  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    try {
      disconnect();
    } catch (_) {}
    try {
      _discoverySocket?.close();
    } catch (_) {}
    super.dispose();
  }

  Future<String?> getLocalIPAddress() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback && address.type == InternetAddressType.IPv4) {
            return address.address;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting local IP: $e');
      return null;
    }
  }

  /// Discover devices using both Bluetooth and WiFi without exposing IP addresses
  Future<List<Map<String, dynamic>>> discoverDevices({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final discoveredDevices = <Map<String, dynamic>>[];

    print('Starting unified device discovery...');

    // Start both Bluetooth and WiFi discovery simultaneously
    final bluetoothFuture = _discoverBluetoothDevices();
    final wifiServicesFuture = _discoverWiFiServices(timeout: timeout);

    // Wait for both to complete
    try {
      final results = await Future.wait([bluetoothFuture, wifiServicesFuture]);

      // Combine results
      final bluetoothDevices = results[0];
      final wifiDevices = results[1];

      discoveredDevices.addAll(bluetoothDevices);
      discoveredDevices.addAll(wifiDevices);

      // Sort by connection strength/quality
      discoveredDevices.sort((a, b) {
        final aStrength = _getConnectionStrength(a);
        final bStrength = _getConnectionStrength(b);
        return bStrength.compareTo(aStrength);
      });

      print(
        'Device discovery completed. Found ${discoveredDevices.length} devices'
        ' (${bluetoothDevices.length} Bluetooth, ${wifiDevices.length} WiFi)',
      );
      return discoveredDevices;
    } catch (e) {
      print('Error during device discovery: $e');
      return discoveredDevices;
    }
  }

  /// Discover devices via Bluetooth
  Future<List<Map<String, dynamic>>> _discoverBluetoothDevices() async {
    final devices = <Map<String, dynamic>>[];

    try {
      if (_bluetoothService.isInitialized) {
        await _bluetoothService.startScanning();

        // Wait for scan results
        await Future.delayed(Duration(seconds: 3));

        for (final device in _bluetoothService.discoveredDevices) {
          devices.add({
            'id': device.platformName,
            'name':
                device.platformName.isNotEmpty
                    ? device.platformName
                    : 'Tong Device (Bluetooth)',
            'type': 'Bluetooth',
            'device': device,
            'signal': 'Good', // Bluetooth signal quality
            'available': true,
            'last_seen': DateTime.now(),
            'connection_method': 'bluetooth',
          });
        }

        await _bluetoothService.stopScanning();
      }
    } catch (e) {
      print('Error discovering Bluetooth devices: $e');
    }

    return devices;
  }

  /// Discover devices via WiFi service broadcasting (without IP scanning)
  Future<List<Map<String, dynamic>>> _discoverWiFiServices({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final discoveredDevices = <Map<String, dynamic>>[];

    try {
      // Clear previous discoveries
      _connectedPeers.removeWhere((peer) => peer['type'] == 'WiFi_Discovery');

      // Broadcast a discovery request
      await _broadcastDiscoveryRequest();

      // Wait for responses
      await Future.delayed(timeout);

      // Get devices that responded
      final wifiDevices =
          _connectedPeers
              .where((peer) => peer['type'] == 'WiFi_Discovery')
              .toList();

      discoveredDevices.addAll(wifiDevices);

      print(
        'WiFi service discovery completed. Found ${discoveredDevices.length} devices',
      );
      return discoveredDevices;
    } catch (e) {
      print('Error during WiFi service discovery: $e');
      return discoveredDevices;
    }
  }

  /// Broadcast a discovery request on the local network
  Future<void> _broadcastDiscoveryRequest() async {
    try {
      if (_discoverySocket == null) return;

      final discoveryMessage = jsonEncode({
        'type': 'tong_discovery_request',
        'service': 'Tong Messenger',
        'version': '1.0.0',
        'device_name': 'Tong Device',
        'timestamp': DateTime.now().toIso8601String(),
      });

      final data = utf8.encode(discoveryMessage);

      // Broadcast to local network
      final localIP = await getLocalIPAddress();
      if (localIP != null) {
        final ipParts = localIP.split('.');
        if (ipParts.length == 4) {
          final broadcastAddress =
              '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.255';
          _discoverySocket!.send(data, InternetAddress(broadcastAddress), 8081);
        }
      }

      // Also send to global broadcast
      _discoverySocket!.send(data, InternetAddress('255.255.255.255'), 8081);

      print('Discovery request broadcasted');
    } catch (e) {
      print('Error broadcasting discovery request: $e');
    }
  }

  /// Handle discovery message from other devices
  void _handleDiscoveryMessage(Datagram datagram) {
    try {
      final message = utf8.decode(datagram.data);
      final messageData = jsonDecode(message);

      if (messageData['type'] == 'tong_discovery_request') {
        // Respond to discovery request
        _sendDiscoveryResponse(datagram.address, datagram.port);
      } else if (messageData['type'] == 'tong_discovery_response') {
        // Handle discovery response - a device found us
        final deviceId =
            messageData['device_id'] ??
            'unknown_${DateTime.now().millisecondsSinceEpoch}';

        // Check if we already know about this device
        final existingDevice = _connectedPeers.firstWhere(
          (peer) => peer['id'] == deviceId,
          orElse: () => {},
        );

        if (existingDevice.isEmpty) {
          _connectedPeers.add({
            'id': deviceId,
            'name': messageData['device_name'] ?? 'Tong Device (WiFi)',
            'type': 'WiFi_Discovery',
            'signal': 'Good',
            'available': true,
            'last_seen': DateTime.now(),
            'connection_method': 'wifi',
            '_internal_address': datagram.address.address,
            '_internal_port': messageData['tcp_port'] ?? 8080,
          });
          notifyListeners();
          print(
            'Discovered WiFi device: ${messageData['device_name']} at ${datagram.address.address}',
          );
        }
      }
    } catch (e) {
      print('Error handling discovery message: $e');
    }
  }

  /// Send discovery response to a requesting device
  Future<void> _sendDiscoveryResponse(InternetAddress address, int port) async {
    try {
      if (_discoverySocket == null) return;

      final response = jsonEncode({
        'type': 'tong_discovery_response',
        'device_id': 'tong_${DateTime.now().millisecondsSinceEpoch}',
        'device_name': 'Tong Messenger Device',
        'service': 'Tong Messenger',
        'version': '1.0.0',
        'tcp_port': 8080,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final data = utf8.encode(response);
      _discoverySocket!.send(data, address, port);

      print('Discovery response sent to ${address.address}:$port');
    } catch (e) {
      print('Error sending discovery response: $e');
    }
  }

  /// Get connection strength score for sorting
  int _getConnectionStrength(Map<String, dynamic> device) {
    // Prioritize Bluetooth over WiFi for better reliability
    if (device['type'] == 'Bluetooth') return 100;
    if (device['type'] == 'WiFi_Discovery') return 80;
    return 50; // TCP fallback
  }

  // Legacy methods for backward compatibility with settings screen

  /// Get available WiFi networks (placeholder - requires platform-specific implementation)
  Future<List<Map<String, dynamic>>> getAvailableWiFiNetworks() async {
    // This would require platform-specific WiFi scanning
    // For now, return empty list with a note
    return [
      {
        'name': 'WiFi scanning not available',
        'type': 'Info',
        'signal': 'Use device WiFi settings to connect to networks',
        'available': false,
      },
    ];
  }

  /// Get available Bluetooth devices
  Future<List<Map<String, dynamic>>> getAvailableBluetoothDevices() async {
    try {
      if (!_bluetoothService.isInitialized) {
        await _bluetoothService.initialize();
      }

      await _bluetoothService.startScanning();
      await Future.delayed(Duration(seconds: 3));

      final devices = <Map<String, dynamic>>[];
      for (final device in _bluetoothService.discoveredDevices) {
        devices.add({
          'name':
              device.platformName.isNotEmpty
                  ? device.platformName
                  : 'Unknown Device',
          'type': 'Bluetooth',
          'signal': 'Good',
          'available': true,
          'device': device,
          'address': device.remoteId.toString(),
        });
      }

      await _bluetoothService.stopScanning();
      return devices;
    } catch (e) {
      print('Error getting Bluetooth devices: $e');
      return [];
    }
  }

  /// Legacy method - use discoverDevices() instead
  Future<List<Map<String, dynamic>>> discoverNetworkDevices() async {
    final devices = await discoverDevices();
    // Filter to only show WiFi devices for backward compatibility
    return devices.where((device) => device['type'] != 'Bluetooth').toList();
  }

  /// Connect to a Bluetooth device
  Future<bool> connectToBluetoothDevice(Map<String, dynamic> device) async {
    try {
      final bluetoothDevice = device['device'];
      if (bluetoothDevice != null) {
        return await _bluetoothService.connectToDevice(bluetoothDevice);
      }
      return false;
    } catch (e) {
      print('Error connecting to Bluetooth device: $e');
      return false;
    }
  }
}

class NetworkMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  // Message type (e.g., 'text')
  final String type;

  NetworkMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.type = 'text',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
    };
  }

  factory NetworkMessage.fromJson(Map<String, dynamic> json) {
    return NetworkMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      type: json['type'] ?? 'text',
    );
  }
}
