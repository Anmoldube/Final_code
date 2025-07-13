import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../../../core/services/file_service.dart';

class FileSharingWidget extends StatefulWidget {
  final VoidCallback? onFilePicked;
  final Function(List<FilePickResult>)? onFilesSelected;
  final bool multipleFiles;
  final List<String>? allowedExtensions;

  const FileSharingWidget({
    super.key,
    this.onFilePicked,
    this.onFilesSelected,
    this.multipleFiles = false,
    this.allowedExtensions,
  });

  @override
  State<FileSharingWidget> createState() => _FileSharingWidgetState();
}

class _FileSharingWidgetState extends State<FileSharingWidget> {
  bool _isPickingFile = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Share Files',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // File picker options
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Quick action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.image,
                        label: 'Images',
                        color: Colors.blue,
                        onTap: () => _pickFiles(fp.FileType.image),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.description,
                        label: 'Documents',
                        color: Colors.orange,
                        onTap: () => _pickDocuments(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.videocam,
                        label: 'Videos',
                        color: Colors.red,
                        onTap: () => _pickFiles(fp.FileType.video),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.folder,
                        label: 'Any File',
                        color: Colors.green,
                        onTap: () => _pickFiles(fp.FileType.any),
                      ),
                    ),
                  ],
                ),

                // Loading indicator
                if (_isPickingFile) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    'Selecting files...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isPickingFile ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles(fp.FileType fileType) async {
    setState(() {
      _isPickingFile = true;
    });

    try {
      if (widget.multipleFiles) {
        final files = await FileService.instance.pickMultipleFiles(
          type: fileType,
          allowedExtensions: widget.allowedExtensions,
        );

        if (files.isNotEmpty) {
          widget.onFilesSelected?.call(files);
          _showSuccessMessage('${files.length} file(s) selected');
        }
      } else {
        final file = await FileService.instance.pickSingleFile(
          type: fileType,
          allowedExtensions: widget.allowedExtensions,
        );

        if (file != null) {
          widget.onFilesSelected?.call([file]);
          widget.onFilePicked?.call();
          _showSuccessMessage('File selected: ${file.name}');
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to pick files: ${e.toString()}');
    } finally {
      setState(() {
        _isPickingFile = false;
      });
    }
  }

  Future<void> _pickDocuments() async {
    setState(() {
      _isPickingFile = true;
    });

    try {
      final files = await FileService.instance.pickDocuments(
        maxFiles: widget.multipleFiles ? 5 : 1,
      );

      if (files.isNotEmpty) {
        widget.onFilesSelected?.call(files);
        if (!widget.multipleFiles) {
          widget.onFilePicked?.call();
        }
        _showSuccessMessage('${files.length} document(s) selected');
      }
    } catch (e) {
      _showErrorMessage('Failed to pick documents: ${e.toString()}');
    } finally {
      setState(() {
        _isPickingFile = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}

// File upload progress widget
class FileUploadProgressWidget extends StatelessWidget {
  final List<FileUploadProgressItem> uploadingFiles;
  final Function(String fileName) onCancel;

  const FileUploadProgressWidget({
    super.key,
    required this.uploadingFiles,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (uploadingFiles.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uploading Files',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...uploadingFiles.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildUploadItem(context, item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadItem(BuildContext context, FileUploadProgressItem item) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.fileName,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: item.progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(item.progress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.cancel, color: Colors.red),
          onPressed: () => onCancel(item.fileName),
          tooltip: 'Cancel upload',
        ),
      ],
    );
  }
}

// File upload progress item model
class FileUploadProgressItem {
  final String fileName;
  final double progress;

  FileUploadProgressItem({required this.fileName, required this.progress});
}
