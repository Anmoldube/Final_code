import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/user_files_section.dart';

class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Files'),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            UserFilesSection(),
          ],
        ),
      ),
    );
  }
}