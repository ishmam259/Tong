import 'package:flutter/material.dart';
import 'dart:io'; // For Platform detection
import 'screens/settings_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/unsupported_platform_screen.dart';
import 'services/networking_service.dart';
import 'services/local_auth_service.dart'; // Changed to local auth
import 'providers/theme_provider.dart';

// Global theme provider instance
final themeProvider = ThemeProvider();
// Global auth service instance
final authService = LocalAuthService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check platform support - only Android, iOS, and Windows are supported
  if (!Platform.isAndroid && !Platform.isIOS && !Platform.isWindows) {
    print('WARNING: Unsupported platform detected.');
    print('Tong Messenger is designed for Android, iOS, and Windows only.');

    // Show unsupported platform screen
    runApp(UnsupportedPlatformScreen());
    return;
  }

  // Note: Firebase is disabled for development
  // To enable Firebase, create a project and configure firebase_options.dart

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
      theme: themeProvider.currentTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapperScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => MessagingScreen(),
        '/settings': (context) => SettingsScreen(),
        '/bluetooth_diagnostics':
            (context) =>
                BluetoothDiagnosticsScreen(), // Add route for Bluetooth diagnostics
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}

class AuthWrapperScreen extends StatelessWidget {
  const AuthWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authService,
      builder: (context, child) {
        if (authService.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tong',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
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
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),

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
  final List<String> _messages = [];
  final NetworkingService _networkingService = NetworkingService();

  @override
  void initState() {
    super.initState();
    _setupNetworking();
  }

  void _setupNetworking() async {
    // Initialize networking services including Bluetooth
    await _networkingService.initializeNetworking();

    _networkingService.setMessageHandler((messageData) {
      final networkMessage = NetworkMessage.fromJson(messageData);
      final currentUser = authService.currentUser;
      if (currentUser != null && networkMessage.senderId != currentUser.id) {
        setState(() {
          _messages.add(
            '${networkMessage.senderName}: ${networkMessage.content}',
          );
        });
      }
    });

    // Start server by default
    _networkingService.startServer();
  }

  void _sendMessage() {
    final currentUser = authService.currentUser;
    if (_messageController.text.trim().isNotEmpty && currentUser != null) {
      final messageText = _messageController.text.trim();
      final networkMessage = NetworkMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: currentUser.id,
        senderName: currentUser.displayName,
        content: messageText,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add('You: $messageText');
        _messageController.clear();
      });

      // Send over network
      _networkingService.sendMessage(networkMessage.toJson());
    }
  }

  void _showConnectionDialog() async {
    // Capture parent context to use for navigation and snack bars
    final parentContext = context;

    String selectedType = 'All';
    showDialog(
      context: parentContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Connect to Device'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transport selection chips
                  Wrap(
                    spacing: 8,
                    children:
                        ['All', 'Bluetooth', 'WiFi'].map((type) {
                          final isSelected = selectedType == type;
                          return ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                selectedType = type;
                              });
                            },
                          );
                        }).toList(),
                  ),
                  Text(
                    'Searching for nearby devices...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Available devices will appear here:',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    width: double.maxFinite,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _networkingService.discoverDevices(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Discovering devices...'),
                              ],
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                SizedBox(height: 8),
                                Text('Discovery failed'),
                              ],
                            ),
                          );
                        }

                        var devices = snapshot.data ?? [];
                        if (selectedType != 'All') {
                          devices =
                              devices
                                  .where((d) => d['type'] == selectedType)
                                  .toList();
                        }

                        if (devices.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.devices_other, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('No devices found'),
                                SizedBox(height: 4),
                                Text(
                                  'Make sure Bluetooth and WiFi are enabled',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            final device = devices[index];
                            return ListTile(
                              leading: Icon(
                                device['type'] == 'Bluetooth'
                                    ? Icons.bluetooth
                                    : Icons.wifi,
                                color:
                                    device['type'] == 'Bluetooth'
                                        ? Colors.blue
                                        : Colors.green,
                              ),
                              title: Text(device['name'] ?? 'Unknown Device'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${device['type']} • ${device['signal']}',
                                  ),
                                  if (device['type'] == 'Bluetooth')
                                    Text(
                                      'Tap to connect via Bluetooth',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[600],
                                      ),
                                    )
                                  else
                                    Text(
                                      'Tap to connect via WiFi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[600],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () async {
                                // Close discovery dialog using parent context
                                Navigator.pop(parentContext);

                                // Show connecting dialog on parent context
                                showDialog(
                                  context: parentContext,
                                  barrierDismissible: false,
                                  builder:
                                      (context) => AlertDialog(
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(height: 16),
                                            Text(
                                              'Connecting to ${device['name']}...',
                                            ),
                                          ],
                                        ),
                                      ),
                                );

                                final success = await _networkingService
                                    .connectToDiscoveredDevice(device);

                                // Close connecting dialog
                                Navigator.pop(parentContext);

                                // Show result using parent context's ScaffoldMessenger
                                ScaffoldMessenger.of(
                                  parentContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Connected to ${device['name']}!'
                                          : 'Failed to connect to ${device['name']}',
                                    ),
                                    backgroundColor:
                                        success ? Colors.green : Colors.red,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Restart discovery
                    _showConnectionDialog();
                  },
                  child: Text('Refresh'),
                ),
              ],
            );
          },
        );
      },
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tong Messenger'),
            if (currentUser != null)
              Text(
                'Welcome, ${currentUser.displayName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder:
                (context) => [
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
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                color:
                    _networkingService.isConnected
                        ? Colors.green[100]
                        : Colors.orange[100],
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color:
                          _networkingService.isConnected
                              ? Colors.green
                              : Colors.orange,
                      size: 12,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _networkingService.isConnected
                            ? 'Connected to ${_networkingService.connectedPeers.length} device(s)'
                            : 'Waiting for connections...',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              _networkingService.isConnected
                                  ? Colors.green[800]
                                  : Colors.orange[800],
                        ),
                      ),
                    ),
                    if (!_networkingService.isConnected)
                      TextButton(
                        onPressed: _showConnectionDialog,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(
                          'Connect',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                  ],
                ),
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
                          SizedBox(height: 8),
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
                      padding: EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue,
                                child: Text(
                                  currentUser?.displayName
                                          .substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _messages[index].startsWith('You:')
                                          ? currentUser?.displayName ?? 'You'
                                          : _messages[index].split(':')[0],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(_messages[index]),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
          // Message input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
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
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _sendMessage,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
