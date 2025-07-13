import 'package:flutter/material.dart';
import '../services/app_initialization_service.dart';
import '../services/connection_test_service.dart';
import '../services/socket_service.dart';

class ConnectionStatusWidget extends StatefulWidget {
  const ConnectionStatusWidget({super.key});

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  bool _isConnected = false;
  bool _isSocketConnected = false;
  bool _isLoading = false;
  Map<String, dynamic>? _connectionDetails;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();

    // Listen to socket connection changes
    SocketService.instance.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isSocketConnected = connected;
        });
      }
    });
  }

  Future<void> _checkConnectionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = AppInitializationService.getStatus();
      final connectionTest = await ConnectionTestService.testConnection();

      setState(() {
        _isConnected = connectionTest;
        _isSocketConnected = SocketService.instance.isConnected;
        _connectionDetails = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _reconnect() async {
    setState(() {
      _isLoading = true;
    });

    final success = await AppInitializationService.reinitialize();

    setState(() {
      _isConnected = success;
      _isSocketConnected = SocketService.instance.isConnected;
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reconnected to backend successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to reconnect to backend'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Backend Connection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _checkConnectionStatus,
                    tooltip: 'Refresh connection status',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Backend API', _isConnected),
            _buildStatusRow('Socket Connection', _isSocketConnected),
            const SizedBox(height: 12),
            if (_connectionDetails != null) ...[
              Text(
                'Backend URL: ${_connectionDetails!['backendInfo']['baseUrl']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Socket URL: ${_connectionDetails!['backendInfo']['socketUrl']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _reconnect,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reconnect'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _showConnectionDetails,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectionDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_connectionDetails != null) ...[
                _buildDetailRow(
                  'App Initialized',
                  _connectionDetails!['isInitialized'],
                ),
                _buildDetailRow('Backend Connected', _isConnected),
                _buildDetailRow('Socket Connected', _isSocketConnected),
                const Divider(),
                const Text(
                  'Backend Configuration:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._connectionDetails!['backendInfo'].entries
                    .map<Widget>(
                      (entry) => _buildDetailRow(entry.key, entry.value),
                    )
                    .toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$key:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
