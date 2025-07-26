import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';

class BluetoothService extends ChangeNotifier {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isConnected = false;
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _messageCharacteristic;
  final List<fbp.BluetoothDevice> _discoveredDevices = [];
  Function(Map<String, dynamic>)? _onMessageReceived;

  // Tong Messenger Bluetooth Service UUID
  static const String serviceUUID = "12345678-1234-1234-1234-123456789abc";
  static const String messageCharacteristicUUID =
      "87654321-4321-4321-4321-cba987654321";

  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;
  List<fbp.BluetoothDevice> get discoveredDevices => _discoveredDevices;

  // Add method to get current Bluetooth status
  Future<String> getBluetoothStatus() async {
    try {
      if (await fbp.FlutterBluePlus.isSupported == false) {
        return "Bluetooth not supported";
      }

      final adapterState = await fbp.FlutterBluePlus.adapterState.first.timeout(
        Duration(seconds: 3),
        onTimeout: () => fbp.BluetoothAdapterState.unknown,
      );

      switch (adapterState) {
        case fbp.BluetoothAdapterState.on:
          return _isInitialized ? "Ready" : "Available";
        case fbp.BluetoothAdapterState.off:
          return "Turned off";
        case fbp.BluetoothAdapterState.turningOn:
          return "Turning on...";
        case fbp.BluetoothAdapterState.turningOff:
          return "Turning off...";
        default:
          return "Unknown state";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<bool> initialize() async {
    try {
      print("Starting Bluetooth initialization...");

      // Check if Bluetooth is supported
      if (await fbp.FlutterBluePlus.isSupported == false) {
        print("Bluetooth not supported by this device");
        return false;
      }
      print("Bluetooth is supported");

      // Request necessary permissions
      print("Requesting Bluetooth permissions...");
      if (!await _requestPermissions()) {
        print("Bluetooth permissions not granted");
        return false;
      }
      print("Bluetooth permissions granted");

      // Check if Bluetooth is enabled
      print("Checking Bluetooth adapter state...");
      try {
        final adapterState = await fbp.FlutterBluePlus.adapterState.first
            .timeout(
              Duration(seconds: 5),
              onTimeout: () {
                print("Timeout waiting for adapter state");
                return fbp.BluetoothAdapterState.unknown;
              },
            );

        print("Bluetooth adapter state: $adapterState");

        if (adapterState == fbp.BluetoothAdapterState.on) {
          _isInitialized = true;
          notifyListeners();
          print("Bluetooth service initialized successfully");
          return true;
        } else if (adapterState == fbp.BluetoothAdapterState.off) {
          print("Bluetooth is turned off - attempting to enable");
          // Try to enable Bluetooth
          final enabled = await enableBluetooth();
          if (enabled) {
            _isInitialized = true;
            notifyListeners();
            print("Bluetooth enabled and service initialized");
            return true;
          }
        }
      } catch (e) {
        print("Error checking adapter state: $e");
      }

      print("Bluetooth adapter is not ready");
      return false;
    } catch (e) {
      print('Error initializing Bluetooth: $e');
      return false;
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        print("Requesting Android Bluetooth permissions...");

        final permissions = [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
          Permission.location,
        ];

        // Check current status first
        Map<Permission, PermissionStatus> currentStatuses = {};
        for (Permission permission in permissions) {
          currentStatuses[permission] = await permission.status;
          print("${permission.toString()}: ${currentStatuses[permission]}");
        }

        // Request permissions
        Map<Permission, PermissionStatus> statuses =
            await permissions.request();

        // Log results
        for (Permission permission in permissions) {
          print(
            "${permission.toString()} after request: ${statuses[permission]}",
          );
        }

        bool allGranted = statuses.values.every(
          (status) =>
              status == PermissionStatus.granted ||
              status == PermissionStatus.limited,
        );

        print("All Bluetooth permissions granted: $allGranted");
        return allGranted;
      }

      print("iOS - permissions handled automatically");
      return true; // iOS handles permissions automatically
    } catch (e) {
      print("Error requesting permissions: $e");
      return false;
    }
  }

  Future<bool> enableBluetooth() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await fbp.FlutterBluePlus.turnOn();
        return true;
      }
      return true; // iOS doesn't allow programmatic enabling
    } catch (e) {
      print('Error enabling Bluetooth: $e');
      return false;
    }
  }

  Future<void> startScanning() async {
    if (!_isInitialized) {
      print("Bluetooth not initialized, attempting to initialize...");
      if (!await initialize()) {
        print("Failed to initialize Bluetooth for scanning");
        return;
      }
    }

    if (_isScanning) {
      print("Already scanning, stopping current scan first");
      await stopScanning();
    }

    try {
      print("Starting Bluetooth scan...");
      _isScanning = true;
      _discoveredDevices.clear();
      notifyListeners();

      // Get bonded (paired) devices first
      print("Getting bonded devices...");
      try {
        final bondedDevices = await fbp.FlutterBluePlus.bondedDevices;
        for (var device in bondedDevices) {
          if (!_discoveredDevices.any((d) => d.remoteId == device.remoteId)) {
            _discoveredDevices.add(device);
            print(
              "Found bonded device: ${device.platformName.isNotEmpty ? device.platformName : 'Unknown'} (${device.remoteId})",
            );
          }
        }
        notifyListeners();
      } catch (e) {
        print("Error getting bonded devices: $e");
      }

      // Start scanning for all nearby devices
      print("Scanning for nearby Bluetooth devices...");
      await fbp.FlutterBluePlus.startScan(timeout: Duration(seconds: 15));

      // Listen for scan results
      fbp.FlutterBluePlus.scanResults.listen((results) {
        print("Scan results received: ${results.length} devices");
        for (fbp.ScanResult result in results) {
          if (!_discoveredDevices.any(
            (d) => d.remoteId == result.device.remoteId,
          )) {
            _discoveredDevices.add(result.device);
            print(
              "Found device: ${result.device.platformName.isNotEmpty ? result.device.platformName : 'Unknown'} (${result.device.remoteId}) RSSI: ${result.rssi}",
            );
          }
        }
        notifyListeners();
      });

      // Stop scanning after timeout
      await Future.delayed(Duration(seconds: 15));
      await stopScanning();
      print(
        "Bluetooth scan completed. Found ${_discoveredDevices.length} devices.",
      );
    } catch (e) {
      print('Error starting Bluetooth scan: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScanning() async {
    try {
      await fbp.FlutterBluePlus.stopScan();
      _isScanning = false;
      notifyListeners();
      print("Bluetooth scan stopped");
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  Future<bool> connectToDevice(fbp.BluetoothDevice device) async {
    if (!_isInitialized) return false;

    try {
      print(
        "Attempting to connect to ${device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'}...",
      );

      // First, check if device is already connected
      if (device.isConnected) {
        print("Device is already connected");
        _connectedDevice = device;
        _isConnected = true;
        notifyListeners();
        return true;
      }

      // Ensure any previous connections are cleaned up
      try {
        await device.disconnect();
        await Future.delayed(Duration(milliseconds: 500));
      } catch (e) {
        // Ignore disconnect errors for unconnected devices
      }

      // Try connection with multiple attempts to handle Android error 133
      bool connected = false;
      int attempts = 0;
      const maxAttempts = 3;

      while (!connected && attempts < maxAttempts) {
        attempts++;
        print("Connection attempt $attempts of $maxAttempts");

        try {
          // Use a longer timeout for more reliable connection
          await device.connect(
            timeout: Duration(seconds: 20),
            autoConnect: false, // Disable auto-connect for better control
          );

          // Wait a moment for connection to stabilize
          await Future.delayed(Duration(milliseconds: 1000));

          if (device.isConnected) {
            connected = true;
            print("Successfully connected on attempt $attempts");
          } else {
            print("Device not connected after attempt $attempts");
            if (attempts < maxAttempts) {
              await Future.delayed(Duration(seconds: 2));
            }
          }
        } catch (e) {
          print("Connection attempt $attempts failed: $e");
          if (attempts < maxAttempts) {
            await Future.delayed(Duration(seconds: 2));
          } else {
            rethrow;
          }
        }
      }

      if (!connected) {
        print("Failed to connect after $maxAttempts attempts");
        return false;
      }

      _connectedDevice = device;
      _isConnected = true;

      // Try to discover services with timeout
      print("Discovering services...");
      List<fbp.BluetoothService> services;
      try {
        services = await device.discoverServices().timeout(
          Duration(seconds: 10),
        );
        print("Found ${services.length} services");
      } catch (e) {
        print("Service discovery failed: $e");
        // Continue anyway - we might be able to use the device without services
        notifyListeners();
        return true;
      }

      // Look for suitable characteristics for communication
      fbp.BluetoothCharacteristic? writeCharacteristic;
      fbp.BluetoothCharacteristic? notifyCharacteristic;

      for (fbp.BluetoothService service in services) {
        print("Service: ${service.uuid}");
        for (fbp.BluetoothCharacteristic characteristic
            in service.characteristics) {
          print(
            "  Characteristic: ${characteristic.uuid} - Properties: ${characteristic.properties}",
          );

          // Look for characteristics we can write to
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            writeCharacteristic = characteristic;
            print("  Found writable characteristic: ${characteristic.uuid}");
          }

          // Look for characteristics we can read notifications from
          if (characteristic.properties.notify ||
              characteristic.properties.read) {
            notifyCharacteristic = characteristic;
            print(
              "  Found readable/notify characteristic: ${characteristic.uuid}",
            );
          }
        }
      }

      // Set up communication if we found suitable characteristics
      if (writeCharacteristic != null) {
        _messageCharacteristic = writeCharacteristic;
        print("Set up write characteristic: ${writeCharacteristic.uuid}");

        // Enable notifications if available
        if (notifyCharacteristic != null &&
            notifyCharacteristic.properties.notify) {
          try {
            await notifyCharacteristic.setNotifyValue(true);
            notifyCharacteristic.lastValueStream.listen(_handleIncomingMessage);
            print("Enabled notifications on: ${notifyCharacteristic.uuid}");
          } catch (e) {
            print("Could not enable notifications: $e");
          }
        }
      } else {
        print("No writable characteristics found - basic connection only");
      }

      notifyListeners();
      print("Successfully connected and configured Bluetooth communication");
      return true;
    } catch (e) {
      print('Error connecting to device: $e');

      // Clean up on failure
      try {
        await device.disconnect();
      } catch (disconnectError) {
        print('Error during cleanup disconnect: $disconnectError');
      }

      _isConnected = false;
      _connectedDevice = null;
      _messageCharacteristic = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _messageCharacteristic = null;
        _isConnected = false;
        notifyListeners();
        print("Disconnected from Bluetooth device");
      }
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  Future<bool> sendMessage(Map<String, dynamic> message) async {
    if (!_isConnected || _messageCharacteristic == null) {
      print("Cannot send message: not connected or characteristic not found");
      return false;
    }

    try {
      final messageJson = jsonEncode(message);
      final messageBytes = Uint8List.fromList(utf8.encode(messageJson));

      // Split large messages into chunks (BLE has ~512 byte limit)
      const chunkSize = 500;

      if (messageBytes.length <= chunkSize) {
        await _messageCharacteristic!.write(messageBytes);
      } else {
        // Send chunked message
        for (int i = 0; i < messageBytes.length; i += chunkSize) {
          final end =
              (i + chunkSize < messageBytes.length)
                  ? i + chunkSize
                  : messageBytes.length;
          final chunk = messageBytes.sublist(i, end);
          await _messageCharacteristic!.write(chunk);
          await Future.delayed(
            Duration(milliseconds: 50),
          ); // Small delay between chunks
        }
      }

      print("Bluetooth message sent: $messageJson");
      return true;
    } catch (e) {
      print('Error sending Bluetooth message: $e');
      return false;
    }
  }

  void _handleIncomingMessage(List<int> data) {
    try {
      final messageString = utf8.decode(data);
      final messageData = jsonDecode(messageString);

      print("Received Bluetooth message: $messageString");
      _onMessageReceived?.call(messageData);
    } catch (e) {
      print('Error handling incoming Bluetooth message: $e');
    }
  }

  void setMessageHandler(Function(Map<String, dynamic>) handler) {
    _onMessageReceived = handler;
  }

  Future<bool> startAdvertising() async {
    if (!_isInitialized) return false;

    try {
      print("Starting Bluetooth advertising...");

      // Note: FlutterBluePlus doesn't support peripheral mode (advertising)
      // This would require platform-specific implementation
      print("Advertising not supported in current FlutterBluePlus version");
      return false;
    } catch (e) {
      print('Error starting advertising: $e');
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    await stopScanning();
    await disconnect();
    super.dispose();
  }

  // Get discovered devices as map format for UI compatibility
  List<Map<String, dynamic>> getDiscoveredDevicesAsMap() {
    return _discoveredDevices.map((device) {
      // Check if this might be a Tong device based on name or recent activity
      bool mightBeTongDevice = false;
      String deviceName =
          device.platformName.isNotEmpty
              ? device.platformName
              : 'Unknown Device';

      // Look for indicators that this might be a Tong device
      if (deviceName.toLowerCase().contains('tong') ||
          deviceName.toLowerCase().contains('messenger') ||
          device.bondState == fbp.BluetoothBondState.bonded) {
        mightBeTongDevice = true;
      }

      return {
        'name': deviceName,
        'address': device.remoteId.toString(),
        'type': 'Bluetooth',
        'signal': 'Available',
        'available': true,
        'category':
            mightBeTongDevice ? 'Possible Tong Device' : 'Bluetooth Device',
        'device': device, // Store actual device for connection
        'bondState': device.bondState.toString(),
        'isTongDevice': mightBeTongDevice,
      };
    }).toList();
  }

  // Add method to check if device is already paired
  Future<bool> isDevicePaired(fbp.BluetoothDevice device) async {
    try {
      final bondedDevices = await fbp.FlutterBluePlus.bondedDevices;
      return bondedDevices.any((d) => d.remoteId == device.remoteId);
    } catch (e) {
      print("Error checking device pair status: $e");
      return false;
    }
  }

  // Add method to pair with device
  Future<bool> pairWithDevice(fbp.BluetoothDevice device) async {
    try {
      print("Attempting to pair with ${device.platformName}...");

      // On Android, pairing happens automatically during connection
      // On iOS, pairing is handled by the system
      await device.connect(timeout: Duration(seconds: 30));
      await device.disconnect();

      print("Successfully paired with ${device.platformName}");
      return true;
    } catch (e) {
      print("Error pairing with device: $e");
      return false;
    }
  }

  // Method to help identify if this device should be discoverable as a Tong device
  Future<void> enableTongDiscoverability() async {
    try {
      print("Enabling Tong device discoverability...");
      // This would ideally set the device name to include "Tong"
      // Unfortunately, flutter_blue_plus doesn't provide this functionality
      // Users may need to manually rename their devices to include "Tong"
      // in Android Settings → Bluetooth → Device name
      print("To help other Tong devices find you:");
      print("1. Go to Android Settings → Bluetooth");
      print("2. Tap on 'Device name' or gear icon");
      print(
        "3. Change your device name to include 'Tong' (e.g., 'John's Tong Phone')",
      );
    } catch (e) {
      print("Error enabling discoverability: $e");
    }
  }
}
