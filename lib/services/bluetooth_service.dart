import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// A BLE service that can act as both peripheral (server) and central (client)
class BluetoothService extends ChangeNotifier {
  // Singleton instance
  BluetoothService._();
  static final BluetoothService instance = BluetoothService._();

  // Reactive BLE instance
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // Custom Tong service and characteristic UUIDs
  static final Uuid _svcUuid = Uuid.parse(
    '12345678-1234-1234-1234-123456789abc',
  );
  static final Uuid _chrUuid = Uuid.parse(
    '87654321-4321-4321-4321-cba987654321',
  );

  // State flags
  bool _isAdvertising = false;
  bool _isScanning = false;
  bool _isConnected = false;
  String? _deviceId;

  // Discovered devices
  final List<DiscoveredDevice> _discoveredDevices = [];
  List<DiscoveredDevice> get discoveredDevices => _discoveredDevices;

  // Subscriptions
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<List<int>>? _notiSub;

  // Characteristic for writing
  QualifiedCharacteristic? _txChar;

  /// Callback for incoming JSON messages
  Function(Map<String, dynamic>)? _onMessage;

  bool get isAdvertising => _isAdvertising;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  Stream<BleStatus> get statusStream => _ble.statusStream;

  /// Start advertising as a BLE peripheral (GATT Server)
  Future<void> startAdvertising() async {
    // Advertising (peripheral) not supported in this build
    _isAdvertising = false;
    notifyListeners();
  }

  /// Stop advertising
  Future<void> stopAdvertising() async {
    // No-op: peripheral advertising not available
    _isAdvertising = false;
    notifyListeners();
  }

  /// Scan for devices for a certain duration
  Future<void> startScanning({int seconds = 5}) async {
    if (_isScanning) return;
    _isScanning = true;
    _discoveredDevices.clear();
    notifyListeners();

    _scanSub = _ble
        .scanForDevices(withServices: [_svcUuid], scanMode: ScanMode.lowLatency)
        .listen((dev) {
          if (_discoveredDevices.every((d) => d.id != dev.id)) {
            _discoveredDevices.add(dev);
            notifyListeners();
          }
        });

    // Stop scanning after a delay
    await Future.delayed(Duration(seconds: seconds));
    await stopScanning();
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    await _scanSub?.cancel();
    _scanSub = null;
    _isScanning = false;
    notifyListeners();
  }

  /// Scan for any Tong peripheral and connect to first advertiser
  void scanAndConnect() {
    if (_isScanning) return;
    _isScanning = true;
    notifyListeners();

    _scanSub = _ble
        .scanForDevices(withServices: [_svcUuid], scanMode: ScanMode.lowLatency)
        .listen((dev) {
          // stop scanning
          _scanSub?.cancel();
          _isScanning = false;
          notifyListeners();
          // connect
          _connect(dev.id);
        });
  }

  /// Internal connect: central role connects to device ID
  void _connect(String id) {
    _deviceId = id;
    _connSub = _ble
        .connectToDevice(id: id, connectionTimeout: const Duration(seconds: 10))
        .listen((update) async {
          if (update.connectionState == DeviceConnectionState.connected) {
            _isConnected = true;
            notifyListeners();

            // Discover services and characteristic
            await _ble.discoverServices(id);
            // subscribe to notifications
            final qc = QualifiedCharacteristic(
              serviceId: _svcUuid,
              characteristicId: _chrUuid,
              deviceId: id,
            );
            _notiSub = _ble.subscribeToCharacteristic(qc).listen((data) {
              final msg = utf8.decode(data);
              _onMessage?.call(jsonDecode(msg) as Map<String, dynamic>);
            });
            // save for writes
            _txChar = qc;
          }
        });
  }

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    await _notiSub?.cancel();
    await _connSub?.cancel();
    _isConnected = false;
    _txChar = null;
    notifyListeners();
  }

  /// Send JSON-encoded message over BLE
  Future<bool> sendMessage(Map<String, dynamic> message) async {
    if (!_isConnected || _txChar == null) return false;
    final bytes = utf8.encode(jsonEncode(message));
    await _ble.writeCharacteristicWithResponse(_txChar!, value: bytes);
    return true;
  }

  /// Set handler for incoming messages
  void setMessageHandler(Function(Map<String, dynamic>) handler) {
    _onMessage = handler;
  }

  @override
  void dispose() {
    disconnect();
    stopAdvertising();
    super.dispose();
  }
}
