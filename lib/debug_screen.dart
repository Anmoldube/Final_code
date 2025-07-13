import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/widgets/auth_debug_widget.dart';
import 'core/services/auth_debug_helper.dart';
import 'core/services/chat_debug_helper.dart';
import 'core/services/realtime_message_tester.dart';

/// Quick debug screen for testing authentication
class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Authentication'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Authentication Fix',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This screen helps diagnose and fix authentication issues.\n'
                      'Check the Flutter console for detailed logs.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.bug_report),
              label: const Text('Run Full Diagnostic'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Running diagnostic... Check Flutter console',
                    ),
                  ),
                );
                await AuthDebugHelper.runFullDiagnostic();
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble),
              label: const Text('Chat System Diagnostic'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Running chat diagnostic... Check Flutter console',
                    ),
                  ),
                );
                await ChatDebugHelper.runFullChatDiagnostic();
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.build),
              label: const Text('Auto Fix Chat Issues'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Auto-fixing chat issues... Check Flutter console',
                    ),
                  ),
                );
                await ChatDebugHelper.autoFixChatIssues();
              },
            ),
            const SizedBox(height: 20),
            // Real-time messaging tests
            Text(
              'Real-time Messaging Tests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.speed_outlined),
              label: const Text('Complete Message Flow Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Testing complete message flow... Check Flutter console',
                    ),
                  ),
                );
                await RealtimeMessageTester.testCompleteMessageFlow();
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Quick Socket Check'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Socket check... Check Flutter console'),
                  ),
                );
                RealtimeMessageTester.quickSocketCheck();
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.security),
              label: const Text('Test Chat Ownership'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Testing chat ownership... Check Flutter console',
                    ),
                  ),
                );
                await RealtimeMessageTester.testChatOwnership(
                  '685bf28e186eda90af89be6e', // Your problematic chat ID
                );
              },
            ),
            const SizedBox(height: 20),
            // Legacy tests
            Text(
              'Legacy Tests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.message),
              label: const Text('Test Message Endpoint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Testing endpoint... Check Flutter console'),
                  ),
                );
                await AuthDebugHelper.testSpecificEndpoint(
                  '/api/messages/685bf28e186eda90af89be6e',
                  method: 'POST',
                  data: {'content': 'Debug test message'},
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text('Test Chat Endpoint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Testing chat endpoint... Check Flutter console',
                    ),
                  ),
                );
                await AuthDebugHelper.testSpecificEndpoint(
                  '/api/chat/c/685bf289186eda90af89be61',
                  method: 'POST',
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Open Detailed Debug Widget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AuthDebugWidget(),
                  ),
                );
              },
            ),
            const Spacer(),
            const Card(
              color: Colors.yellow,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '⚠️ Important: Watch the Flutter console/terminal for detailed diagnostic information!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add this as a floating action button to any screen for quick access
class QuickDebugFab extends StatelessWidget {
  const QuickDebugFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.red,
      child: const Icon(Icons.bug_report, color: Colors.white),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DebugScreen()),
        );
      },
    );
  }
}
