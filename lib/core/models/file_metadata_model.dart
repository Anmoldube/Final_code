import '../services/timestamp_service.dart';

class FileMetadataModel {
  final String id;
  final String originalName;
  final String fileName;
  final String filePath;
  final String fileUrl;
  final String mimeType;
  final int fileSize;
  final String fileExtension;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String? messageId;
  final String? chatId;
  final String? thumbnailUrl;
  final int? duration;
  final FileDimensions? dimensions;
  final Map<String, dynamic>? metadata;
  final bool isDeleted;
  final DateTime? deletedAt;

  const FileMetadataModel({
    required this.id,
    required this.originalName,
    required this.fileName,
    required this.filePath,
    required this.fileUrl,
    required this.mimeType,
    required this.fileSize,
    required this.fileExtension,
    required this.uploadedBy,
    required this.uploadedAt,
    this.messageId,
    this.chatId,
    this.thumbnailUrl,
    this.duration,
    this.dimensions,
    this.metadata,
    this.isDeleted = false,
    this.deletedAt,
  });

  factory FileMetadataModel.fromJson(Map<String, dynamic> json) {
    return FileMetadataModel(
      id: json['id'] ?? json['_id'] ?? '',
      originalName: json['originalName'] ?? '',
      fileName: json['fileName'] ?? '',
      filePath: json['filePath'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      mimeType: json['mimeType'] ?? '',
      fileSize:
          json['fileSize'] ??
          json['size'] ??
          0, // Try both fileSize and size fields
      fileExtension: json['fileExtension'] ?? '',
      uploadedBy: json['uploadedBy'] ?? '',
      uploadedAt: TimestampService.parseFileTimestamp(json['uploadedAt']),
      messageId: json['messageId'],
      chatId: json['chatId'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'],
      dimensions: json['dimensions'] != null
          ? FileDimensions.fromJson(json['dimensions'])
          : null,
      metadata: json['metadata'],
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: TimestampService.parseAndValidateDateTime(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalName': originalName,
      'fileName': fileName,
      'filePath': filePath,
      'fileUrl': fileUrl,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'fileExtension': fileExtension,
      'uploadedBy': uploadedBy,
      'uploadedAt': TimestampService.toIsoString(uploadedAt),
      'messageId': messageId,
      'chatId': chatId,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'dimensions': dimensions?.toJson(),
      'metadata': metadata,
      'isDeleted': isDeleted,
      'deletedAt': TimestampService.toIsoString(deletedAt),
    };
  }

  // Getters for UI
  String get fileCategory {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType.contains('pdf')) return 'pdf';
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return 'document';
    }
    if (mimeType.contains('text/')) return 'text';
    return 'other';
  }

  String get formattedFileSize {
    if (fileSize == 0) return '0 B';

    const int kb = 1024;
    const int mb = 1024 * 1024;
    const int gb = 1024 * 1024 * 1024;

    if (fileSize >= gb) {
      return '${(fileSize / gb).toStringAsFixed(1)} GB';
    } else if (fileSize >= mb) {
      return '${(fileSize / mb).toStringAsFixed(1)} MB';
    } else if (fileSize >= kb) {
      return '${(fileSize / kb).toStringAsFixed(1)} KB';
    } else {
      return '$fileSize B';
    }
  }

  String get displayName => originalName.isNotEmpty ? originalName : fileName;

  FileMetadataModel copyWith({
    String? id,
    String? originalName,
    String? fileName,
    String? filePath,
    String? fileUrl,
    String? mimeType,
    int? fileSize,
    String? fileExtension,
    String? uploadedBy,
    DateTime? uploadedAt,
    String? messageId,
    String? chatId,
    String? thumbnailUrl,
    int? duration,
    FileDimensions? dimensions,
    Map<String, dynamic>? metadata,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return FileMetadataModel(
      id: id ?? this.id,
      originalName: originalName ?? this.originalName,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileUrl: fileUrl ?? this.fileUrl,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      fileExtension: fileExtension ?? this.fileExtension,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      dimensions: dimensions ?? this.dimensions,
      metadata: metadata ?? this.metadata,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileMetadataModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class FileDimensions {
  final int width;
  final int height;

  const FileDimensions({required this.width, required this.height});

  factory FileDimensions.fromJson(Map<String, dynamic> json) {
    return FileDimensions(
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'width': width, 'height': height};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileDimensions &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => width.hashCode ^ height.hashCode;
}

class FileStatistics {
  final int totalFiles;
  final int totalSize;
  final int imageCount;
  final int videoCount;
  final int documentCount;

  const FileStatistics({
    required this.totalFiles,
    required this.totalSize,
    required this.imageCount,
    required this.videoCount,
    required this.documentCount,
  });

  factory FileStatistics.fromJson(Map<String, dynamic> json) {
    return FileStatistics(
      totalFiles: json['totalFiles'] ?? 0,
      totalSize: json['totalSize'] ?? 0,
      imageCount: json['imageCount'] ?? 0,
      videoCount: json['videoCount'] ?? 0,
      documentCount: json['documentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalFiles': totalFiles,
      'totalSize': totalSize,
      'imageCount': imageCount,
      'videoCount': videoCount,
      'documentCount': documentCount,
    };
  }

  String get formattedTotalSize {
    if (totalSize == 0) return '0 B';

    const int kb = 1024;
    const int mb = 1024 * 1024;
    const int gb = 1024 * 1024 * 1024;

    if (totalSize >= gb) {
      return '${(totalSize / gb).toStringAsFixed(1)} GB';
    } else if (totalSize >= mb) {
      return '${(totalSize / mb).toStringAsFixed(1)} MB';
    } else if (totalSize >= kb) {
      return '${(totalSize / kb).toStringAsFixed(1)} KB';
    } else {
      return '$totalSize B';
    }
  }
}
