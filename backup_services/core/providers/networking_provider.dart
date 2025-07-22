import 'package:flutter/foundation.dart';
import '../models/network_connection.dart';
import '../models/message.dart';
import '../services/service_locator.dart';
import '../services/networking/socket_service.dart';
import '../services/networking/bluetooth_service.dart';
import '../services/networking/ble_service.dart';

class NetworkingProvider extends ChangeNotifier {
  final List<NetworkConnection> _connections = [];
  NetworkConnection? _primaryConnection;
  bool _isScanning = false;
  bool _autoReconnect = true;
  int _maxRetries = 5;

  List<NetworkConnection> get connections => _connections;
  NetworkConnection? get primaryConnection => _primaryConnection;
  bool get isScanning => _isScanning;
  bool get autoReconnect => _autoReconnect;
  bool get hasActiveConnection =>
      _primaryConnection?.status == ConnectionStatus.connected;

  Future<void> initialize() async {
    try {
      // Initialize networking services
      await _initializeServices();

      // Load saved connections
      await _loadSavedConnections();

      // Start auto-reconnection if enabled
      if (_autoReconnect) {
        _startAutoReconnection();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing networking provider: $e');
    }
  }

  Future<void> _initializeServices() async {
    try {
      await getIt<SocketService>().initialize();
      await getIt<BluetoothService>().initialize();
      await getIt<BleService>().initialize();
    } catch (e) {
      debugPrint('Error initializing networking services: $e');
    }
  }

  Future<void> _loadSavedConnections() async {
    // Load saved connections from storage
    // Implementation will depend on storage service
  }

  void startScanning({List<NetworkType>? types}) {
    if (_isScanning) return;

    _isScanning = true;
    notifyListeners();

    final typesToScan =
        types ?? [NetworkType.bluetooth, NetworkType.ble, NetworkType.internet];

    for (final type in typesToScan) {
      switch (type) {
        case NetworkType.bluetooth:
          _scanBluetooth();
          break;
        case NetworkType.ble:
          _scanBLE();
          break;
        case NetworkType.internet:
          _scanInternet();
          break;
        case NetworkType.local:
          _scanLocal();
          break;
      }
    }
  }

  void stopScanning() {
    _isScanning = false;
    notifyListeners();

    // Stop all scanning services
    getIt<BluetoothService>().stopScanning();
    getIt<BleService>().stopScanning();
  }

  Future<void> _scanBluetooth() async {
    try {
      final bluetoothService = getIt<BluetoothService>();

      // Set up device handler before starting scan
      bluetoothService.setDeviceHandler((devices) {
        for (final device in devices) {
          final connection = NetworkConnection(
            id: device['address'],
            type: NetworkType.bluetooth,
            address: device['address'],
            name: device['name'] ?? 'Unknown Device',
            metadata: device,
          );

          _addOrUpdateConnection(connection);
        }
      });

      // Start scanning
      await bluetoothService.startScanning();
    } catch (e) {
      debugPrint('Error scanning Bluetooth: $e');
    }
  }

  Future<void> _scanBLE() async {
    try {
      final bleService = getIt<BleService>();
      await bleService.startScanning((devices) {
        for (final device in devices) {
          final connection = NetworkConnection(
            id: device['id'],
            type: NetworkType.ble,
            address: device['id'],
            name: device['name'] ?? 'BLE Device',
            metadata: device,
          );

          _addOrUpdateConnection(connection);
        }
      });
    } catch (e) {
      debugPrint('Error scanning BLE: $e');
    }
  }

  Future<void> _scanInternet() async {
    // Implement internet peer discovery
    // This could involve finding peers on local network or through discovery servers
  }

  Future<void> _scanLocal() async {
    // Implement local network scanning
    // Find devices on the same WiFi network
  }

  void _addOrUpdateConnection(NetworkConnection connection) {
    final existingIndex = _connections.indexWhere((c) => c.id == connection.id);
    if (existingIndex >= 0) {
      _connections[existingIndex] = connection;
    } else {
      _connections.add(connection);
    }
    notifyListeners();
  }

  Future<bool> connectTo(NetworkConnection connection) async {
    try {
      connection.status = ConnectionStatus.connecting;
      _addOrUpdateConnection(connection);

      bool success = false;

      switch (connection.type) {
        case NetworkType.bluetooth:
          success = await getIt<BluetoothService>().connect(connection.address);
          break;
        case NetworkType.ble:
          success = await getIt<BleService>().connect(connection.address);
          break;
        case NetworkType.internet:
          success = await getIt<SocketService>().connect(connection.address);
          break;
        case NetworkType.local:
          // Implement local connection
          break;
      }

      if (success) {
        connection.status = ConnectionStatus.connected;
        connection.lastConnected = DateTime.now();
        connection.retryCount = 0;
        _primaryConnection = connection;
      } else {
        connection.status = ConnectionStatus.failed;
        connection.retryCount++;
      }

      _addOrUpdateConnection(connection);
      return success;
    } catch (e) {
      debugPrint('Error connecting to ${connection.name}: $e');
      connection.status = ConnectionStatus.failed;
      connection.retryCount++;
      _addOrUpdateConnection(connection);
      return false;
    }
  }

  Future<void> disconnect(NetworkConnection connection) async {
    try {
      switch (connection.type) {
        case NetworkType.bluetooth:
          await getIt<BluetoothService>().disconnect(connection.address);
          break;
        case NetworkType.ble:
          await getIt<BleService>().disconnect(connection.address);
          break;
        case NetworkType.internet:
          await getIt<SocketService>().disconnect();
          break;
        case NetworkType.local:
          // Implement local disconnection
          break;
      }

      connection.status = ConnectionStatus.disconnected;
      if (_primaryConnection?.id == connection.id) {
        _primaryConnection = null;
      }

      _addOrUpdateConnection(connection);
    } catch (e) {
      debugPrint('Error disconnecting from ${connection.name}: $e');
    }
  }

  Future<bool> sendMessage(Message message) async {
    if (_primaryConnection?.status != ConnectionStatus.connected) {
      return false;
    }

    try {
      switch (_primaryConnection!.type) {
        case NetworkType.bluetooth:
          return await getIt<BluetoothService>().sendMessage(message.toJson());
        case NetworkType.ble:
          return await getIt<BleService>().sendMessage(message.toJson());
        case NetworkType.internet:
          return await getIt<SocketService>().sendMessage(message.toJson());
        case NetworkType.local:
          // Implement local message sending
          return false;
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  void _startAutoReconnection() {
    // Implement auto-reconnection logic
    // This should periodically try to reconnect to failed connections
  }

  void setAutoReconnect(bool enabled) {
    _autoReconnect = enabled;
    if (enabled) {
      _startAutoReconnection();
    }
    notifyListeners();
  }

  void setMaxRetries(int maxRetries) {
    _maxRetries = maxRetries;
    notifyListeners();
  }

  void removeConnection(String connectionId) {
    _connections.removeWhere((c) => c.id == connectionId);
    if (_primaryConnection?.id == connectionId) {
      _primaryConnection = null;
    }
    notifyListeners();
  }

  void clearConnections() {
    _connections.clear();
    _primaryConnection = null;
    notifyListeners();
  }

  void reset() {
    clearConnections();
    _isScanning = false;
    _autoReconnect = true;
    _maxRetries = 5;
    notifyListeners();
  }
}
