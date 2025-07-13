import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/file_metadata_model.dart';
import '../../../../core/services/file_metadata_service.dart';

// Provider for file metadata by file ID
final fileMetadataProvider = FutureProvider.family<FileMetadataModel?, String>((ref, fileId) async {
  return await FileMetadataService.getFileMetadata(fileId);
});

// Provider for files by message ID
final filesByMessageProvider = FutureProvider.family<List<FileMetadataModel>, String>((ref, messageId) async {
  return await FileMetadataService.getFilesByMessage(messageId);
});

// Provider for files by chat ID with pagination
final filesByChatProvider = FutureProvider.family<List<FileMetadataModel>, FilesByChatParams>((ref, params) async {
  return await FileMetadataService.getFilesByChat(
    params.chatId,
    limit: params.limit,
    skip: params.skip,
  );
});

// Provider for files by user ID with pagination
final filesByUserProvider = FutureProvider.family<List<FileMetadataModel>, FilesByUserParams>((ref, params) async {
  return await FileMetadataService.getFilesByUser(
    params.userId,
    limit: params.limit,
    skip: params.skip,
  );
});

// Provider for file search
final fileSearchProvider = FutureProvider.family<List<FileMetadataModel>, FileSearchParams>((ref, params) async {
  return await FileMetadataService.searchFiles(
    searchTerm: params.searchTerm,
    fileType: params.fileType,
    chatId: params.chatId,
    uploadedBy: params.uploadedBy,
    dateFrom: params.dateFrom,
    dateTo: params.dateTo,
    limit: params.limit,
    skip: params.skip,
  );
});

// Provider for file statistics
final fileStatisticsProvider = FutureProvider.family<FileStatistics, String?>((ref, userId) async {
  return await FileMetadataService.getFileStatistics(userId: userId);
});

// Provider for attachment metadata
final attachmentMetadataProvider = FutureProvider.family<List<FileMetadataModel>, List<String>>((ref, attachmentIds) async {
  return await FileMetadataService.getAttachmentMetadata(attachmentIds);
});

// State notifier for managing file metadata state
class FileMetadataNotifier extends StateNotifier<FileMetadataState> {
  FileMetadataNotifier() : super(const FileMetadataState());

  // Cache for file metadata to avoid repeated API calls
  final Map<String, FileMetadataModel> _fileCache = {};
  final Map<String, List<FileMetadataModel>> _messageFilesCache = {};
  final Map<String, List<FileMetadataModel>> _chatFilesCache = {};

  // Get file metadata with caching
  Future<FileMetadataModel?> getFileMetadata(String fileId) async {
    if (_fileCache.containsKey(fileId)) {
      return _fileCache[fileId];
    }

    try {
      state = state.copyWith(isLoading: true);
      final fileMetadata = await FileMetadataService.getFileMetadata(fileId);
      
      if (fileMetadata != null) {
        _fileCache[fileId] = fileMetadata;
      }
      
      state = state.copyWith(isLoading: false);
      return fileMetadata;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Get files by message with caching
  Future<List<FileMetadataModel>> getFilesByMessage(String messageId) async {
    if (_messageFilesCache.containsKey(messageId)) {
      return _messageFilesCache[messageId]!;
    }

    try {
      state = state.copyWith(isLoading: true);
      final files = await FileMetadataService.getFilesByMessage(messageId);
      
      _messageFilesCache[messageId] = files;
      
      // Also cache individual files
      for (final file in files) {
        _fileCache[file.id] = file;
      }
      
      state = state.copyWith(isLoading: false);
      return files;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Get files by chat with caching
  Future<List<FileMetadataModel>> getFilesByChat(
    String chatId, {
    int limit = 50,
    int skip = 0,
  }) async {
    final cacheKey = '${chatId}_${limit}_$skip';
    if (_chatFilesCache.containsKey(cacheKey)) {
      return _chatFilesCache[cacheKey]!;
    }

    try {
      state = state.copyWith(isLoading: true);
      final files = await FileMetadataService.getFilesByChat(
        chatId,
        limit: limit,
        skip: skip,
      );
      
      _chatFilesCache[cacheKey] = files;
      
      // Also cache individual files
      for (final file in files) {
        _fileCache[file.id] = file;
      }
      
      state = state.copyWith(isLoading: false);
      return files;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Clear cache
  void clearCache() {
    _fileCache.clear();
    _messageFilesCache.clear();
    _chatFilesCache.clear();
    state = const FileMetadataState();
  }

  // Clear specific cache entries
  void clearFileCache(String fileId) {
    _fileCache.remove(fileId);
  }

  void clearMessageCache(String messageId) {
    _messageFilesCache.remove(messageId);
  }

  void clearChatCache(String chatId) {
    _chatFilesCache.removeWhere((key, value) => key.startsWith(chatId));
  }
}

// Provider for file metadata notifier
final fileMetadataNotifierProvider = StateNotifierProvider<FileMetadataNotifier, FileMetadataState>((ref) {
  return FileMetadataNotifier();
});

// Parameter classes for providers
class FilesByChatParams {
  final String chatId;
  final int limit;
  final int skip;

  const FilesByChatParams({
    required this.chatId,
    this.limit = 50,
    this.skip = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilesByChatParams &&
        other.chatId == chatId &&
        other.limit == limit &&
        other.skip == skip;
  }

  @override
  int get hashCode => chatId.hashCode ^ limit.hashCode ^ skip.hashCode;
}

class FilesByUserParams {
  final String userId;
  final int limit;
  final int skip;

  const FilesByUserParams({
    required this.userId,
    this.limit = 50,
    this.skip = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilesByUserParams &&
        other.userId == userId &&
        other.limit == limit &&
        other.skip == skip;
  }

  @override
  int get hashCode => userId.hashCode ^ limit.hashCode ^ skip.hashCode;
}

class FileSearchParams {
  final String? searchTerm;
  final String? fileType;
  final String? chatId;
  final String? uploadedBy;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int limit;
  final int skip;

  const FileSearchParams({
    this.searchTerm,
    this.fileType,
    this.chatId,
    this.uploadedBy,
    this.dateFrom,
    this.dateTo,
    this.limit = 50,
    this.skip = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileSearchParams &&
        other.searchTerm == searchTerm &&
        other.fileType == fileType &&
        other.chatId == chatId &&
        other.uploadedBy == uploadedBy &&
        other.dateFrom == dateFrom &&
        other.dateTo == dateTo &&
        other.limit == limit &&
        other.skip == skip;
  }

  @override
  int get hashCode {
    return searchTerm.hashCode ^
        fileType.hashCode ^
        chatId.hashCode ^
        uploadedBy.hashCode ^
        dateFrom.hashCode ^
        dateTo.hashCode ^
        limit.hashCode ^
        skip.hashCode;
  }
}

// State class for file metadata
class FileMetadataState {
  final bool isLoading;
  final String? error;

  const FileMetadataState({
    this.isLoading = false,
    this.error,
  });

  FileMetadataState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return FileMetadataState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileMetadataState &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => isLoading.hashCode ^ error.hashCode;
}