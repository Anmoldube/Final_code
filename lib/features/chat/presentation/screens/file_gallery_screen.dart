import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/file_metadata_model.dart';
import '../providers/file_metadata_provider.dart';

class FileGalleryScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;

  const FileGalleryScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  ConsumerState<FileGalleryScreen> createState() => _FileGalleryScreenState();
}

class _FileGalleryScreenState extends ConsumerState<FileGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedFileType = 'all';
  String _searchQuery = '';
  bool _isSearching = false;
  int _currentPage = 0;
  final int _pageSize = 20;
  final List<FileMetadataModel> _allFiles = [];
  bool _hasMoreFiles = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadInitialFiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreFiles();
    }
  }

  Future<void> _loadInitialFiles() async {
    _currentPage = 0;
    _allFiles.clear();
    _hasMoreFiles = true;
    await _loadMoreFiles();
  }

  Future<void> _loadMoreFiles() async {
    if (!_hasMoreFiles) return;

    try {
      final params = FilesByChatParams(
        chatId: widget.chatId,
        limit: _pageSize,
        skip: _currentPage * _pageSize,
      );

      final files = await ref.read(filesByChatProvider(params).future);

      if (files.length < _pageSize) {
        _hasMoreFiles = false;
      }

      setState(() {
        _allFiles.addAll(files);
        _currentPage++;
      });
    } catch (e) {
      print('Error loading files: $e');
    }
  }

  List<FileMetadataModel> get _filteredFiles {
    var files = _allFiles;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      files = files
          .where(
            (file) =>
                file.originalName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                file.fileExtension.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Filter by file type
    if (_selectedFileType != 'all') {
      files = files
          .where((file) => file.fileCategory == _selectedFileType)
          .toList();
    }

    return files;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Files',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.chatName,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFileType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Files')),
              const PopupMenuItem(value: 'image', child: Text('Images')),
              const PopupMenuItem(value: 'video', child: Text('Videos')),
              const PopupMenuItem(value: 'document', child: Text('Documents')),
              const PopupMenuItem(value: 'audio', child: Text('Audio')),
              const PopupMenuItem(value: 'other', child: Text('Other')),
            ],
            child: const Icon(Icons.filter_list),
          ),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search files...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              )
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Images'),
                  Tab(text: 'Videos'),
                  Tab(text: 'Docs'),
                  Tab(text: 'Other'),
                ],
                onTap: (index) {
                  final types = ['all', 'image', 'video', 'document', 'other'];
                  setState(() {
                    _selectedFileType = types[index];
                  });
                },
              ),
      ),
      body: _buildFileGrid(),
    );
  }

  Widget _buildFileGrid() {
    final filteredFiles = _filteredFiles;

    if (filteredFiles.isEmpty && _allFiles.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No files found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_allFiles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadInitialFiles,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: filteredFiles.length + (_hasMoreFiles ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= filteredFiles.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final file = filteredFiles[index];
          return _buildFileCard(file);
        },
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
  }

  Widget _buildFileCard(FileMetadataModel file) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openFile(file),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File preview
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                ),
                child: _buildFilePreview(file),
              ),
            ),

            // File info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getFileTypeColor(
                              file.fileCategory,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            file.fileExtension.toUpperCase(),
                            style: TextStyle(
                              color: _getFileTypeColor(file.fileCategory),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.formattedFileSize,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(file.uploadedAt),
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(FileMetadataModel file) {
    switch (file.fileCategory) {
      case 'image':
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: CachedNetworkImage(
            imageUrl: file.thumbnailUrl ?? file.fileUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => _buildFileIcon(file),
          ),
        );
      case 'video':
        return Stack(
          children: [
            if (file.thumbnailUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: file.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => _buildFileIcon(file),
                ),
              )
            else
              _buildFileIcon(file),
            const Center(
              child: Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 48,
              ),
            ),
          ],
        );
      default:
        return _buildFileIcon(file);
    }
  }

  Widget _buildFileIcon(FileMetadataModel file) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(file.fileCategory),
            size: 48,
            color: _getFileTypeColor(file.fileCategory),
          ),
          const SizedBox(height: 8),
          Text(
            file.fileExtension.toUpperCase(),
            style: TextStyle(
              color: _getFileTypeColor(file.fileCategory),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
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

  void _openFile(FileMetadataModel file) {
    // TODO: Implement file opening logic
    // This could open a file viewer or download the file
    print('Opening file: ${file.displayName}');
  }
}
