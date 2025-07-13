import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';

class ChatDebugService {
  static void debugChatParticipants(ChatModel chat) {
    if (!kDebugMode) return;
    
    debugPrint('🔍 === CHAT DEBUG INFO ===');
    debugPrint('Chat ID: ${chat.id}');
    debugPrint('Chat Name: ${chat.name}');
    debugPrint('Chat Type: ${chat.type}');
    debugPrint('Is Group: ${chat.isGroup}');
    debugPrint('Raw participants count: ${chat.participants.length}');
    
    // Check for duplicates
    final userIds = chat.participants.map((p) => p.id).toList();
    final uniqueUserIds = userIds.toSet().toList();
    
    debugPrint('Unique user IDs count: ${uniqueUserIds.length}');
    if (userIds.length != uniqueUserIds.length) {
      debugPrint('⚠️ DUPLICATE USERS DETECTED!');
      final duplicates = <String>[];
      for (var id in userIds) {
        if (userIds.where((element) => element == id).length > 1 && !duplicates.contains(id)) {
          duplicates.add(id);
        }
      }
      debugPrint('Duplicate user IDs: $duplicates');
    }
    
    debugPrint('--- Participants Details ---');
    for (int i = 0; i < chat.participants.length; i++) {
      final participant = chat.participants[i];
      debugPrint('[$i] ID: ${participant.id}');
      debugPrint('[$i] Name: ${participant.displayName}');
      debugPrint('[$i] Email: ${participant.email}');
      debugPrint('[$i] Username: ${participant.username}');
      debugPrint('---');
    }
    
    if (chat.admin != null) {
      debugPrint('Admin: ${chat.admin!.displayName} (${chat.admin!.id})');
    }
    
    debugPrint('🔍 === END CHAT DEBUG ===\n');
  }
  
  static void debugRawChatData(Map<String, dynamic> rawData) {
    if (!kDebugMode) return;
    
    debugPrint('🔍 === RAW CHAT DATA DEBUG ===');
    debugPrint('Chat Name: ${rawData['name']}');
    debugPrint('Chat ID: ${rawData['_id'] ?? rawData['id']}');
    debugPrint('Is Group Chat: ${rawData['isGroupChat']}');
    
    if (rawData['participants'] != null) {
      final participants = rawData['participants'] as List;
      debugPrint('Raw participants count: ${participants.length}');
      
      debugPrint('--- Raw Participants ---');
      for (int i = 0; i < participants.length; i++) {
        final participant = participants[i];
        if (participant is Map<String, dynamic>) {
          debugPrint('[$i] ID: ${participant['_id'] ?? participant['id']}');
          debugPrint('[$i] Name: ${participant['name'] ?? 'N/A'}');
          debugPrint('[$i] Email: ${participant['email'] ?? 'N/A'}');
          debugPrint('[$i] Username: ${participant['username'] ?? 'N/A'}');
        } else {
          debugPrint('[$i] Raw data: $participant');
        }
        debugPrint('---');
      }
    } else {
      debugPrint('No participants data found in raw data');
    }
    
    debugPrint('🔍 === END RAW CHAT DATA DEBUG ===\n');
  }
}