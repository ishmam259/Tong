import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/permission_service.dart';
import '../services/bluetooth_service.dart';
import '../services/networking_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DeviceDiscoveryScreen extends StatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  State<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends State<DeviceDiscoveryScreen> {
  final PermissionService _permissionService = PermissionService();
  final BluetoothService _bluetoothService = BluetoothService.instance;
  final NetworkingService _networkingService = NetworkingService();

  bool _isScanning = false;
  bool _permissionsGranted = false;
  List<DiscoveredDevice> _bluetoothDevices = [];
  List<Map<String, dynamic>> _wifiDevices = [];
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeAndCheckPermissions();

    // Listen to Bluetooth service changes
    _bluetoothService.addListener(_onBluetoothServiceChanged);
  }

  @override
  void dispose() {
    _bluetoothService.removeListener(_onBluetoothServiceChanged);
    super.dispose();
  }

  void _onBluetoothServiceChanged() {
    if (mounted) {
      setState(() {
        _bluetoothDevices = _bluetoothService.discoveredDevices;
        _isScanning = _bluetoothService.isScanning;
      });
    }
  }

  Future<void> _initializeAndCheckPermissions() async {
    setState(() {
      _status = 'Checking permissions...';
    });

    // Request all permissions
    final permissionsGranted = await _permissionService.requestAllPermissions();

    setState(() {
      _permissionsGranted = permissionsGranted;
      _status =
          permissionsGranted
              ? 'Permissions granted. Ready to scan.'
              : 'Permissions required. Please grant permissions in settings.';
    });

    if (permissionsGranted) {
      // Initialize services
      await _bluetoothService.initialize();
      await _networkingService.initializeNetworking();

      setState(() {
        _status = 'Ready to discover devices';
      });
    }
  }

  Future<void> _startBluetoothScan() async {
    if (!_permissionsGranted) {
      await _initializeAndCheckPermissions();
      return;
    }

    setState(() {
      _status = 'Scanning for Bluetooth devices...';
      _bluetoothDevices.clear();
    });

    try {
      await _bluetoothService.startScanning(seconds: 10);
    } catch (e) {
      setState(() {
        _status = 'Bluetooth scan error: $e';
      });
    }
  }

  Future<void> _startWifiDiscovery() async {
    if (!_permissionsGranted) {
      await _initializeAndCheckPermissions();
      return;
    }

    setState(() {
      _status = 'Discovering WiFi devices...';
      _wifiDevices.clear();
    });

    try {
      final devices = await _networkingService.discoverDevices();
      setState(() {
        _wifiDevices = devices;
        _status = 'Found ${devices.length} WiFi devices';
      });
    } catch (e) {
      setState(() {
        _status = 'WiFi discovery error: $e';
      });
    }
  }

  Future<void> _stopScanning() async {
    await _bluetoothService.stopScanning();
    setState(() {
      _status = 'Scanning stopped';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Discovery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await _permissionService.openAppSettings();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _permissionsGranted
                              ? Icons.check_circle
                              : Icons.error,
                          color:
                              _permissionsGranted ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _permissionsGranted
                              ? 'Permissions granted'
                              : 'Permissions required',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _permissionsGranted && !_isScanning
                            ? _startBluetoothScan
                            : null,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Scan Bluetooth'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _permissionsGranted ? _startWifiDiscovery : null,
                    icon: const Icon(Icons.wifi_find),
                    label: const Text('Find WiFi'),
                  ),
                ),
              ],
            ),

            if (_isScanning) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _stopScanning,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Scanning'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Device Lists
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Bluetooth', icon: Icon(Icons.bluetooth)),
                        Tab(text: 'WiFi', icon: Icon(Icons.wifi)),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Bluetooth Devices
                          _bluetoothDevices.isEmpty
                              ? const Center(
                                child: Text('No Bluetooth devices found'),
                              )
                              : ListView.builder(
                                itemCount: _bluetoothDevices.length,
                                itemBuilder: (context, index) {
                                  final device = _bluetoothDevices[index];
                                  return ListTile(
                                    leading: const Icon(Icons.bluetooth),
                                    title: Text(
                                      device.name.isNotEmpty
                                          ? device.name
                                          : 'Unknown Device',
                                    ),
                                    subtitle: Text(
                                      'ID: ${device.id}\nRSSI: ${device.rssi} dBm',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.connect_without_contact,
                                      ),
                                      onPressed: () async {
                                        // Try to connect to this device
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Connecting to ${device.name.isNotEmpty ? device.name : device.id}...',
                                            ),
                                          ),
                                        );

                                        try {
                                          await _bluetoothService
                                              .connectToDeviceId(device.id);
                                        } catch (e) {
                                          if (kDebugMode) {
                                            print('Connection error: $e');
                                          }
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),

                          // WiFi Devices
                          _wifiDevices.isEmpty
                              ? const Center(
                                child: Text('No WiFi devices found'),
                              )
                              : ListView.builder(
                                itemCount: _wifiDevices.length,
                                itemBuilder: (context, index) {
                                  final device = _wifiDevices[index];
                                  return ListTile(
                                    leading: const Icon(Icons.wifi),
                                    title: Text(
                                      device['name'] ?? 'Unknown Device',
                                    ),
                                    subtitle: Text(
                                      'Address: ${device['address']}\nPort: ${device['port']}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.connect_without_contact,
                                      ),
                                      onPressed: () async {
                                        // Try to connect to this device
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Connecting to ${device['name'] ?? device['address']}...',
                                            ),
                                          ),
                                        );

                                        try {
                                          await _networkingService
                                              .connectToDevice(
                                                device['address'],
                                                port: device['port'] ?? 8080,
                                              );
                                        } catch (e) {
                                          if (kDebugMode) {
                                            print('Connection error: $e');
                                          }
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
