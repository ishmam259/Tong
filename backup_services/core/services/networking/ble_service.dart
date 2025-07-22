import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  bool _isInitialized = false;
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;

  Function(Map<String, dynamic>)? _messageHandler;
  Function(List<Map<String, dynamic>>)? _deviceHandler;

  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  bool get isConnected => _connectedDevice != null;

  Future<void> initialize() async {
    try {
      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        print("Bluetooth not supported by this device");
        return;
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing BLE: $e');
    }
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      return await FlutterBluePlus.adapterState.first ==
          BluetoothAdapterState.on;
    } catch (e) {
      print('Error checking BLE status: $e');
      return false;
    }
  }

  Future<void> startScanning(
    Function(List<Map<String, dynamic>>) deviceHandler,
  ) async {
    if (!_isInitialized || _isScanning) return;

    try {
      _deviceHandler = deviceHandler;
      _isScanning = true;

      final List<Map<String, dynamic>> devices = [];

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        devices.clear();
        for (ScanResult result in results) {
          devices.add({
            'id': result.device.remoteId.toString(),
            'name':
                result.device.platformName.isNotEmpty
                    ? result.device.platformName
                    : 'Unknown BLE Device',
            'rssi': result.rssi,
            'serviceUuids':
                result.advertisementData.serviceUuids
                    .map((uuid) => uuid.toString())
                    .toList(),
            'manufacturerData': result.advertisementData.manufacturerData,
          });
        }
        _deviceHandler!(devices);
      });

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      print('Error starting BLE scanning: $e');
      _isScanning = false;
    }
  }

  Future<void> stopScanning() async {
    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
    } catch (e) {
      print('Error stopping BLE scanning: $e');
    }
  }

  Future<bool> connect(String deviceId) async {
    try {
      if (_connectedDevice != null) {
        await disconnect(deviceId);
      }

      // Find the device
      final scanResults = await FlutterBluePlus.scanResults.first;
      final device =
          scanResults
              .firstWhere(
                (result) => result.device.remoteId.toString() == deviceId,
              )
              .device;

      // Connect to device
      await device.connect();
      _connectedDevice = device;

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Find characteristics for messaging
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.write) {
            _writeCharacteristic = characteristic;
          }
          if (characteristic.properties.read ||
              characteristic.properties.notify) {
            _readCharacteristic = characteristic;

            // Subscribe to notifications if supported
            if (characteristic.properties.notify) {
              await characteristic.setNotifyValue(true);
              characteristic.lastValueStream.listen(_onDataReceived);
            }
          }
        }
      }

      return true;
    } catch (e) {
      print('Error connecting to BLE device: $e');
      _connectedDevice = null;
      return false;
    }
  }

  Future<void> disconnect(String deviceId) async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _writeCharacteristic = null;
        _readCharacteristic = null;
      }
    } catch (e) {
      print('Error disconnecting BLE: $e');
    }
  }

  Future<bool> sendMessage(Map<String, dynamic> message) async {
    try {
      if (_writeCharacteristic == null || _connectedDevice == null) {
        return false;
      }

      final jsonString = message.toString();
      final data = jsonString.codeUnits;

      // BLE has a limit on data size, so we might need to chunk large messages
      const maxChunkSize = 20; // Typical BLE MTU - 3 bytes for headers

      for (int i = 0; i < data.length; i += maxChunkSize) {
        final end =
            (i + maxChunkSize < data.length) ? i + maxChunkSize : data.length;
        final chunk = data.sublist(i, end);

        await _writeCharacteristic!.write(chunk);
      }

      return true;
    } catch (e) {
      print('Error sending BLE message: $e');
      return false;
    }
  }

  void _onDataReceived(List<int> data) {
    try {
      final message = String.fromCharCodes(data);
      if (_messageHandler != null) {
        _messageHandler!({'content': message, 'type': 'ble'});
      }
    } catch (e) {
      print('Error processing received BLE data: $e');
    }
  }

  void setMessageHandler(Function(Map<String, dynamic>) handler) {
    _messageHandler = handler;
  }

  void dispose() {
    stopScanning();
    if (_connectedDevice != null) {
      _connectedDevice!.disconnect();
    }
    _isInitialized = false;
  }
}
