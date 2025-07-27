// Quick test app to verify local authentication is working
// Run this with: flutter run --target lib/test_auth.dart

import 'package:flutter/material.dart';
import 'services/local_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local auth service
  try {
    await LocalAuthService().initialize();
    print('Local auth service initialized successfully');
  } catch (e) {
    print('Auth service initialization failed: $e');
  }

  runApp(TestAuthApp());
}

class TestAuthApp extends StatelessWidget {
  const TestAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Auth App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TestAuthScreen(),
    );
  }
}

class TestAuthScreen extends StatefulWidget {
  const TestAuthScreen({super.key});

  @override
  _TestAuthScreenState createState() => _TestAuthScreenState();
}

class _TestAuthScreenState extends State<TestAuthScreen> {
  final LocalAuthService _authService = LocalAuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  String _status = 'Ready to test authentication';

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    setState(() {
      if (_authService.isLoggedIn) {
        _status = 'Logged in as: ${_authService.currentUser?.displayName}';
      } else {
        _status = 'Not logged in';
      }
    });
  }

  Future<void> _testRegister() async {
    setState(() {
      _status = 'Registering...';
    });

    final error = await _authService.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );

    setState(() {
      if (error == null) {
        _status = 'Registration successful!';
      } else {
        _status = 'Registration failed: $error';
      }
    });
  }

  Future<void> _testLogin() async {
    setState(() {
      _status = 'Signing in...';
    });

    final error = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() {
      if (error == null) {
        _status = 'Sign in successful!';
      } else {
        _status = 'Sign in failed: $error';
      }
    });
  }

  Future<void> _testLogout() async {
    await _authService.signOut();
    setState(() {
      _status = 'Signed out';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Local Authentication'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  _status,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testRegister,
              child: Text('Test Register'),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _testLogin, child: Text('Test Sign In')),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testLogout,
              child: Text('Test Sign Out'),
            ),
            SizedBox(height: 20),
            if (_authService.currentUser != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current User:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('ID: ${_authService.currentUser!.id}'),
                      Text('Email: ${_authService.currentUser!.email}'),
                      Text('Name: ${_authService.currentUser!.displayName}'),
                      Text('Created: ${_authService.currentUser!.createdAt}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
