import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/enhanced_auth_service.dart';
import '../services/auth_debug_helper.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Debug widget to check and fix authentication issues
class AuthDebugWidget extends ConsumerStatefulWidget {
  const AuthDebugWidget({super.key});

  @override
  ConsumerState<AuthDebugWidget> createState() => _AuthDebugWidgetState();
}

class _AuthDebugWidgetState extends ConsumerState<AuthDebugWidget> {
  Map<String, dynamic>? _debugInfo;
  bool _isLoading = false;
  String? _lastAction;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final info = await EnhancedAuthService.getAuthDebugInfo();
      setState(() {
        _debugInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshToken() async {
    setState(() {
      _isLoading = true;
      _lastAction = 'Refreshing token...';
    });

    try {
      final success = await EnhancedAuthService.forceRefreshToken();
      setState(() {
        _lastAction = success
            ? '✅ Token refreshed successfully!'
            : '❌ Token refresh failed';
      });
      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _lastAction = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testAuthCall() async {
    setState(() {
      _isLoading = true;
      _lastAction = 'Testing authenticated call...';
    });

    try {
      final success = await EnhancedAuthService.testAuthenticatedCall();
      setState(() {
        _lastAction = success
            ? '✅ Authenticated call successful!'
            : '❌ Authenticated call failed';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _lastAction = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _forceLogout() async {
    setState(() {
      _isLoading = true;
      _lastAction = 'Logging out...';
    });

    try {
      await ref.read(authProvider.notifier).logout();
      setState(() {
        _lastAction = '✅ Logged out successfully!';
      });
      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _lastAction = '❌ Logout error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _runFullDiagnostic() async {
    setState(() {
      _isLoading = true;
      _lastAction = 'Running full diagnostic...';
    });

    try {
      await AuthDebugHelper.runFullDiagnostic();
      setState(() {
        _lastAction = '✅ Full diagnostic completed! Check Flutter console';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _lastAction = '❌ Diagnostic error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _quickFix() async {
    setState(() {
      _isLoading = true;
      _lastAction = 'Running quick fix...';
    });

    try {
      await AuthDebugHelper.quickFix();
      setState(() {
        _lastAction = '✅ Quick fix completed! Check console';
        _isLoading = false;
      });
      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _lastAction = '❌ Quick fix error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testMessageEndpoint() async {
    setState(() {
      _isLoading = true;
      _lastAction = 'Testing message endpoint...';
    });

    try {
      await AuthDebugHelper.testSpecificEndpoint(
        '/api/messages/685bf28e186eda90af89be6e',
        method: 'POST',
        data: {'content': 'test'},
      );
      setState(() {
        _lastAction = '✅ Message endpoint test completed! Check console';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _lastAction = '❌ Message endpoint test error: $e';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Auth State
                  _buildSection('Current Auth State', [
                    'Authenticated: ${authState.isAuthenticated}',
                    'Loading: ${authState.isLoading}',
                    'User: ${authState.user?.username ?? 'None'}',
                    'Error: ${authState.error ?? 'None'}',
                  ]),

                  const SizedBox(height: 20),

                  // Last Action
                  if (_lastAction != null) ...[
                    _buildSection('Last Action', [_lastAction!]),
                    const SizedBox(height: 20),
                  ],

                  // Debug Info
                  if (_debugInfo != null) ...[
                    _buildSection('Token Status', [
                      'Status: ${_debugInfo!['token_status'] ?? 'Unknown'}',
                      'Has Access Token: ${_debugInfo!['has_access_token']}',
                      'Has Refresh Token: ${_debugInfo!['has_refresh_token']}',
                      'User ID: ${_debugInfo!['user_id'] ?? 'None'}',
                      if (_debugInfo!['token_expiry'] != null)
                        'Token Expires: ${_debugInfo!['token_expiry']}',
                    ]),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  _buildSection(
                    'Actions',
                    [],
                    children: [
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.bug_report),
                            label: const Text('Full Diagnostic'),
                            onPressed: _runFullDiagnostic,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.build),
                            label: const Text('Quick Fix'),
                            onPressed: _quickFix,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.message),
                            label: const Text('Test Message API'),
                            onPressed: _testMessageEndpoint,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Token'),
                            onPressed: _refreshToken,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.security),
                            label: const Text('Test Auth Call'),
                            onPressed: _testAuthCall,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.logout),
                            label: const Text('Force Logout'),
                            onPressed: _forceLogout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Raw Debug Data
                  if (_debugInfo != null) ...[
                    _buildSection(
                      'Raw Debug Data',
                      [],
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Debug Info:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: const Text('Copy'),
                                    onPressed: () =>
                                        _copyToClipboard(_debugInfo.toString()),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                _formatDebugInfo(_debugInfo!),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Instructions
                  _buildSection('Fix Instructions', [
                    '1. If token is expired, tap "Refresh Token"',
                    '2. If refresh fails, tap "Force Logout" and login again',
                    '3. If issues persist, check backend logs',
                    '4. Ensure backend /auth/refresh endpoint is working',
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(
    String title,
    List<String> items, {
    List<Widget> children = const [],
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  String _formatDebugInfo(Map<String, dynamic> info) {
    final buffer = StringBuffer();
    for (final entry in info.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    return buffer.toString();
  }
}

/// Quick access floating action button for auth debug
class AuthDebugFab extends StatelessWidget {
  const AuthDebugFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.orange,
      child: const Icon(Icons.bug_report),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AuthDebugWidget()),
        );
      },
    );
  }
}
