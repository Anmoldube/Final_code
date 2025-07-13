import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/file_service.dart';

class FileUploadProgress extends StatelessWidget {
  final String fileName;
  final double progress; // 0.0 to 1.0
  final int? fileSize;
  final VoidCallback? onCancel;
  final bool isCompleted;
  final bool hasError;
  final String? errorMessage;

  const FileUploadProgress({
    super.key,
    required this.fileName,
    required this.progress,
    this.fileSize,
    this.onCancel,
    this.isCompleted = false,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? Colors.red.withOpacity(0.3)
              : (isCompleted
                    ? Colors.green.withOpacity(0.3)
                    : Colors.transparent),
        ),
      ),
      child: Row(
        children: [
          // File icon
          _buildFileIcon(),

          const SizedBox(width: 12),

          // File info and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File name
                Text(
                  fileName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Progress or status
                _buildProgressIndicator(context, isDark),

                const SizedBox(height: 4),

                // File size and status text
                _buildStatusText(context, isDark),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Action button
          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildFileIcon() {
    IconData icon;
    Color color;

    if (hasError) {
      icon = Icons.error;
      color = Colors.red;
    } else if (isCompleted) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else {
      final extension = path.extension(fileName).toLowerCase();
      switch (extension) {
        case '.jpg':
        case '.jpeg':
        case '.png':
        case '.gif':
          icon = Icons.image;
          color = Colors.blue;
          break;
        case '.mp4':
        case '.avi':
        case '.mkv':
          icon = Icons.videocam;
          color = Colors.red;
          break;
        case '.mp3':
        case '.wav':
        case '.flac':
          icon = Icons.audiotrack;
          color = Colors.orange;
          break;
        case '.pdf':
          icon = Icons.picture_as_pdf;
          color = Colors.red;
          break;
        case '.doc':
        case '.docx':
          icon = Icons.description;
          color = Colors.blue;
          break;
        case '.zip':
        case '.rar':
          icon = Icons.archive;
          color = Colors.grey;
          break;
        default:
          icon = Icons.insert_drive_file;
          color = Colors.grey;
      }
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, bool isDark) {
    if (hasError) {
      return Container(
        height: 4,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    if (isCompleted) {
      return Container(
        height: 4,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark
                ? AppTheme.darkBackground
                : Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusText(BuildContext context, bool isDark) {
    String statusText;
    Color? textColor;

    if (hasError) {
      statusText = errorMessage ?? 'Upload failed';
      textColor = Colors.red;
    } else if (isCompleted) {
      statusText = 'Upload completed';
      textColor = Colors.green;
    } else {
      final percentage = (progress * 100).toInt();
      final sizeText = fileSize != null
          ? FileService.instance.formatFileSize(fileSize!)
          : '';
      statusText =
          'Uploading... $percentage%${sizeText.isNotEmpty ? ' • $sizeText' : ''}';
      textColor = isDark
          ? AppTheme.darkTextSecondary
          : AppTheme.lightTextSecondary;
    }

    return Text(
      statusText,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (hasError) {
      return IconButton(
        icon: const Icon(Icons.refresh, size: 20),
        onPressed: onCancel, // Could be onRetry instead
        color: Colors.orange,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      );
    }

    if (isCompleted) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.close, size: 20),
      onPressed: onCancel,
      color: Colors.grey,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}

// Widget for multiple file uploads
class MultipleFileUploadProgress extends StatelessWidget {
  final List<FileUploadProgressItem> files;
  final VoidCallback? onCancelAll;

  const MultipleFileUploadProgress({
    super.key,
    required this.files,
    this.onCancelAll,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppTheme.darkDividerColor
                      : AppTheme.lightDividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_upload, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Uploading ${files.length} file${files.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onCancelAll != null) ...[
                  TextButton(
                    onPressed: onCancelAll,
                    child: const Text('Cancel All'),
                  ),
                ],
              ],
            ),
          ),

          // File list
          Column(
            children: files.map((file) {
              return FileUploadProgress(
                fileName: file.fileName,
                progress: file.progress,
                fileSize: file.fileSize,
                onCancel: file.onCancel,
                isCompleted: file.isCompleted,
                hasError: file.hasError,
                errorMessage: file.errorMessage,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Data model for file upload progress
class FileUploadProgressItem {
  final String fileName;
  final double progress;
  final int? fileSize;
  final VoidCallback? onCancel;
  final bool isCompleted;
  final bool hasError;
  final String? errorMessage;

  FileUploadProgressItem({
    required this.fileName,
    required this.progress,
    this.fileSize,
    this.onCancel,
    this.isCompleted = false,
    this.hasError = false,
    this.errorMessage,
  });

  FileUploadProgressItem copyWith({
    String? fileName,
    double? progress,
    int? fileSize,
    VoidCallback? onCancel,
    bool? isCompleted,
    bool? hasError,
    String? errorMessage,
  }) {
    return FileUploadProgressItem(
      fileName: fileName ?? this.fileName,
      progress: progress ?? this.progress,
      fileSize: fileSize ?? this.fileSize,
      onCancel: onCancel ?? this.onCancel,
      isCompleted: isCompleted ?? this.isCompleted,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Overlay widget for showing upload progress
class FileUploadOverlay extends StatelessWidget {
  final List<FileUploadProgressItem> files;
  final VoidCallback? onCancelAll;

  const FileUploadOverlay({super.key, required this.files, this.onCancelAll});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      right: 16,
      child: SizedBox(
        width: 300,
        child: MultipleFileUploadProgress(
          files: files,
          onCancelAll: onCancelAll,
        ),
      ),
    );
  }
}
