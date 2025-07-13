import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'file_service.dart';
import 'storage_service.dart';
import '../config/api_config.dart';

class EnhancedFileService {
  static EnhancedFileService? _instance;
  static EnhancedFileService get instance =>
      _instance ??= EnhancedFileService._();

  EnhancedFileService._();

  late final Dio _dio;
  bool _isInitialized = false;
  static String get baseUrl => ApiConfig.baseUrl;

  void initialize() {
    if (_isInitialized) {
      debugPrint('EnhancedFileService already initialized, skipping...');
      return;
    }
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    _isInitialized = true;
    debugPrint('EnhancedFileService initialized successfully');
  }

  // Upload regular file (simplified version without encryption)
  Future<FileUploadResult> uploadFile({
    required FilePickResult fileResult,
    required String chatId,
    String? caption,
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('📁 Starting file upload: ${fileResult.name}');

      // Get file bytes
      Uint8List fileBytes;
      if (kIsWeb && fileResult.bytes != null) {
        fileBytes = fileResult.bytes!;
      } else if (!kIsWeb && fileResult.path != null) {
        final file = File(fileResult.path!);
        fileBytes = await file.readAsBytes();
      } else {
        throw Exception('Invalid file data for current platform');
      }

      // Create form data
      final formData = FormData.fromMap({
        'attachments': MultipartFile.fromBytes(
          fileBytes,
          filename: fileResult.name,
        ),
        if (caption != null) 'content': caption,
      });

      // Upload file
      final response = await _dio.post(
        '/api/messages/$chatId',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true || data['statusCode'] == '10000') {
          return FileUploadResult(
            success: true,
            messageId: data['data']?['_id'],
            fileUrl: data['data']?['attachments']?[0]?['url'],
            originalFileName: fileResult.name,
            originalFileSize: fileBytes.length,
          );
        }
      }

      return FileUploadResult(
        success: false,
        error: 'Upload failed: ${response.statusMessage}',
      );
    } catch (e) {
      debugPrint('❌ File upload error: $e');
      return FileUploadResult(success: false, error: 'Upload failed: $e');
    }
  }

  // Download file (simplified version)
  Future<FileDownloadResult> downloadFile({
    required String fileUrl,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('📥 Starting file download: $fileName');

      // Use the regular file service for downloading
      return await FileService.instance.downloadFile(
        fileUrl: fileUrl,
        fileName: fileName,
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('❌ File download error: $e');
      rethrow; // Let the FileService handle the error
    }
  }
}

// Simplified result classes
class FileUploadResult {
  final bool success;
  final String? messageId;
  final String? fileUrl;
  final String? originalFileName;
  final int? originalFileSize;
  final String? error;

  FileUploadResult({
    required this.success,
    this.messageId,
    this.fileUrl,
    this.originalFileName,
    this.originalFileSize,
    this.error,
  });
}
