import '../../../../core/models/conversation_model.dart';
import '../datasources/conversation_api_service.dart';

class ConversationRepository {
  final ConversationApiService _apiService;

  ConversationRepository({ConversationApiService? apiService})
    : _apiService = apiService ?? ConversationApiService();

  /// Get all conversations for the current user
  Future<List<ConversationModel>> getConversations() async {
    try {
      return await _apiService.getConversations();
    } catch (e) {
      print('❌ ConversationRepository - Error getting conversations: $e');
      return [];
    }
  }

  /// Mark a conversation as read
  Future<void> markConversationAsRead(String chatId) async {
    try {
      await _apiService.markConversationAsRead(chatId);
    } catch (e) {
      print(
        '❌ ConversationRepository - Error marking conversation as read: $e',
      );
      rethrow;
    }
  }
}
