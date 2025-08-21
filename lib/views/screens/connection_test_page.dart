import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/services/supabase_auth_service.dart';

class ConnectionTestPage extends StatefulWidget {
  const ConnectionTestPage({super.key});

  @override
  _ConnectionTestPageState createState() => _ConnectionTestPageState();
}

class _ConnectionTestPageState extends State<ConnectionTestPage> {
  String _connectionStatus = 'Testing...';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _connectionStatus = 'Testing connection...';
    });

    try {
      // Test 1: Check if Supabase is initialized
      final client = Supabase.instance.client;
      setState(() {
        _connectionStatus = 'Supabase client initialized ✓\n';
      });

      // Test 2: Test basic connection
      final isConnected = await SupabaseAuthService.testConnection();
      
      if (isConnected) {
        setState(() {
          _connectionStatus += 'Database connection successful ✓\n';
          _isConnected = true;
        });
      } else {
        setState(() {
          _connectionStatus += 'Database connection failed ✗\n';
        });
      }

      // Test 3: Check auth configuration
      try {
        await client.auth.getUser();
        setState(() {
          _connectionStatus += 'Auth service accessible ✓\n';
        });
      } catch (e) {
        setState(() {
          _connectionStatus += 'Auth service error: $e\n';
        });
      }

    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection test failed: $e';
      });
    }
  }

  Future<void> _testSignup() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection not established. Fix connection first.')),
      );
      return;
    }

    try {
      final response = await SupabaseAuthService.signUpWithEmailAndPassword(
        email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'testpassword123',
        displayName: 'Test User',
      );

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test signup successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test signup failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connection Test'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supabase Configuration',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('URL: ${SupabaseConfig.supabaseUrl}'),
                    Text('Anon Key: ${SupabaseConfig.supabaseAnonKey.substring(0, 20)}...'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(_connectionStatus),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _testConnection,
                  child: Text('Retest Connection'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _testSignup,
                  child: Text('Test Signup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
