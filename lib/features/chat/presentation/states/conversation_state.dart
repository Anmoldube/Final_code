import '../../../../core/models/conversation_model.dart';

class ConversationState {
  final List<ConversationModel> conversations;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const ConversationState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
  });

  ConversationState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return ConversationState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  /// Helper to get sorted conversations with WhatsApp-like behavior
  List<ConversationModel> get sortedConversations {
    final sorted = List<ConversationModel>.from(conversations);
    sorted.sort((a, b) {
      // First, prioritize conversations with unread messages
      if (a.hasUnreadMessages && !b.hasUnreadMessages) {
        return -1;
      } else if (!a.hasUnreadMessages && b.hasUnreadMessages) {
        return 1;
      }
      
      // Then sort by last message timestamp (most recent first)
      if (a.lastMessageTimestamp == null && b.lastMessageTimestamp == null) {
        return b.updatedAt.compareTo(a.updatedAt);
      } else if (a.lastMessageTimestamp == null) {
        return 1;
      } else if (b.lastMessageTimestamp == null) {
        return -1;
      } else {
        // Use a more stable comparison that considers both timestamp and ID
        final timestampComparison = b.lastMessageTimestamp!.compareTo(a.lastMessageTimestamp!);
        if (timestampComparison != 0) {
          return timestampComparison;
        }
        // If timestamps are equal, use conversation ID for stable sorting
        return b.id.compareTo(a.id);
      }
    });
    return sorted;
  }

  /// Helper to get conversations with unread messages
  List<ConversationModel> get unreadConversations {
    return conversations.where((c) => c.hasUnreadMessages).toList();
  }

  /// Helper to get total unread count
  int get totalUnreadCount {
    return conversations.fold(0, (sum, c) => sum + c.unreadCount);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationState &&
        other.conversations.length == conversations.length &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.hasMore == hasMore &&
        other.currentPage == currentPage;
  }

  @override
  int get hashCode {
    return conversations.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        hasMore.hashCode ^
        currentPage.hashCode;
  }

  @override
  String toString() {
    return 'ConversationState(conversations: ${conversations.length}, isLoading: $isLoading, error: $error)';
  }
}
