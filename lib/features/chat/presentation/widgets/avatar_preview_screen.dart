import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/avatar_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'user_avatar.dart';

/// Screen to preview and test the avatar system
class AvatarPreviewScreen extends ConsumerWidget {
  const AvatarPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testAvatars = AvatarService.generateTestAvatars();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar System Preview'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avatar System Features',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('✅ Deterministic colors based on user ID'),
                    const Text('✅ First & last name initials (e.g., John Doe → JD)'),
                    const Text('✅ Consistent colors across sessions'),
                    const Text('✅ Automatic contrast adjustment'),
                    const Text('✅ Fallback for missing profile photos'),
                    const Text('✅ Multiple size support'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Size variations
            Text(
              'Size Variations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        UserAvatar(
                          name: 'John Doe',
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        const Text('24px', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        UserAvatar(
                          name: 'Alice Smith',
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text('32px', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        UserAvatar(
                          name: 'Bob Johnson',
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        const Text('48px', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        UserAvatar(
                          name: 'Sarah Wilson',
                          size: 64,
                        ),
                        const SizedBox(height: 8),
                        const Text('64px', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        UserAvatar(
                          name: 'Mike Davis',
                          size: 80,
                        ),
                        const SizedBox(height: 8),
                        const Text('80px', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test avatars grid
            Text(
              'Test Users (Consistent Colors)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Each user gets the same color every time based on their ID',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: testAvatars.length,
              itemBuilder: (context, index) {
                final entry = testAvatars.entries.elementAt(index);
                final name = entry.key;
                final avatarData = entry.value;
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        UserAvatar(
                          name: name,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                avatarData.initials,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Color palette
            Text(
              'Available Color Palette',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AvatarService.getColorPalette().map((color) {
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            color: AvatarService.getContrastingTextColor(color),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Edge cases
            Text(
              'Edge Cases & Special Names',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildEdgeCaseRow('Single Name', 'Madonna'),
                    _buildEdgeCaseRow('Empty String', ''),
                    _buildEdgeCaseRow('Multiple Names', 'Jean-Claude Van Damme'),
                    _buildEdgeCaseRow('Special Characters', 'José María'),
                    _buildEdgeCaseRow('Numbers', 'User123'),
                    _buildEdgeCaseRow('Symbols', '@user_name'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEdgeCaseRow(String label, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          UserAvatar(
            name: name,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  name.isEmpty ? '(empty)' : name,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AvatarService.getInitials(name),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show avatar preview
void showAvatarPreview(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const AvatarPreviewScreen(),
    ),
  );
}