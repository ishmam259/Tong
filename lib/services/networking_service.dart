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
      return true;
    } catch (e) {
      print('Error initializing networking: $e');
      return false;
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

  /// Discover devices on the local network by scanning IP addresses
  Future<List<Map<String, dynamic>>> discoverNetworkDevices({
    int port = 8080,
    Duration timeout = const Duration(seconds: 1),
  }) async {
    final discoveredDevices = <Map<String, dynamic>>[];

    try {
      final localIP = await getLocalIPAddress();
      if (localIP == null) {
        print('Could not get local IP address');
        return discoveredDevices;
      }

      // Extract network subnet (assuming /24 subnet)
      final ipParts = localIP.split('.');
      if (ipParts.length != 4) return discoveredDevices;

      final networkBase = '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}';
      print('Scanning network: $networkBase.0/24 on port $port');

      // Scan a smaller range first for testing (can expand later)
      final futures = <Future<void>>[];

      // Scan common IP ranges first
      final commonIPs = [
        for (int i = 1; i <= 20; i++) '$networkBase.$i', // First 20
        for (int i = 100; i <= 120; i++) '$networkBase.$i', // Common DHCP range
        for (int i = 200; i <= 220; i++)
          '$networkBase.$i', // Another common range
      ];

      for (final targetIP in commonIPs) {
        // Skip our own IP
        if (targetIP == localIP) continue;

        futures.add(
          _scanSingleDevice(targetIP, port, timeout)
              .then((result) {
                if (result != null) {
                  print('Found Tong device at $targetIP');
                  discoveredDevices.add(result);
                }
              })
              .catchError((e) {
                // Silently ignore connection errors (expected for most IPs)
              }),
        );
      }

      // Wait for all scans to complete
      await Future.wait(futures);

      // Sort by IP address
      discoveredDevices.sort((a, b) => a['address'].compareTo(b['address']));

      print(
        'Network scan completed. Found ${discoveredDevices.length} devices',
      );
      return discoveredDevices;
    } catch (e) {
      print('Error during network discovery: $e');
      return discoveredDevices;
    }
  }

  /// Scan a single IP address to see if it's running our service
  Future<Map<String, dynamic>?> _scanSingleDevice(
    String address,
    int port,
    Duration timeout,
  ) async {
    try {
      // Try to connect
      final socket = await Socket.connect(address, port).timeout(timeout);

      // Send a discovery ping
      final discoveryMessage = jsonEncode({
        'type': 'discovery_ping',
        'sender': await getLocalIPAddress(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      socket.add(utf8.encode(discoveryMessage));

      // Wait for response
      final completer = Completer<String>();
      late StreamSubscription subscription;

      subscription = socket.listen(
        (data) {
          final responseData = utf8.decode(data);
          completer.complete(responseData);
          subscription.cancel();
        },
        onError: (error) {
          if (!completer.isCompleted) completer.completeError(error);
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.completeError('Connection closed');
          }
        },
      );

      final responseData = await completer.future.timeout(timeout);
      await socket.close();

      try {
        final responseJson = jsonDecode(responseData);
        if (responseJson['type'] == 'discovery_pong') {
          return {
            'address': address,
            'port': port,
            'type': 'TCP',
            'name': responseJson['device_name'] ?? 'Tong Device at $address',
            'signal': 'Good',
            'available': true,
            'last_seen': DateTime.now(),
          };
        }
      } catch (e) {
        // Response wasn't valid JSON or expected format
        print('Invalid response from $address: $responseData');
      }

      return null;
    } catch (e) {
      // Connection failed - device not available or not running our service
      // This is expected for most IPs, so we don't log it
      return null;
    }
  }

  /// Get available Bluetooth devices
  Future<List<Map<String, dynamic>>> getAvailableBluetoothDevices() async {
    try {
      print("NetworkingService: Getting Bluetooth devices...");

      // Check Bluetooth status first
      final status = await _bluetoothService.getBluetoothStatus();
      print("Bluetooth status: $status");

      if (!_bluetoothService.isInitialized) {
        print("Bluetooth not initialized, attempting to initialize...");
        final initialized = await _bluetoothService.initialize();
        if (!initialized) {
          print("Failed to initialize Bluetooth");
          return [
            {
              'name': 'Bluetooth unavailable',
              'type': 'Error',
              'signal': 'Status: $status',
              'available': false,
              'category': 'Bluetooth Error',
              'info': true,
            },
          ];
        }
      }

      if (_bluetoothService.isInitialized) {
        print("Starting Bluetooth scan...");
        await _bluetoothService.startScanning();
        // Wait a bit for scan results
        await Future.delayed(Duration(seconds: 8));
        final devices = _bluetoothService.getDiscoveredDevicesAsMap();
        print("Found ${devices.length} Bluetooth devices");

        if (devices.isEmpty) {
          return [
            {
              'name': 'No Bluetooth devices found',
              'type': 'Info',
              'signal':
                  'Make sure other devices have Bluetooth enabled and discoverable',
              'available': false,
              'category': 'Bluetooth Scan Result',
              'info': true,
            },
          ];
        }

        return devices;
      }

      return [
        {
          'name': 'Bluetooth initialization failed',
          'type': 'Error',
          'signal': 'Status: $status',
          'available': false,
          'category': 'Bluetooth Error',
          'info': true,
        },
      ];
    } catch (e) {
      print('Error getting Bluetooth devices: $e');
      return [
        {
          'name': 'Bluetooth error',
          'type': 'Error',
          'signal': 'Error: $e',
          'available': false,
          'category': 'Bluetooth Error',
          'info': true,
        },
      ];
    }
  }

  /// Connect to a Bluetooth device
  Future<bool> connectToBluetoothDevice(Map<String, dynamic> deviceInfo) async {
    try {
      final device = deviceInfo['device'];
      if (device != null) {
        final success = await _bluetoothService.connectToDevice(device);
        if (success) {
          _connectedPeers.add(deviceInfo);
          notifyListeners();
        }
        return success;
      }
      return false;
    } catch (e) {
      print('Error connecting to Bluetooth device: $e');
      return false;
    }
  }

  /// Get available WiFi networks (simplified version)
  Future<List<Map<String, dynamic>>> getAvailableWiFiNetworks() async {
    // Note: Real WiFi scanning requires platform-specific implementations
    // This is a simplified version that just returns network interface info
    final networks = <Map<String, dynamic>>[];

    try {
      final interfaces = await NetworkInterface.list();

      for (final interface in interfaces) {
        if (interface.name.toLowerCase().contains('wi-fi') ||
            interface.name.toLowerCase().contains('wlan') ||
            interface.name.toLowerCase().contains('wireless')) {
          for (final address in interface.addresses) {
            if (!address.isLoopback &&
                address.type == InternetAddressType.IPv4) {
              networks.add({
                'name': interface.name,
                'type': 'WiFi',
                'address': address.address,
                'signal': 'Connected',
                'available': true,
                'interface': interface.name,
              });
            }
          }
        }
      }

      return networks;
    } catch (e) {
      print('Error getting WiFi networks: $e');
      return networks;
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

class NetworkMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
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
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'] ?? 'text',
    );
  }
}
