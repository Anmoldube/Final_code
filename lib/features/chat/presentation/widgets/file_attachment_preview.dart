import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/services/file_service.dart';
import 'enhanced_file_attachment.dart';

class FileAttachmentPreview extends StatelessWidget {
  final List<MessageAttachment> attachments;
  final bool isMe;
  final Function(MessageAttachment)? onDownload;
  final Function(MessageAttachment)? onOpen;

  const FileAttachmentPreview({
    super.key,
    required this.attachments,
    this.isMe = false,
    this.onDownload,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      children: attachments.map((attachment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildAttachmentWidget(context, attachment),
        );
      }).toList(),
    );
  }

  Widget _buildAttachmentWidget(
    BuildContext context,
    MessageAttachment attachment,
  ) {
    // Use enhanced file attachment if fileMetadataId is available
    if (attachment.fileMetadataId != null) {
      return EnhancedFileAttachment(
        attachment: attachment,
        isFromCurrentUser: isMe,
        onTap: () => onOpen?.call(attachment),
        onLongPress: () => onDownload?.call(attachment),
      );
    }
    
    // Fallback to original attachment display
    switch (attachment.fileType.toLowerCase()) {
      case 'image':
        return _buildImageAttachment(context, attachment);
      case 'video':
        return _buildVideoAttachment(context, attachment);
      case 'audio':
        return _buildAudioAttachment(context, attachment);
      default:
        return _buildDocumentAttachment(context, attachment);
    }
  }

  Widget _buildImageAttachment(
    BuildContext context,
    MessageAttachment attachment,
  ) {
    return GestureDetector(
      onTap: () => _showImageViewer(context, attachment),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250, maxHeight: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Image
              CachedNetworkImage(
                imageUrl: attachment.url,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ),

              // Download button overlay
              Positioned(
                bottom: 8,
                right: 8,
                child: _buildDownloadButton(context, attachment),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(
    BuildContext context,
    MessageAttachment attachment,
  ) {
    return Container(
      width: 250,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Thumbnail or placeholder
          if (attachment.thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: attachment.thumbnailUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => _buildVideoPlaceholder(),
              ),
            )
          else
            _buildVideoPlaceholder(),

          // Play button
          const Center(
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.black54,
              child: Icon(Icons.play_arrow, size: 40, color: Colors.white),
            ),
          ),

          // Video info
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                const Icon(Icons.videocam, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    attachment.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildDownloadButton(context, attachment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.movie, size: 48, color: Colors.white),
      ),
    );
  }

  Widget _buildAudioAttachment(
    BuildContext context,
    MessageAttachment attachment,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withOpacity(0.2)
            : (isDark ? AppTheme.darkBackground : Colors.grey[100]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? Colors.white.withOpacity(0.3)
              : (isDark
                    ? AppTheme.darkDividerColor
                    : AppTheme.lightDividerColor),
        ),
      ),
      child: Row(
        children: [
          // Play button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isMe ? Colors.white : AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow,
              color: isMe ? AppTheme.primaryColor : Colors.white,
            ),
          ),

          const SizedBox(width: 12),

          // Audio info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.displayName,
                  style: TextStyle(
                    color: isMe ? Colors.white : null,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.audiotrack,
                      size: 14,
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      attachment.formattedFileSize,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    if (attachment.duration != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(attachment.duration!),
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Download button
          _buildDownloadButton(context, attachment),
        ],
      ),
    );
  }

  Widget _buildDocumentAttachment(
    BuildContext context,
    MessageAttachment attachment,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onOpen?.call(attachment),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.white.withOpacity(0.2)
              : (isDark ? AppTheme.darkBackground : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe
                ? Colors.white.withOpacity(0.3)
                : (isDark
                      ? AppTheme.darkDividerColor
                      : AppTheme.lightDividerColor),
          ),
        ),
        child: Row(
          children: [
            // File icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getDocumentColor(attachment.fileName),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getDocumentIcon(attachment.fileName),
                color: Colors.white,
                size: 24,
              ),
            ),

            const SizedBox(width: 12),

            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.displayName,
                    style: TextStyle(
                      color: isMe ? Colors.white : null,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // File type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getDocumentColor(attachment.fileName).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          attachment.extension.toUpperCase(),
                          style: TextStyle(
                            color: _getDocumentColor(attachment.fileName),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        attachment.formattedFileSize,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Download button
            _buildDownloadButton(context, attachment),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context,
    MessageAttachment attachment,
  ) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Provide haptic feedback
            HapticFeedback.lightImpact();

            // Show visual feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Starting download...'),
                duration: Duration(milliseconds: 800),
              ),
            );

            onDownload?.call(attachment);
          },
          child: const Icon(Icons.download, size: 16, color: Colors.white),
        ),
      ),
    );
  }

  void _showImageViewer(BuildContext context, MessageAttachment attachment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => onDownload?.call(attachment),
              ),
            ],
          ),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(attachment.url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: attachment.id),
          ),
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocumentColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.purple;
      case 'txt':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

// Widget for file selection preview before sending
class FileSelectionPreview extends StatelessWidget {
  final List<FilePickResult> files;
  final Function(FilePickResult)? onRemove;
  final VoidCallback? onClearAll;

  const FileSelectionPreview({
    super.key,
    required this.files,
    this.onRemove,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkDividerColor
              : AppTheme.lightDividerColor,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.attach_file, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${files.length} file${files.length > 1 ? 's' : ''} selected',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (onClearAll != null)
                TextButton(
                  onPressed: onClearAll,
                  child: const Text('Clear All'),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // File list
          Column(
            children: files
                .map((file) => _buildFileItem(context, file, isDark))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    FilePickResult file,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getFileTypeColor(file.name),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileTypeIcon(file.name),
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  FileService.instance.formatFileSize(file.size),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Remove button
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => onRemove!(file),
              color: Colors.grey,
            ),
        ],
      ),
    );
  }

  IconData _getFileTypeIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audiotrack;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.blue;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return Colors.red;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Colors.orange;
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'zip':
      case 'rar':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
