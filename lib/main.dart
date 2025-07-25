import 'package:flutter/material.dart';
import 'screens/settings_screen.dart';
import 'services/networking_service.dart';
import 'providers/theme_provider.dart';

// Global theme provider instance
final themeProvider = ThemeProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeProvider.initializeTheme();
  runApp(TongApp());
}

class TongApp extends StatefulWidget {
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
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tong Messenger')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40), // Add top spacing
              Icon(Icons.forum, size: 64, color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Welcome to Tong',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Advanced Multi-Network Messaging',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Your messaging app is ready!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '✓ Anonymous Identity System\n'
                        '✓ Multi-Network Messaging\n'
                        '✓ Chat Spaces & Forums\n'
                        '✓ Encrypted Communication\n'
                        '✓ Offline Message Storage',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MessagingScreen()),
                  );
                },
                icon: Icon(Icons.chat),
                label: Text('Start Messaging'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              SizedBox(height: 40), // Add bottom spacing for scrolling
            ],
          ),
        ),
      ),
    );
  }
}

class MessagingScreen extends StatefulWidget {
  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];
  final NetworkingService _networkingService = NetworkingService();
  String _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
  String _userName = 'Anonymous User';

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
      if (networkMessage.senderId != _currentUserId) {
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
    if (_messageController.text.trim().isNotEmpty) {
      final messageText = _messageController.text.trim();
      final networkMessage = NetworkMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        senderName: _userName,
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
    final localIP = await _networkingService.getLocalIPAddress();

    showDialog(
      context: context,
      builder: (context) {
        String targetIP = '';
        return AlertDialog(
          title: Text('Connect to Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your IP Address: ${localIP ?? 'Unknown'}'),
              SizedBox(height: 16),
              Text(
                'Share this IP with other users so they can connect to you.',
              ),
              SizedBox(height: 16),
              Text('Or enter an IP address to connect to:'),
              SizedBox(height: 8),
              TextField(
                onChanged: (value) => targetIP = value,
                decoration: InputDecoration(
                  hintText: 'e.g., 192.168.1.100',
                  border: OutlineInputBorder(),
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
              onPressed: () async {
                if (targetIP.trim().isNotEmpty) {
                  Navigator.pop(context);
                  final success = await _networkingService.connectToDevice(
                    targetIP.trim(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Connected!' : 'Connection failed',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _networkingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tong Messenger'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
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
                                  'You',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'You',
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
