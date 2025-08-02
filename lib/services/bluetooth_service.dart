import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BluetoothService extends ChangeNotifier {
  // Singleton
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  static BluetoothService get instance => _instance;
  BluetoothService._internal();

  // Reactive BLE instance
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // Tong Chat Service UUIDs
  static const String serviceUUID = '12345678-1234-1234-1234-123456789abc';
  static const String messageCharacteristicUUID =
      '87654321-4321-4321-4321-cba987654321';

  static final Uuid _serviceUuid = Uuid.parse(serviceUUID);
  static final Uuid _charUuid = Uuid.parse(messageCharacteristicUUID);

  // State management
  bool _isAdvertising = false;
  bool _isScanning = false;
  bool _isConnected = false;
  String? _connectedDeviceId;

  // Subscriptions
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _characteristicSubscription;

  // Message handling
  Function(Map<String, dynamic>)? _onMessageReceived;
  QualifiedCharacteristic? _writeCharacteristic;

  // Discovered devices
  final List<DiscoveredDevice> _discoveredDevices = [];

  // Getters
  bool get isAdvertising => _isAdvertising;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  bool get isInitialized => true;
  String? get connectedDeviceId => _connectedDeviceId;
  List<DiscoveredDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  Stream<BleStatus> get statusStream => _ble.statusStream;

  /// Initialize the service
  Future<bool> initialize() async {
    try {
      // Check permissions and Bluetooth status
      final status = await _ble.statusStream.first;
      if (status != BleStatus.ready) {
        if (kDebugMode) print('❌ Bluetooth not ready: $status');
        return false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Failed to initialize Bluetooth: $e');
      return false;
    }
  }

  /// Get Bluetooth status as string
  Future<String> getBluetoothStatus() async {
    try {
      final status = await _ble.statusStream.first;
      switch (status) {
        case BleStatus.ready:
          return 'Ready';
        case BleStatus.poweredOff:
          return 'Powered Off';
        case BleStatus.unauthorized:
          return 'Unauthorized';
        case BleStatus.unsupported:
          return 'Unsupported';
        case BleStatus.locationServicesDisabled:
          return 'Location Services Disabled';
        default:
          return 'Unknown';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Start advertising as a peripheral (server)
  Future<void> startAdvertising() async {
    try {
      if (_isAdvertising) return;

      // Note: flutter_reactive_ble ^5.4.0 may not support advertising
      // This is a placeholder for when/if advertising support is added
      _isAdvertising = false;
      notifyListeners();

      if (kDebugMode) {
        print(
          '⚠️ Advertising not supported in current flutter_reactive_ble version',
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Failed to start advertising: $e');
      _isAdvertising = false;
      notifyListeners();
    }
  }

  /// Stop advertising
  Future<void> stopAdvertising() async {
    _isAdvertising = false;
    notifyListeners();
  }

  /// Start scanning for Tong devices
  Future<void> startScanning({int seconds = 5}) async {
    if (_isScanning) return;

    _discoveredDevices.clear();
    _isScanning = true;
    notifyListeners();

    _scanSubscription = _ble
        .scanForDevices(
          withServices: [_serviceUuid],
          scanMode: ScanMode.lowLatency,
        )
        .listen(
          (device) {
            // Add unique devices
            if (!_discoveredDevices.any((d) => d.id == device.id)) {
              _discoveredDevices.add(device);
              notifyListeners();
              if (kDebugMode) {
                print('📱 Found Tong device: ${device.name} (${device.id})');
              }
            }
          },
          onError: (e) {
            if (kDebugMode) print('❌ Scan error: $e');
          },
        );

    // Auto-stop scanning after specified seconds
    Timer(Duration(seconds: seconds), () {
      stopScanning();
    });
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    notifyListeners();
  }

  /// Scan and connect to first available device
  void scanAndConnect() {
    if (_isScanning) return;

    startScanning(seconds: 10);

    // Listen for discovered devices and connect to first one
    _scanSubscription?.onData((device) async {
      await stopScanning();
      await connectToDeviceId(device.id);
    });
  }

  /// Connect to a discovered device
  Future<bool> connectToDeviceId(
    String deviceId, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      if (_isConnected) await disconnect();

      if (kDebugMode) print('� Connecting to $deviceId...');

      _connectionSubscription = _ble
          .connectToDevice(id: deviceId, connectionTimeout: timeout)
          .listen(
            (connectionState) async {
              if (connectionState.connectionState ==
                  DeviceConnectionState.connected) {
                _connectedDeviceId = deviceId;
                _isConnected = true;
                notifyListeners();

                await _discoverAndSetupCharacteristics(deviceId);
                if (kDebugMode) print('✅ Connected to $deviceId');
              } else if (connectionState.connectionState ==
                  DeviceConnectionState.disconnected) {
                _handleDisconnection();
              }
            },
            onError: (e) {
              if (kDebugMode) print('❌ Connection error: $e');
              _handleDisconnection();
            },
          );

      // Wait for connection
      await Future.delayed(timeout);
      return _isConnected;
    } catch (e) {
      if (kDebugMode) print('❌ Failed to connect: $e');
      return false;
    }
  }

  /// Discover services and setup characteristics
  Future<void> _discoverAndSetupCharacteristics(String deviceId) async {
    try {
      final services = await _ble.discoverServices(deviceId);

      for (final service in services) {
        if (service.serviceId == _serviceUuid) {
          for (final characteristic in service.characteristics) {
            if (characteristic.characteristicId == _charUuid) {
              final qualifiedChar = QualifiedCharacteristic(
                serviceId: _serviceUuid,
                characteristicId: _charUuid,
                deviceId: deviceId,
              );

              // Setup for writing
              _writeCharacteristic = qualifiedChar;

              // Setup for receiving notifications
              _characteristicSubscription = _ble
                  .subscribeToCharacteristic(qualifiedChar)
                  .listen(
                    (data) {
                      _handleIncomingMessage(data);
                    },
                    onError: (e) {
                      if (kDebugMode) {
                        print('❌ Characteristic subscription error: $e');
                      }
                    },
                  );

              if (kDebugMode) print('✅ Chat characteristic setup complete');
              break;
            }
          }
          break;
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Failed to discover characteristics: $e');
    }
  }

  /// Handle incoming message
  void _handleIncomingMessage(List<int> data) {
    try {
      final message = utf8.decode(data);
      final messageJson = jsonDecode(message) as Map<String, dynamic>;

      if (kDebugMode) print('📨 Received message: $message');
      _onMessageReceived?.call(messageJson);
    } catch (e) {
      if (kDebugMode) print('❌ Failed to decode message: $e');
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _isConnected = false;
    _connectedDeviceId = null;
    _writeCharacteristic = null;
    _characteristicSubscription?.cancel();
    _characteristicSubscription = null;
    notifyListeners();

    if (kDebugMode) print('🔌 Disconnected from device');
  }

  /// Send a message
  Future<bool> sendMessage(Map<String, dynamic> message) async {
    if (!_isConnected || _writeCharacteristic == null) {
      if (kDebugMode) print('❌ Cannot send message: not connected');
      return false;
    }

    try {
      final messageJson = jsonEncode(message);
      final messageBytes = utf8.encode(messageJson);

      await _ble.writeCharacteristicWithResponse(
        _writeCharacteristic!,
        value: messageBytes,
      );

      if (kDebugMode) print('📤 Sent message: $messageJson');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Failed to send message: $e');
      return false;
    }
  }

  /// Set message handler
  void setMessageHandler(Function(Map<String, dynamic>) handler) {
    _onMessageReceived = handler;
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      await _characteristicSubscription?.cancel();
      await _connectionSubscription?.cancel();
      await stopScanning();

      _handleDisconnection();

      if (kDebugMode) print('🔌 Manually disconnected');
    } catch (e) {
      if (kDebugMode) print('❌ Error during disconnect: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    stopAdvertising();
    super.dispose();
  }
}
