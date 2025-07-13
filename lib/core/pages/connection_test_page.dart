import 'package:flutter/material.dart';
import '../widgets/connection_status_widget.dart';
import '../services/connection_test_service.dart';
import '../services/storage_service.dart';
import '../../features/auth/data/datasources/auth_api_service.dart';

class ConnectionTestPage extends StatefulWidget {
  const ConnectionTestPage({super.key});

  @override
  State<ConnectionTestPage> createState() => _ConnectionTestPageState();
}

class _ConnectionTestPageState extends State<ConnectionTestPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _testResult;
  Map<String, dynamic>? _fullTestResults;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _runFullConnectionTest() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      final token = await StorageService.getAccessToken();
      final results = await ConnectionTestService.runFullConnectionTest(
        token: token,
      );

      setState(() {
        _fullTestResults = results;
        _testResult = 'Connection test completed. Check details below.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Connection test failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      final authService = AuthApiService();
      final response = await authService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await StorageService.saveAccessToken(data['accessToken']);
        if (data['refreshToken'] != null) {
          await StorageService.saveRefreshToken(data['refreshToken']);
        }

        setState(() {
          _testResult = '✅ Login successful! Token saved.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _testResult = '❌ Login failed: ${response.statusMessage}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ Login error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testRegister() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      final authService = AuthApiService();
      final response = await authService.register(
        firstName: 'Test',
        lastName: 'User',
        username: _emailController.text.split('@')[0],
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.statusCode == 201) {
        setState(() {
          _testResult = '✅ Registration successful!';
          _isLoading = false;
        });
      } else {
        setState(() {
          _testResult = '❌ Registration failed: ${response.statusMessage}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ Registration error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Connection Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ConnectionStatusWidget(),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Connection Tests',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _runFullConnectionTest,
                      icon: const Icon(Icons.network_check),
                      label: const Text('Run Full Connection Test'),
                    ),
                    const SizedBox(height: 12),
                    if (_fullTestResults != null) ...[
                      const Divider(),
                      const Text(
                        'Test Results:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._buildTestResults(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Authentication Test',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testLogin,
                            icon: const Icon(Icons.login),
                            label: const Text('Test Login'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _testRegister,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Test Register'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_testResult != null)
              Card(
                color: _testResult!.contains('✅')
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Result:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(_testResult!),
                    ],
                  ),
                ),
              ),
            if (_isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Running test...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTestResults() {
    if (_fullTestResults == null) return [];

    final results = <Widget>[];

    _fullTestResults!.forEach((key, value) {
      if (value is bool) {
        results.add(_buildResultRow(key, value));
      } else if (value is Map) {
        results.add(
          ExpansionTile(
            title: Text(key),
            children: value.entries
                .map<Widget>(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _buildResultRow(entry.key, entry.value),
                  ),
                )
                .toList(),
          ),
        );
      }
    });

    return results;
  }

  Widget _buildResultRow(String key, dynamic value) {
    final isSuccess = value == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(key)),
          Text(
            value.toString(),
            style: TextStyle(
              color: isSuccess ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
