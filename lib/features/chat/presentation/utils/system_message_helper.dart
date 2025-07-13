import '../../../../core/models/message_model.dart';
import '../../../../core/models/user_model.dart';

class SystemMessageHelper {
  /// Creates a system message for chat start point
  static MessageModel createChatStartMessage({
    required String chatId,
    required List<UserModel> participants,
    required bool isGroupChat,
  }) {
    final content = isGroupChat
        ? _createGroupStartMessage(participants)
        : _createDirectChatStartMessage(participants);

    // Create a dummy sender for system messages
    final systemSender = UserModel(
      id: 'system',
      username: 'System',
      email: 'system@app.com',
      firstName: 'System',
      lastName: null,
      avatar: null,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now().subtract(const Duration(days: 365)),
      isSynced: true,
    );

    return MessageModel(
      id: '${chatId}_start_system',
      chatId: chatId,
      sender: systemSender,
      content: content,
      type: MessageType.text,
      attachments: [],
      status: MessageStatus.read,
      createdAt: DateTime.now().subtract(const Duration(days: 365)), // Very old
      updatedAt: DateTime.now().subtract(const Duration(days: 365)),
      readAt: DateTime.now().subtract(const Duration(days: 365)),
      senderId: 'system',
      isSynced: true,
      isLocalOnly: false,
      readBy: [],
      deliveredTo: [],
      isEdited: false,
      isDeleted: false,
      metadata: {'isSystemMessage': true},
    );
  }

  /// Creates a system message for when new messages are available
  static MessageModel createNewMessagesIndicator({
    required String chatId,
    required int messageCount,
  }) {
    // Create a dummy sender for system messages
    final systemSender = UserModel(
      id: 'system',
      username: 'System',
      email: 'system@app.com',
      firstName: 'System',
      lastName: null,
      avatar: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: true,
    );

    return MessageModel(
      id: '${chatId}_new_messages_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      sender: systemSender,
      content: '$messageCount new messages',
      type: MessageType.text,
      attachments: [],
      status: MessageStatus.read,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      readAt: DateTime.now(),
      senderId: 'system',
      isSynced: true,
      isLocalOnly: false,
      readBy: [],
      deliveredTo: [],
      isEdited: false,
      isDeleted: false,
      metadata: {'isSystemMessage': true},
    );
  }

  static String _createGroupStartMessage(List<UserModel> participants) {
    if (participants.length <= 2) {
      return 'Group created';
    }
    
    final participantNames = participants
        .take(3)
        .map((user) => user.firstName ?? user.username)
        .join(', ');
    
    if (participants.length > 3) {
      final remaining = participants.length - 3;
      return 'Group created • $participantNames and $remaining others';
    }
    
    return 'Group created • $participantNames';
  }

  static String _createDirectChatStartMessage(List<UserModel> participants) {
    if (participants.length != 2) {
      return 'Chat started';
    }
    
    final user1 = participants[0].firstName ?? participants[0].username;
    final user2 = participants[1].firstName ?? participants[1].username;
    return '$user1 and $user2 connected';
  }

  /// Check if a message is a system message
  static bool isSystemMessage(MessageModel message) {
    return message.metadata?['isSystemMessage'] == true || 
           message.senderId == 'system' ||
           message.id.contains('_system');
  }

  /// Check if a message is a chat start message
  static bool isChatStartMessage(MessageModel message) {
    return message.id.contains('_start_system');
  }

  /// Check if a message is a new messages indicator
  static bool isNewMessagesIndicator(MessageModel message) {
    return message.id.contains('_new_messages_');
  }
}