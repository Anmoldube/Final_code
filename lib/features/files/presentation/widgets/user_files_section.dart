import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/file_metadata_model.dart';
import '../../../../core/services/file_metadata_service.dart';
import '../../../../core/services/file_service.dart';

class UserFilesSection extends ConsumerStatefulWidget {
  const UserFilesSection({super.key});

  @override
  ConsumerState<UserFilesSection> createState() => _UserFilesSectionState();
}

class _UserFilesSectionState extends ConsumerState<UserFilesSection> {
  List<FileMetadataModel> _userFiles = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'all';
  bool _isDownloading = false;
  String? _downloadingFileId;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserFiles();
  }

  Future<void> _loadUserFiles() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final files = await FileMetadataService.getCurrentUserFiles();

      setState(() {
        _userFiles = files;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  List<FileMetadataModel> get _filteredFiles {
    if (_selectedCategory == 'all') return _userFiles;
    return _userFiles
        .where((file) => file.fileCategory == _selectedCategory)
        .toList();
  }

  Future<void> _downloadAndOpenFile(FileMetadataModel file) async {
    if (_isDownloading) return;

    try {
      setState(() {
        _isDownloading = true;
        _downloadingFileId = file.id;
        _downloadProgress = 0.0;
      });

      // Verify file exists on server
      final verificationResult = await FileService.instance.verifyFileUrl(
        file.fileUrl,
      );

      if (!verificationResult.isAccessible) {
        _showErrorDialog(
          'File Not Found',
          'This file no longer exists on the server.',
        );
        return;
      }

      // Open file directly (the openFile method handles downloading internally)
      final success = await FileService.instance.openFile(
        file.fileUrl,
        file.fileName,
      );

      if (!success) {
        // If direct opening fails, try explicit download with progress
        final result = await FileService.instance.downloadFile(
          fileUrl: file.fileUrl,
          fileName: file.fileName,
          onProgress: (progress) {
            setState(() {
              _downloadProgress = progress;
            });
          },
        );

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'File downloaded successfully${result.filePath != null ? ": ${result.filePath}" : ""}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          _showErrorDialog(
            'Download Failed',
            result.error ?? 'Failed to download file',
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Error', 'Failed to process file: $e');
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadingFileId = null;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    // End of ListTile and Card
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          _buildCategoryFilter(isDark),
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState(isDark)
          else if (_userFiles.isEmpty)
            _buildEmptyState(isDark)
          else
            _buildFilesList(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Your Files',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserFiles,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('All', 'all', isDark),
          _buildFilterChip('Images', 'image', isDark),
          _buildFilterChip('Videos', 'video', isDark),
          _buildFilterChip('Documents', 'document', isDark),
          _buildFilterChip('Audio', 'audio', isDark),
          _buildFilterChip('Others', 'other', isDark),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String category, bool isDark) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected
              ? Theme.of(context).primaryColor
              : isDark
              ? Colors.white
              : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFilesList(bool isDark) {
    final files = _filteredFiles;

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: files.length,
        itemBuilder: (context, index) => _buildFileItem(files[index], isDark),
      ),
    );
  }

  Widget _buildFileItem(FileMetadataModel file, bool isDark) {
    final isDownloading = _downloadingFileId == file.id;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getFileTypeColor(file.fileCategory).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(file.fileCategory),
            color: _getFileTypeColor(file.fileCategory),
          ),
        ),
        title: Text(
          file.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${file.formattedFileSize} • ${dateFormat.format(file.uploadedAt)}',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (isDownloading)
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          onSelected: (action) => _handleFileAction(action, file),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.open_in_new),
                  SizedBox(width: 8),
                  Text('Open'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('Details'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _downloadAndOpenFile(file),
      ),
    );
  }

  IconData _getFileIcon(String category) {
    switch (category) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      case 'document':
        return Icons.description;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(String category) {
    switch (category) {
      case 'image':
        return Colors.green;
      case 'video':
        return Colors.red;
      case 'audio':
        return Colors.orange;
      case 'document':
        return Colors.blue;
      case 'pdf':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openFile(FileMetadataModel file) async {
    try {
      setState(() {
        _isDownloading = true;
        _downloadingFileId = file.id;
        _downloadProgress = 0.0;
      });

      final success = await FileService.instance.openFile(
        file.fileUrl,
        file.fileName,
      );

      if (!success) {
        _showErrorDialog(
          'Open File Failed',
          'Could not open the file. Try downloading it instead.',
        );
      }
    } catch (e) {
      _showErrorDialog('Error', 'Failed to open file: $e');
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadingFileId = null;
      });
    }
  }

  void _handleFileAction(String action, FileMetadataModel file) {
    switch (action) {
      case 'open':
        _openFile(file);
        break;
      case 'download':
        setState(() {
          _isDownloading = true;
          _downloadingFileId = file.id;
          _downloadProgress = 0.0;
        });

        FileService.instance
            .downloadFileSimple(file.fileUrl, file.fileName)
            .then((result) {
              if (result.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'File downloaded successfully${result.filePath != null ? ": ${result.filePath}" : ""}',
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 5),
                  ),
                );
              } else {
                _showErrorDialog(
                  'Download Failed',
                  result.error ?? 'Failed to download file',
                );
              }
            })
            .catchError((error) {
              _showErrorDialog('Error', 'Failed to download file: $error');
            })
            .whenComplete(() {
              setState(() {
                _isDownloading = false;
                _downloadingFileId = null;
              });
            });
        break;
      case 'details':
        _showFileDetails(file);
        break;
    }
  }

  void _showFileDetails(FileMetadataModel file) {
    showDialog(
      context: context,
      builder: (context) => _FileDetailsDialog(file: file),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark ? Colors.red[300] : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading files',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserFiles,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 48,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No Files Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Files shared in your chats will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _FileDetailsDialog extends StatelessWidget {
  final FileMetadataModel file;

  const _FileDetailsDialog({required this.file});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy \'at\' h:mm a');

    return AlertDialog(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      title: Text(
        'File Details',
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Name', file.displayName, isDark),
          _buildDetailRow('Size', file.formattedFileSize, isDark),
          _buildDetailRow('Type', file.mimeType, isDark),
          _buildDetailRow(
            'Uploaded',
            dateFormat.format(file.uploadedAt),
            isDark,
          ),
          if (file.dimensions != null)
            _buildDetailRow(
              'Dimensions',
              '${file.dimensions!.width}×${file.dimensions!.height}',
              isDark,
            ),
          if (file.duration != null)
            _buildDetailRow(
              'Duration',
              _formatDuration(file.duration!),
              isDark,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}
