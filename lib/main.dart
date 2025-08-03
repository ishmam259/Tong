import 'package:flutter/material.dart';
import 'dart:io'; // For Platform detection
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/settings_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/unsupported_platform_screen.dart';
import 'screens/device_discovery_screen.dart';
import 'services/networking_service.dart';
import 'services/firebase_auth_service.dart'; // Changed to Firebase auth
import 'services/bluetooth_service.dart'; // Import bluetooth service
import 'services/permission_service.dart'; // Import permission service
import 'providers/theme_provider.dart';
import 'core/theme/premium_theme.dart';
import 'widgets/premium_chat_widgets.dart';
import 'widgets/tong_logo.dart';
import 'models/chat_message.dart';
// import 'dart:typed_data'; // Removed unused import
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart'; // Import for DiscoveredDevice

// Global theme provider instance
final themeProvider = ThemeProvider();
// Global Firebase auth service instance
final authService = FirebaseAuthService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check platform support - only Android, iOS, and Windows are supported
  if (!Platform.isAndroid && !Platform.isIOS && !Platform.isWindows) {
    print('WARNING: Unsupported platform detected.');
    print('Tong Messenger is designed for Android, iOS, and Windows only.');

    // Show unsupported platform screen
    runApp(UnsupportedPlatformScreen());
    return;
  }

  // Initialize theme
  await themeProvider.initializeTheme();

  // Initialize local auth service (no Firebase required)
  try {
    await authService.initialize();
  } catch (e) {
    print('Local auth service initialization failed: $e');
  }

  runApp(TongApp());
}

class TongApp extends StatefulWidget {
  const TongApp({super.key});

  @override
  _TongAppState createState() => _TongAppState();
}

class _TongAppState extends State<TongApp> {
  @override
  void initState() {
    super.initState();
    themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tong Messenger',
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: PremiumTheme.lightTheme(),
      darkTheme: PremiumTheme.darkTheme(),
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapperScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => MessagingScreen(),
        '/settings': (context) => SettingsScreen(),
        '/device_discovery': (context) => DeviceDiscoveryScreen(),
        '/bluetooth_diagnostics':
            (context) =>
                BluetoothDiagnosticsScreen(), // Add route for Bluetooth diagnostics
        '/profile': (context) => ProfileScreen(),
        '/bluetooth_chat':
            (context) => BluetoothChatScreen(), // Add route for Bluetooth chat
      },
    );
  }
}

class AuthWrapperScreen extends StatefulWidget {
  const AuthWrapperScreen({super.key});

  @override
  State<AuthWrapperScreen> createState() => _AuthWrapperScreenState();
}

class _AuthWrapperScreenState extends State<AuthWrapperScreen> {
  bool _permissionsChecked = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsOnStartup();
  }

  Future<void> _checkPermissionsOnStartup() async {
    // Only check permissions on mobile platforms
    if (Platform.isAndroid || Platform.isIOS) {
      final permissionService = PermissionService();
      await permissionService.requestAllPermissions();
    }

    setState(() {
      _permissionsChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsChecked) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedTongLogo(size: 120, showText: true),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Setting up Tong...'),
            ],
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: authService,
      builder: (context, child) {
        if (authService.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedTongLogo(size: 120, showText: true),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Loading...'),
                ],
              ),
            ),
          );
        }

        if (authService.isLoggedIn) {
          return MessagingScreen();
        } else {
          return WelcomeScreen();
        }
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              AnimatedTongLogo(size: 100, showText: true),
              const SizedBox(height: 32),

              Text(
                'Welcome to Tong',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Connect with your world',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Available on Android, iOS & Windows',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Advanced Multi-Network Messaging',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeatureItem(
                            context,
                            Icons.bluetooth,
                            'Bluetooth Discovery',
                            'Find nearby devices automatically',
                          ),
                          _buildFeatureItem(
                            context,
                            Icons.wifi,
                            'WiFi Mesh Networking',
                            'Connect devices on same network',
                          ),
                          _buildFeatureItem(
                            context,
                            Icons.security,
                            'No IP Addresses',
                            'Smart discovery without manual setup',
                          ),
                          _buildFeatureItem(
                            context,
                            Icons.offline_bolt,
                            'Offline Support',
                            'Works without internet connection',
                          ),
                          _buildFeatureItem(
                            context,
                            Icons.people,
                            'User Management',
                            'Secure local user profiles',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Sign up button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Login button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final NetworkingService _networkingService = NetworkingService();

  @override
  void initState() {
    super.initState();
    _setupNetworking();
  }

  void _setupNetworking() async {
    // Request permissions first
    final permissionService = PermissionService();
    final permissionsGranted = await permissionService.requestAllPermissions();

    if (!permissionsGranted) {
      // Show permission dialog
      if (mounted) {
        _showPermissionDialog();
      }
      return;
    }

    // Initialize networking services including Bluetooth
    await _networkingService.initializeNetworking();

    _networkingService.setMessageHandler((messageData) {
      final networkMessage = NetworkMessage.fromJson(messageData);
      final currentUser = authService.currentUser;
      if (currentUser != null && networkMessage.senderId != currentUser.uid) {
        setState(() {
          _messages.add(
            ChatMessage.fromNetworkMessage(networkMessage, currentUser.uid),
          );
        });
      }
    });

    // Start server by default
    _networkingService.startServer();
  }

  // void _sendMessage() {
  //   // This method is now replaced by the callback in PremiumMessageInput
  // }

  // void _showConnectionDialog() async {
  //   // This method is now replaced by navigation to DeviceDiscoveryScreen
  // }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.security, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Permissions Required',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tong needs the following permissions to work:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 16),
                  // Use Flexible to prevent overflow
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildPermissionItem(
                            Icons.bluetooth,
                            'Bluetooth',
                            'Connect to nearby devices',
                          ),
                          _buildPermissionItem(
                            Icons.location_on,
                            'Location',
                            'Find Bluetooth devices',
                          ),
                          _buildPermissionItem(
                            Icons.wifi,
                            'Nearby WiFi',
                            'Discover local devices',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'These permissions are essential for device discovery and messaging.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Show limited functionality message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Some features may not work without permissions',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _requestPermissionsAgain();
                },
                child: Text('Grant Permissions'),
              ),
            ],
          ),
    );
  }

  Future<void> _requestPermissionsAgain() async {
    final permissionService = PermissionService();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Requesting permissions...'),
              ],
            ),
          ),
    );

    // Request permissions
    final permissionsGranted = await permissionService.requestAllPermissions();

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    if (permissionsGranted) {
      // Permissions granted, continue with setup
      await _networkingService.initializeNetworking();
      _networkingService.setMessageHandler((messageData) {
        final networkMessage = NetworkMessage.fromJson(messageData);
        final currentUser = authService.currentUser;
        if (currentUser != null && networkMessage.senderId != currentUser.uid) {
          setState(() {
            _messages.add(
              ChatMessage.fromNetworkMessage(networkMessage, currentUser.uid),
            );
          });
        }
      });
      _networkingService.startServer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permissions granted! Tong is ready to use.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Permissions still denied, offer to open settings
      if (mounted) {
        _showOpenSettingsDialog();
      }
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Permissions Needed'),
            content: Text(
              'Some permissions were denied. Please enable them in Settings to use all features.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final permissionService = PermissionService();
                  await permissionService.openAppSettings();
                },
                child: Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await authService.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _networkingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            TongLogo(size: 32, showText: false),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tong'),
                if (currentUser != null)
                  Text(
                    'Welcome, ${currentUser.displayName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          // Connectivity status icon
          AnimatedBuilder(
            animation: _networkingService,
            builder: (context, child) {
              return IconButton(
                icon: Icon(
                  _networkingService.isConnected ? Icons.wifi : Icons.wifi_off,
                  color:
                      _networkingService.isConnected
                          ? Colors.green
                          : Colors.grey,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/device_discovery');
                },
                tooltip:
                    _networkingService.isConnected
                        ? 'Connected (${_networkingService.connectedPeers.length} devices)'
                        : 'Not connected - Tap to find devices',
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'connectivity':
                  Navigator.pushNamed(context, '/device_discovery');
                  break;
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'device_discovery':
                  Navigator.pushNamed(context, '/device_discovery');
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'connectivity',
                    child: ListTile(
                      leading: AnimatedBuilder(
                        animation: _networkingService,
                        builder: (context, child) {
                          return Icon(
                            _networkingService.isConnected
                                ? Icons.wifi
                                : Icons.wifi_off,
                            color:
                                _networkingService.isConnected
                                    ? Colors.green
                                    : Colors.grey,
                          );
                        },
                      ),
                      title: Text('Connectivity'),
                      subtitle: AnimatedBuilder(
                        animation: _networkingService,
                        builder: (context, child) {
                          return Text(
                            _networkingService.isConnected
                                ? '${_networkingService.connectedPeers.length} devices connected'
                                : 'Not connected',
                            style: TextStyle(fontSize: 12),
                          );
                        },
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Profile'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Settings'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'device_discovery',
                    child: ListTile(
                      leading: Icon(Icons.search),
                      title: Text('Find Devices'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Logout'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status
          AnimatedBuilder(
            animation: _networkingService,
            builder: (context, child) {
              return ConnectionStatusIndicator(
                isConnected: _networkingService.isConnected,
                connectedDevices: _networkingService.connectedPeers.length,
                connectionType:
                    _networkingService.isConnected ? 'WiFi/BT' : null,
              );
            },
          ),
          // Messages area
          Expanded(
            child:
                _messages.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TongLogo(size: 64, showText: false),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return PremiumChatBubble(
                          message: message.content,
                          sender: message.senderName,
                          timestamp: message.timestamp,
                          isMe: message.isMe,
                          isDelivered: message.isDelivered,
                          isRead: message.isRead,
                        );
                      },
                    ),
          ),
          // Message input
          PremiumMessageInput(
            onSendMessage: (message) {
              final currentUser = authService.currentUser;
              if (message.trim().isNotEmpty && currentUser != null) {
                final networkMessage = NetworkMessage(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  senderId: currentUser.uid,
                  senderName:
                      currentUser.displayName ??
                      currentUser.email ??
                      'Anonymous',
                  content: message.trim(),
                  timestamp: DateTime.now(),
                );

                setState(() {
                  _messages.add(
                    ChatMessage(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      content: message.trim(),
                      senderId: currentUser.uid,
                      senderName:
                          currentUser.displayName ??
                          currentUser.email ??
                          'Anonymous',
                      timestamp: DateTime.now(),
                      isMe: true,
                    ),
                  );
                });

                // Send over network
                _networkingService.sendMessage(networkMessage.toJson());
              }
            },
            onAttachment: () {
              // TODO: Implement file attachment
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File attachments coming soon!')),
              );
            },
            onVoiceNote: () {
              // TODO: Implement voice notes
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice notes coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class BluetoothChatScreen extends StatefulWidget {
  const BluetoothChatScreen({super.key});

  @override
  _BluetoothChatScreenState createState() => _BluetoothChatScreenState();
}

class _BluetoothChatScreenState extends State<BluetoothChatScreen> {
  final BluetoothService _bluetoothService = BluetoothService.instance;
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initializeBluetoothService();
  }

  Future<void> _initializeBluetoothService() async {
    await _bluetoothService.initialize();

    // Set up message handler
    _bluetoothService.setMessageHandler((messageData) {
      final message = messageData['content'] as String? ?? 'No content';
      final sender = messageData['senderName'] as String? ?? 'Unknown';
      setState(() {
        _messages.add('$sender: $message');
      });
    });

    // Listen for state changes
    _bluetoothService.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _bluetoothService.startScanning();
    });

    // Automatically stop scan after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _bluetoothService.stopScanning();
        });
      }
    });
  }

  void _connectToDevice(DiscoveredDevice device) async {
    setState(() {
      _isScanning = false;
      _bluetoothService.stopScanning();
    });

    final success = await _bluetoothService.connectToDeviceId(device.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Connected to ${device.name}'
              : 'Failed to connect to ${device.name}',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty ||
        !_bluetoothService.isConnected) {
      return;
    }

    final messageText = _messageController.text.trim();
    final message = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': 'local',
      'senderName': 'Me',
      'content': messageText,
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'text',
    };

    _bluetoothService.sendMessage(message);

    setState(() {
      _messages.add('Me: $messageText');
      _messageController.clear();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Chat'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text('Bluetooth Status'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scanning: ${_bluetoothService.isScanning}'),
                          Text('Connected: ${_bluetoothService.isConnected}'),
                          if (_bluetoothService.isConnected)
                            Text(
                              'Device ID: ${_bluetoothService.connectedDeviceId}',
                            ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status banner
          Container(
            color:
                _bluetoothService.isConnected
                    ? Colors.green[100]
                    : Colors.orange[100],
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.bluetooth,
                  color:
                      _bluetoothService.isConnected
                          ? Colors.green
                          : Colors.orange,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _bluetoothService.isConnected
                        ? 'Connected to device'
                        : 'Not connected to any device',
                    style: TextStyle(
                      color:
                          _bluetoothService.isConnected
                              ? Colors.green[800]
                              : Colors.orange[800],
                    ),
                  ),
                ),
                if (!_bluetoothService.isConnected)
                  TextButton(
                    onPressed: _startScan,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      _isScanning ? 'Scanning...' : 'Scan',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ),
              ],
            ),
          ),

          // Devices list if scanning
          if (_isScanning)
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Available Devices',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        _bluetoothService.discoveredDevices.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Scanning for devices...'),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount:
                                  _bluetoothService.discoveredDevices.length,
                              itemBuilder: (context, index) {
                                final device =
                                    _bluetoothService.discoveredDevices[index];
                                return ListTile(
                                  leading: Icon(Icons.bluetooth),
                                  title: Text(
                                    device.name.isNotEmpty
                                        ? device.name
                                        : 'Unknown Device',
                                  ),
                                  subtitle: Text('RSSI: ${device.rssi} dBm'),
                                  trailing: Icon(Icons.chevron_right),
                                  onTap: () => _connectToDevice(device),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),

          // Messages area
          Expanded(
            flex: _isScanning ? 1 : 2,
            child:
                _messages.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isFromMe = message.startsWith('Me:');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Align(
                            alignment:
                                isFromMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isFromMe
                                        ? Colors.blue[100]
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(message),
                            ),
                          ),
                        );
                      },
                    ),
          ),

          // Input area
          if (_bluetoothService.isConnected)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: _sendMessage,
                    child: Icon(Icons.send),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
