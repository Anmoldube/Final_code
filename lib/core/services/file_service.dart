// Use conditional imports to handle web vs non-web platforms
import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:open_file/open_file.dart' as file_opener;

// Import for web platform
import 'web_file_handler.dart'
    if (dart.library.io) 'stub_web_file_handler.dart';

import 'storage_service.dart';
import '../config/api_config.dart';

class FileService {
  static FileService? _instance;
  static FileService get instance => _instance ??= FileService._();

  FileService._();

  late final Dio _dio;
  bool _isInitialized = false;

  static String get baseUrl => ApiConfig.baseUrl; // Backend URL

  // Helper method to validate and normalize file URLs for LAN access
  static String normalizeFileUrl(String originalUrl) {
    try {
      // If the URL is already properly formatted, return it
      final uri = Uri.parse(originalUrl);

      // Check if it's a valid URL with our base URL
      if (uri.hasScheme && uri.host.isNotEmpty) {
        // Replace localhost URLs with the actual server IP for LAN access
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          return originalUrl.replaceFirst(
            'http://${uri.host}:${uri.port}',
            baseUrl,
          );
        }
        return originalUrl;
      }

      // If it's a relative path, construct the full URL
      String cleanPath = originalUrl;
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }

      return '$baseUrl/$cleanPath';
    } catch (e) {
      debugPrint('Error normalizing URL: $originalUrl, Error: $e');
      // Return the original URL if parsing fails
      return originalUrl;
    }
  }

  void initialize() {
    if (_isInitialized) {
      debugPrint('FileService already initialized, skipping...');
      return;
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(
          minutes: 5,
        ), // Longer timeout for file downloads
        sendTimeout: const Duration(
          minutes: 5,
        ), // Longer timeout for file uploads
      ),
    );

    // Add auth interceptor
    _dio.interceptors.add(_AuthInterceptor());

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false, // Don't log file data
          responseBody: false,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }

    _isInitialized = true;
    debugPrint('FileService initialized successfully');
  }

  // Pick single file
  Future<FilePickResult?> pickSingleFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
        withData: kIsWeb, // On web, we need bytes
        withReadStream: !kIsWeb, // On mobile, we use read stream
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        return FilePickResult(
          name: file.name,
          path: kIsWeb ? null : file.path, // Path is null on web
          size: file.size,
          extension: file.extension,
          bytes: file.bytes,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  // Pick multiple files
  Future<List<FilePickResult>> pickMultipleFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
    int maxFiles = 10,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
        withData: kIsWeb, // On web, we need bytes
        withReadStream: !kIsWeb, // On mobile, we use read stream
      );

      if (result != null && result.files.isNotEmpty) {
        final files = result.files.take(maxFiles).map((file) {
          return FilePickResult(
            name: file.name,
            path: kIsWeb ? null : file.path, // Path is null on web
            size: file.size,
            extension: file.extension,
            bytes: file.bytes,
          );
        }).toList();

        return files;
      }

      return [];
    } catch (e) {
      debugPrint('Error picking files: $e');
      return [];
    }
  }

  // Pick images
  Future<List<FilePickResult>> pickImages({int maxImages = 5}) async {
    return await pickMultipleFiles(type: FileType.image, maxFiles: maxImages);
  }

  // Pick documents
  Future<List<FilePickResult>> pickDocuments({int maxFiles = 5}) async {
    return await pickMultipleFiles(
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
      ],
      type: FileType.custom,
      maxFiles: maxFiles,
    );
  }

  // Upload file with progress (works with FilePickResult)
  Future<FileUploadResult> uploadFileFromResult({
    required FilePickResult fileResult,
    required String chatId,
    String? caption,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = fileResult.name;

      // Create form data based on platform
      late FormData formData;

      if (kIsWeb && fileResult.bytes != null) {
        // Web platform - use bytes
        formData = FormData.fromMap({
          'attachments': MultipartFile.fromBytes(
            fileResult.bytes!,
            filename: fileName,
          ),
          if (caption != null && caption.isNotEmpty) 'content': caption,
        });
      } else if (!kIsWeb && fileResult.path != null) {
        // Mobile platform - use file path
        formData = FormData.fromMap({
          'attachments': await MultipartFile.fromFile(
            fileResult.path!,
            filename: fileName,
          ),
          if (caption != null && caption.isNotEmpty) 'content': caption,
        });
      } else {
        throw Exception('Invalid file data for current platform');
      }

      // Upload file
      final response = await _dio.post(
        '/api/messages/$chatId',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = sent / total;
            onProgress?.call(progress);
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return FileUploadResult(
          success: true,
          fileUrl: data['url'],
          messageId: data['messageId'],
          fileName: fileName,
          fileSize: fileResult.size,
          fileType: _getFileType(fileName),
        );
      } else {
        return FileUploadResult(
          success: false,
          error: 'Upload failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return FileUploadResult(success: false, error: e.toString());
    }
  }

  // Upload file with progress (legacy method for file paths)
  Future<FileUploadResult> uploadFile({
    required String filePath,
    required String chatId,
    String? caption,
    Function(double)? onProgress,
  }) async {
    try {
      final file = io.File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final fileName = path.basename(filePath);
      final fileSize = await file.length();
      final fileType = _getFileType(fileName);

      // Create form data
      final formData = FormData.fromMap({
        'attachments': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        if (caption != null && caption.isNotEmpty) 'content': caption,
      });

      // Upload file
      final response = await _dio.post(
        '/api/messages/$chatId',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = sent / total;
            onProgress?.call(progress);
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return FileUploadResult(
          success: true,
          messageId: data['_id'],
          fileUrl: data['attachments']?[0]?['url'],
          fileName: fileName,
          fileSize: fileSize,
          fileType: fileType,
        );
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('File upload error: $e');
      return FileUploadResult(success: false, error: e.toString());
    }
  }

  // Upload multiple files from FilePickResult
  Future<List<FileUploadResult>> uploadMultipleFileResults({
    required List<FilePickResult> fileResults,
    required String chatId,
    String? caption,
    Function(String fileName, double progress)? onProgress,
  }) async {
    final results = <FileUploadResult>[];

    for (final fileResult in fileResults) {
      final result = await uploadFileFromResult(
        fileResult: fileResult,
        chatId: chatId,
        caption: caption,
        onProgress: (progress) => onProgress?.call(fileResult.name, progress),
      );
      results.add(result);
    }

    return results;
  }

  // Upload multiple files (legacy method for file paths)
  Future<List<FileUploadResult>> uploadMultipleFiles({
    required List<String> filePaths,
    required String chatId,
    String? caption,
    Function(String fileName, double progress)? onProgress,
  }) async {
    final results = <FileUploadResult>[];

    for (final filePath in filePaths) {
      final fileName = path.basename(filePath);
      final result = await uploadFile(
        filePath: filePath,
        chatId: chatId,
        caption: caption,
        onProgress: (progress) => onProgress?.call(fileName, progress),
      );
      results.add(result);
    }

    return results;
  }

  // Download file with progress
  Future<FileDownloadResult> downloadFile({
    required String fileUrl,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      // Get the appropriate local directory based on platform
      String filePath;

      if (kIsWeb) {
        // Web platform doesn't use local file system
        // Instead, we'll trigger a browser download
        final normalizedUrl = normalizeFileUrl(fileUrl);
        debugPrint('🌐 Web download URL: $normalizedUrl');

        final success = await downloadFileInBrowser(normalizedUrl, fileName);

        if (success) {
          return FileDownloadResult(
            success: true,
            fileName: fileName,
            // No filePath for web
          );
        } else {
          return FileDownloadResult(
            success: false,
            error: 'Failed to download file in browser',
            fileName: fileName,
          );
        }
      }

      // For desktop/mobile platforms
      try {
        io.Directory? directory;

        try {
          // Try to get application documents directory
          directory = await getApplicationDocumentsDirectory();
        } catch (e) {
          debugPrint('❌ Error getting app documents directory: $e');

          // Fallback: Try to get temporary directory
          try {
            directory = await getTemporaryDirectory();
          } catch (e2) {
            debugPrint('❌ Error getting temporary directory: $e2');

            // Last resort: Use current directory
            directory = io.Directory('.');
          }
        }

        filePath = path.join(directory.path, fileName);
        debugPrint('📂 Using directory: ${directory.path}');

        // Check if file already exists in cache
        if (await fileExists(filePath)) {
          debugPrint('✅ File already exists at: $filePath');
          return FileDownloadResult(
            success: true,
            filePath: filePath,
            fileName: fileName,
          );
        }
      } catch (e) {
        debugPrint('❌ Error setting up file path: $e');
        // Create a fallback path in the current directory
        filePath = fileName;
      }

      // Normalize URL for LAN access
      final normalizedUrl = normalizeFileUrl(fileUrl);
      debugPrint('📥 Downloading file from: $normalizedUrl');
      debugPrint('📥 Saving to: $filePath');

      // Download the file with progress tracking
      final response = await _dio.download(
        normalizedUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
        options: Options(
          headers: {'Accept': '*/*'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ File downloaded successfully to: $filePath');
        return FileDownloadResult(
          success: true,
          filePath: filePath,
          fileName: fileName,
        );
      } else {
        debugPrint('❌ Download failed with status: ${response.statusCode}');
        return FileDownloadResult(
          success: false,
          error: 'Download failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ File download error: $e');
      return FileDownloadResult(success: false, error: e.toString());
    }
  }

  // Simple file download with default progress and fallback
  Future<FileDownloadResult> downloadFileSimple(
    String fileUrl,
    String fileName,
  ) async {
    try {
      if (kIsWeb) {
        debugPrint('🌐 Web simple download for: $fileName');

        // For web, we'll directly trigger the download
        final normalizedUrl = normalizeFileUrl(fileUrl);
        final success = await downloadFileInBrowser(normalizedUrl, fileName);

        if (success) {
          debugPrint('✅ Web download initiated for: $fileName');
          return FileDownloadResult(success: true, fileName: fileName);
        } else {
          debugPrint('❌ Web download error');
          return FileDownloadResult(
            success: false,
            error: 'Failed to download file in browser',
            fileName: fileName,
          );
        }
      }

      // For desktop/mobile platforms
      // Show progress in debug console
      final result = await downloadFile(
        fileUrl: fileUrl,
        fileName: fileName,
        onProgress: (progress) {
          debugPrint(
            'Download progress: ${(progress * 100).toStringAsFixed(1)}%',
          );
        },
      );

      if (result.success) {
        debugPrint('✅ File downloaded successfully: ${result.filePath}');

        // For Windows, try to show the file in explorer
        if (!kIsWeb && io.Platform.isWindows && result.filePath != null) {
          try {
            final filePath = result.filePath!;
            final directory = path.dirname(filePath);
            await io.Process.run('explorer.exe', [
              '/select,',
              filePath,
            ], runInShell: true);
            debugPrint('✅ Opened file location in Explorer: $directory');
          } catch (e) {
            debugPrint('⚠️ Could not open file location: $e');
          }
        }
      } else {
        debugPrint('❌ Download failed: ${result.error}');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Simple file download error: $e');
      return FileDownloadResult(success: false, error: e.toString());
    }
  }

  /// Open file using system default application
  Future<bool> openFile(String fileUrl, String fileName) async {
    try {
      debugPrint('📂 Attempting to open file: $fileName');

      if (kIsWeb) {
        // For web, we'll use a different approach
        final normalizedUrl = normalizeFileUrl(fileUrl);
        debugPrint('🌐 Web opening URL: $normalizedUrl');

        // Determine if this is a viewable file type that browsers can display
        if (isViewableInBrowser(fileName)) {
          // Open directly in a new tab for viewable files
          final success = await openFileInBrowser(normalizedUrl);
          if (success) {
            debugPrint('✅ File opened in browser tab (viewable type)');
          } else {
            debugPrint('❌ Failed to open file in browser');
          }
          return success;
        } else {
          // For non-viewable files, trigger a download
          final success = await downloadFileInBrowser(normalizedUrl, fileName);
          if (success) {
            debugPrint('✅ File download triggered (non-viewable type)');
          } else {
            debugPrint('❌ Failed to download file in browser');
          }
          return success;
        }
      }

      // For desktop/mobile platforms, first download the file
      final result = await downloadFile(fileUrl: fileUrl, fileName: fileName);

      if (!result.success) {
        debugPrint('❌ Failed to prepare file for opening: ${result.error}');
        return false;
      }

      if (result.filePath == null) {
        debugPrint('❌ No file path returned from download');
        return false;
      }

      debugPrint('🔍 Attempting to open file at path: ${result.filePath}');

      // Verify file exists before trying to open it
      if (result.filePath == null) {
        debugPrint('❌ No file path provided');
        return false;
      }

      final file = io.File(result.filePath!);
      if (!kIsWeb && !await file.exists()) {
        debugPrint('❌ File does not exist at path: ${result.filePath}');
        return false;
      }

      // For desktop/mobile, use open_file package
      try {
        final openResult = await file_opener.OpenFile.open(
          result.filePath,
          type: getMimeType(fileName),
        );

        if (openResult.type == file_opener.ResultType.done) {
          debugPrint('✅ File opened successfully');
          return true;
        } else {
          debugPrint('❌ Error opening file: ${openResult.message}');

          // If opening fails, at least show the file location to the user
          debugPrint('📂 File is located at: ${result.filePath}');
          return false;
        }
      } catch (e) {
        debugPrint('❌ Error using OpenFile: $e');

        // Try alternative method to open file on Windows
        if (!kIsWeb && io.Platform.isWindows) {
          try {
            final process = await io.Process.run('start', [
              result.filePath!,
            ], runInShell: true);
            if (process.exitCode == 0) {
              debugPrint('✅ File opened using Windows shell');
              return true;
            } else {
              debugPrint('❌ Windows shell error: ${process.stderr}');
            }
          } catch (shellError) {
            debugPrint('❌ Windows shell error: $shellError');
          }
        }

        return false;
      }
    } catch (e) {
      debugPrint('❌ Error handling file: $e');
      return false;
    }
  }

  // Get file type based on extension
  String _getFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    const videoExtensions = ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv'];
    const audioExtensions = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a'];
    const documentExtensions = [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt',
    ];

    if (imageExtensions.contains(extension)) {
      return 'image';
    } else if (videoExtensions.contains(extension)) {
      return 'video';
    } else if (audioExtensions.contains(extension)) {
      return 'audio';
    } else if (documentExtensions.contains(extension)) {
      return 'document';
    } else {
      return 'file';
    }
  }

  // Get file icon based on extension
  String getFileIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    switch (extension) {
      case '.pdf':
        return '📄';
      case '.doc':
      case '.docx':
        return '📝';
      case '.xls':
      case '.xlsx':
        return '📊';
      case '.ppt':
      case '.pptx':
        return '📺';
      case '.zip':
      case '.rar':
      case '.7z':
        return '🗜️';
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return '🖼️';
      case '.mp4':
      case '.avi':
      case '.mkv':
        return '🎥';
      case '.mp3':
      case '.wav':
      case '.flac':
        return '🎵';
      default:
        return '📎';
    }
  }

  // Format file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Generate file hash
  Future<String> generateFileHash(String filePath) async {
    try {
      if (kIsWeb) return ''; // Web doesn't support direct file access
      final file = io.File(filePath);
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('Error generating file hash: $e');
      return '';
    }
  }

  // Check if file exists
  Future<bool> fileExists(String filePath) async {
    if (kIsWeb) return false; // Web doesn't have direct file access

    try {
      final file = io.File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Delete local file
  Future<bool> deleteLocalFile(String filePath) async {
    if (kIsWeb) return false; // Web doesn't have direct file access

    try {
      final file = io.File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  // Get file mime type
  String getMimeType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    const mimeTypes = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.pdf': 'application/pdf',
      '.doc': 'application/msword',
      '.docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.xls': 'application/vnd.ms-excel',
      '.xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      '.ppt': 'application/vnd.ms-powerpoint',
      '.pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      '.txt': 'text/plain',
      '.mp4': 'video/mp4',
      '.mp3': 'audio/mpeg',
      '.wav': 'audio/wav',
      '.zip': 'application/zip',
      '.rar': 'application/x-rar-compressed',
      '.svg': 'image/svg+xml',
      '.webp': 'image/webp',
      '.html': 'text/html',
      '.htm': 'text/html',
      '.css': 'text/css',
      '.js': 'text/javascript',
      '.json': 'application/json',
      '.webm': 'video/webm',
      '.ogg': 'audio/ogg',
      '.csv': 'text/csv',
    };

    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  // Check if a file can be viewed directly in a browser
  bool _isViewableInBrowser(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    // File types that most browsers can display natively
    const viewableExtensions = [
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', // Images
      '.pdf', // PDF (most browsers have built-in viewers)
      '.txt', '.html', '.htm', '.css', '.js', '.json', '.csv', // Text files
      '.mp4', '.webm', // Common video formats
      '.mp3', '.wav', '.ogg', // Common audio formats
    ];

    return viewableExtensions.contains(extension);
  }

  // Verify if file URL is accessible on the server
  Future<FileVerificationResult> verifyFileUrl(String fileUrl) async {
    try {
      final normalizedUrl = normalizeFileUrl(fileUrl);
      debugPrint('Verifying file URL: $normalizedUrl');

      // First try to check file info through our API
      try {
        final uri = Uri.parse(normalizedUrl);
        final pathSegments = uri.pathSegments;

        String filePath = '';
        if (pathSegments.contains('uploads')) {
          final uploadsIndex = pathSegments.indexOf('uploads');
          if (uploadsIndex < pathSegments.length - 1) {
            filePath = pathSegments.sublist(uploadsIndex + 1).join('/');
          }
        }

        if (filePath.isNotEmpty) {
          final infoUrl = '$baseUrl/api/files/info/$filePath';
          final response = await _dio.get(infoUrl);

          if (response.statusCode == 200 && response.data['exists'] == true) {
            return FileVerificationResult(
              isAccessible: true,
              fileSize: response.data['size'],
              lastModified: response.data['lastModified'],
              actualPath: response.data['actualPath'],
            );
          }
        }
      } catch (e) {
        debugPrint('File info check failed: $e');
      }

      // Fallback: Try HEAD request to the file URL
      final response = await _dio.head(normalizedUrl);

      if (response.statusCode == 200) {
        return FileVerificationResult(
          isAccessible: true,
          fileSize: int.tryParse(
            response.headers.value('content-length') ?? '0',
          ),
        );
      } else {
        return FileVerificationResult(
          isAccessible: false,
          error: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('File verification failed: $e');
      return FileVerificationResult(isAccessible: false, error: e.toString());
    }
  }
}

// Auth interceptor for file service
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// Models
class FilePickResult {
  final String name;
  final String? path; // Nullable for web platform
  final int size;
  final String? extension;
  final Uint8List? bytes;

  FilePickResult({
    required this.name,
    this.path, // Optional for web platform
    required this.size,
    this.extension,
    this.bytes,
  });
}

class FileUploadResult {
  final bool success;
  final String? messageId;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;
  final String? error;

  FileUploadResult({
    required this.success,
    this.messageId,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileType,
    this.error,
  });
}

class FileDownloadResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final String? error;

  FileDownloadResult({
    required this.success,
    this.filePath,
    this.fileName,
    this.error,
  });
}

class FileVerificationResult {
  final bool isAccessible;
  final int? fileSize;
  final String? lastModified;
  final String? actualPath;
  final String? error;

  FileVerificationResult({
    required this.isAccessible,
    this.fileSize,
    this.lastModified,
    this.actualPath,
    this.error,
  });
}
