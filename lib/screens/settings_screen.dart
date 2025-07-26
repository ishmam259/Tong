import 'package:flutter/material.dart';
import '../main.dart' show themeProvider;
import '../services/networking_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  String _nickname = 'Anonymous User';
  String _connectionType = 'WiFi';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text('Nickname'),
                    subtitle: Text(_nickname),
                    trailing: Icon(Icons.edit),
                    onTap: _editNickname,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Connection Section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.wifi, color: Colors.blue),
                    title: Text('Connection Type'),
                    subtitle: Text(_connectionType),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: _selectConnectionType,
                  ),
                  ListTile(
                    leading: Icon(Icons.network_check, color: Colors.green),
                    title: Text('Network Discovery'),
                    subtitle: Text('Scan for nearby devices'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: _openNetworkDiscovery,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.bluetooth_searching,
                      color: Colors.blue,
                    ),
                    title: Text('Bluetooth Diagnostics'),
                    subtitle: Text('Check Bluetooth status and troubleshoot'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: _openBluetoothDiagnostics,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Notifications Section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 16),
                  SwitchListTile(
                    secondary: Icon(Icons.notifications, color: Colors.blue),
                    title: Text('Enable Notifications'),
                    subtitle: Text('Get notified of new messages'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    secondary: Icon(Icons.volume_up, color: Colors.blue),
                    title: Text('Sound'),
                    subtitle: Text('Play sound for notifications'),
                    value: _soundEnabled,
                    onChanged: (value) {
                      setState(() {
                        _soundEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Appearance Section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 16),
                  SwitchListTile(
                    secondary: Icon(Icons.dark_mode, color: Colors.blue),
                    title: Text('Dark Mode'),
                    subtitle: Text('Switch to dark theme'),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) async {
                      await themeProvider.setTheme(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // About Section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.info, color: Colors.blue),
                    title: Text('Version'),
                    subtitle: Text('Tong Messenger v1.0.0'),
                  ),
                  ListTile(
                    leading: Icon(Icons.help, color: Colors.blue),
                    title: Text('Help & Support'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: _showHelpDialog,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editNickname() {
    showDialog(
      context: context,
      builder: (context) {
        String newNickname = _nickname;
        return AlertDialog(
          title: Text('Edit Nickname'),
          content: TextField(
            onChanged: (value) => newNickname = value,
            decoration: InputDecoration(
              hintText: 'Enter your nickname',
              prefixIcon: Icon(Icons.person),
            ),
            controller: TextEditingController(text: _nickname),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _nickname =
                      newNickname.isNotEmpty ? newNickname : 'Anonymous User';
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _selectConnectionType() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Connection Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.wifi),
                title: Text('WiFi Network'),
                subtitle: Text('Connect via local WiFi'),
                onTap: () {
                  setState(() {
                    _connectionType = 'WiFi';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.bluetooth),
                title: Text('Bluetooth'),
                subtitle: Text('Connect via Bluetooth'),
                onTap: () {
                  setState(() {
                    _connectionType = 'Bluetooth';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.cloud),
                title: Text('Internet'),
                subtitle: Text('Connect via internet'),
                onTap: () {
                  setState(() {
                    _connectionType = 'Internet';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openNetworkDiscovery() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NetworkDiscoveryScreen()),
    );
  }

  void _openBluetoothDiagnostics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BluetoothDiagnosticsScreen()),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Help & Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tong Messenger Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Multi-network messaging (WiFi, Bluetooth, Internet)'),
              Text('• Anonymous identity system'),
              Text('• Encrypted communication'),
              Text('• Offline message storage'),
              Text('• Multi-device synchronization'),
              SizedBox(height: 16),
              Text(
                'For support, contact: support@tongmessenger.com',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class NetworkDiscoveryScreen extends StatefulWidget {
  const NetworkDiscoveryScreen({super.key});

  @override
  _NetworkDiscoveryScreenState createState() => _NetworkDiscoveryScreenState();
}

class _NetworkDiscoveryScreenState extends State<NetworkDiscoveryScreen> {
  bool _isScanning = false;
  final List<Map<String, dynamic>> _discoveredDevices = [];
  final NetworkingService _networkingService = NetworkingService();

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  void _startScanning() async {
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
    });

    try {
      print('Starting network discovery...');

      // Get local device info first
      final localIP = await _networkingService.getLocalIPAddress();
      if (localIP != null && mounted) {
        setState(() {
          _discoveredDevices.add({
            'name': 'This Device',
            'type': 'Local',
            'address': localIP,
            'signal': 'Local',
            'available': true,
            'category': 'Local Device',
          });
        });
      }

      // Get WiFi networks
      final wifiNetworks = await _networkingService.getAvailableWiFiNetworks();
      print('Found ${wifiNetworks.length} WiFi networks');

      // Scan for Bluetooth devices
      print('Scanning for Bluetooth devices...');
      final bluetoothDevices =
          await _networkingService.getAvailableBluetoothDevices();
      print('Found ${bluetoothDevices.length} Bluetooth devices');

      // Scan for Tong devices on the local network
      print('Scanning for Tong devices...');
      final tongDevices = await _networkingService.discoverNetworkDevices();
      print('Found ${tongDevices.length} Tong devices');

      if (mounted) {
        setState(() {
          // Add WiFi networks
          _discoveredDevices.addAll(
            wifiNetworks.map(
              (network) => {...network, 'category': 'WiFi Network'},
            ),
          );

          // Add Bluetooth devices
          _discoveredDevices.addAll(
            bluetoothDevices.map(
              (device) => {...device, 'category': 'Bluetooth Device'},
            ),
          );

          // Add discovered Tong devices
          _discoveredDevices.addAll(
            tongDevices.map((device) => {...device, 'category': 'Tong Device'}),
          );

          // Add helpful info if no devices found
          if (_discoveredDevices.length <= 1) {
            // Only local device
            _discoveredDevices.addAll([
              {
                'name': 'No other devices found',
                'type': 'Info',
                'signal':
                    'Scanned WiFi: ${localIP?.split('.').take(3).join('.')}.1-254\nScanned Bluetooth: ${bluetoothDevices.length} devices',
                'available': false,
                'category': 'Scan Result',
                'info': true,
              },
              {
                'name': 'To connect with friends via Bluetooth',
                'type': 'Info',
                'signal':
                    '1. Both devices: Go to Android Settings → Bluetooth\n2. Change device name to include "Tong" (e.g., "John\'s Tong Phone")\n3. Make sure devices are discoverable\n4. Refresh this scan',
                'available': false,
                'category': 'How to Connect',
                'info': true,
              },
              {
                'name': 'To connect via WiFi/IP',
                'type': 'Info',
                'signal':
                    '1. Share your IP: $localIP\n2. Ask them to install Tong\n3. Use manual connect with your IP address',
                'available': false,
                'category': 'WiFi Connection',
                'info': true,
              },
            ]);
          }

          _isScanning = false;
        });
      }
    } catch (e) {
      print('Error during network discovery: $e');
      if (mounted) {
        setState(() {
          _isScanning = false;

          // Add error info
          _discoveredDevices.add({
            'name': 'Network scan failed',
            'type': 'Error',
            'signal': 'Error: $e',
            'available': false,
            'category': 'Error',
            'info': true,
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network scan failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network Discovery'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
            onPressed: _isScanning ? _stopScanning : _startScanning,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isScanning)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('Scanning for devices...'),
                ],
              ),
            ),
          Expanded(
            child:
                _discoveredDevices.isEmpty && !_isScanning
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No devices found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try scanning again',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final device = _discoveredDevices[index];
                        final isLocal = device['type'] == 'Local';
                        final isTongDevice =
                            device['category'] == 'Tong Device';
                        final isPossibleTongDevice =
                            device['category'] == 'Possible Tong Device';
                        final isBluetoothDevice =
                            device['category'] == 'Bluetooth Device' ||
                            isPossibleTongDevice;
                        final isInfo = device['info'] == true;

                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          color: isInfo ? Colors.grey[50] : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  isLocal
                                      ? Colors.blue
                                      : isInfo
                                      ? Colors.grey[400]
                                      : isPossibleTongDevice
                                      ? Colors.green[600]
                                      : isBluetoothDevice
                                      ? Colors.purple[600]
                                      : device['available']
                                      ? Colors.green
                                      : Colors.grey,
                              child: Icon(
                                _getDeviceIcon(device['type']),
                                color: Colors.white,
                                size: isInfo ? 16 : 24,
                              ),
                            ),
                            title: Text(
                              device['name'],
                              style: TextStyle(
                                fontSize: isInfo ? 14 : 16,
                                fontWeight:
                                    isInfo
                                        ? FontWeight.normal
                                        : FontWeight.w500,
                                color: isInfo ? Colors.grey[700] : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isInfo
                                      ? device['signal']
                                      : '${device['type']} • Signal: ${device['signal']}',
                                  style: TextStyle(
                                    fontSize: isInfo ? 12 : 14,
                                    color: isInfo ? Colors.grey[600] : null,
                                  ),
                                ),
                                if (device['address'] != null && !isInfo)
                                  Text(
                                    'Address: ${device['address']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                if (!isInfo)
                                  Text(
                                    device['category'] ?? 'Network',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            trailing:
                                isLocal
                                    ? Chip(
                                      label: Text(
                                        'You',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: Colors.blue[100],
                                    )
                                    : isInfo
                                    ? Icon(
                                      Icons.info_outline,
                                      color: Colors.grey[400],
                                      size: 20,
                                    )
                                    : ElevatedButton(
                                      onPressed:
                                          device['available'] &&
                                                  (isTongDevice ||
                                                      isPossibleTongDevice ||
                                                      isBluetoothDevice)
                                              ? () => _connectToDevice(device)
                                              : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            device['available'] &&
                                                    (isTongDevice ||
                                                        isPossibleTongDevice ||
                                                        isBluetoothDevice)
                                                ? (isPossibleTongDevice
                                                    ? Colors.green[600]
                                                    : isBluetoothDevice
                                                    ? Colors.purple[600]
                                                    : Colors.blue)
                                                : Colors.grey,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        !device['available']
                                            ? 'Offline'
                                            : !(isTongDevice ||
                                                isPossibleTongDevice ||
                                                isBluetoothDevice)
                                            ? 'Info'
                                            : 'Connect',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'Bluetooth':
        return Icons.bluetooth;
      case 'WiFi':
        return Icons.wifi;
      case 'Internet':
        return Icons.cloud;
      case 'TCP':
        return Icons.computer;
      case 'Local':
        return Icons.smartphone;
      case 'Info':
        return Icons.info_outline;
      case 'Error':
        return Icons.error_outline;
      default:
        return Icons.device_unknown;
    }
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
  }

  void _connectToDevice(Map<String, dynamic> device) {
    final isDirectConnection = device['address'] != null;
    final isBluetoothDevice = device['category'] == 'Bluetooth Device';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Connect to ${device['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Do you want to connect to this device for messaging?'),
              SizedBox(height: 8),
              if (isDirectConnection) ...[
                Text('Address: ${device['address']}'),
                Text('Type: ${device['type']}'),
                if (isBluetoothDevice && device['bondState'] != null)
                  Text('Pair Status: ${device['bondState']}'),
              ],
              if (isBluetoothDevice) ...[
                SizedBox(height: 8),
                Text(
                  'Note: Bluetooth connection may require device pairing first.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            if (isBluetoothDevice &&
                device['bondState'] == 'BluetoothBondState.none')
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pairWithDevice(device);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('Pair First'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performConnection(device);
              },
              child: Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  void _performConnection(Map<String, dynamic> device) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connecting to ${device['name']}...'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      bool success = false;
      final deviceType = device['type'];

      if (deviceType == 'Bluetooth') {
        // Try Bluetooth connection
        success = await _networkingService.connectToBluetoothDevice(device);
      } else if (device['address'] != null) {
        // Try direct TCP connection
        success = await _networkingService.connectToDevice(
          device['address'],
          port: device['port'] ?? 8080,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Connected to ${device['name']} via $deviceType!'
                  : 'Failed to connect to ${device['name']}',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          // Go back to messaging screen
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _pairWithDevice(Map<String, dynamic> device) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pairing with ${device['name']}...'),
        backgroundColor: Colors.orange,
      ),
    );

    try {
      final bluetoothService = _networkingService.bluetoothService;
      final success = await bluetoothService.pairWithDevice(device['device']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Successfully paired with ${device['name']}!'
                  : 'Failed to pair with ${device['name']}',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          // Refresh the device list to show updated pairing status
          _startScanning();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pairing error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class BluetoothDiagnosticsScreen extends StatefulWidget {
  const BluetoothDiagnosticsScreen({super.key});

  @override
  _BluetoothDiagnosticsScreenState createState() =>
      _BluetoothDiagnosticsScreenState();
}

class _BluetoothDiagnosticsScreenState
    extends State<BluetoothDiagnosticsScreen> {
  final NetworkingService _networkingService = NetworkingService();
  String _bluetoothStatus = 'Checking...';
  final List<String> _diagnosticResults = [];
  bool _isRunningDiagnostics = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  @override
  void dispose() {
    // Cancel any ongoing operations
    super.dispose();
  }

  void _runDiagnostics() async {
    if (!mounted) return; // Check if widget is still mounted

    setState(() {
      _isRunningDiagnostics = true;
      _diagnosticResults.clear();
    });

    try {
      // Check Bluetooth support
      _addResult('Checking Bluetooth support...');
      final bluetoothService = _networkingService.bluetoothService;
      final status = await bluetoothService.getBluetoothStatus();

      if (!mounted) return; // Check again after async operation

      setState(() {
        _bluetoothStatus = status;
      });
      _addResult('Bluetooth status: $status');

      // Try to initialize
      _addResult('Attempting to initialize Bluetooth...');
      final initialized = await bluetoothService.initialize();

      if (!mounted) return; // Check again after async operation

      _addResult(
        'Bluetooth initialization: ${initialized ? 'SUCCESS' : 'FAILED'}',
      );

      if (initialized) {
        // Try scanning
        _addResult('Attempting to scan for devices...');
        await bluetoothService.startScanning();

        if (!mounted) return; // Check before delay

        await Future.delayed(Duration(seconds: 5));

        if (!mounted) return; // Check after delay

        final devices = bluetoothService.discoveredDevices;
        _addResult('Found ${devices.length} devices');

        for (var device in devices) {
          if (!mounted) return; // Check during loop
          _addResult(
            '  - ${device.platformName.isNotEmpty ? device.platformName : 'Unknown'} (${device.remoteId})',
          );
        }
      }

      _addResult('Diagnostics completed');
    } catch (e) {
      if (mounted) {
        _addResult('ERROR: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isRunningDiagnostics = false;
      });
    }
  }

  void _addResult(String result) {
    if (mounted) {
      setState(() {
        _diagnosticResults.add(
          '[${DateTime.now().toString().substring(11, 19)}] $result',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Diagnostics'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isRunningDiagnostics ? null : _runDiagnostics,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bluetooth Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _bluetoothStatus == 'Ready'
                              ? Icons.check_circle
                              : Icons.error,
                          color:
                              _bluetoothStatus == 'Ready'
                                  ? Colors.green
                                  : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(_bluetoothStatus),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Diagnostic Log',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (_isRunningDiagnostics)
              Center(child: CircularProgressIndicator()),
            Expanded(
              child: Card(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          _diagnosticResults
                              .map(
                                (result) => Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    result,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
