import 'package:equatable/equatable.dart';

import '../../../../core/models/chat_model.dart';
import '../../../../core/models/user_model.dart';

class ChatState extends Equatable {
  final List<ChatModel> chats;
  final List<ChatModel> directChats;
  final List<ChatModel> groupChats;
  final List<ChatModel> searchResults;
  final List<UserModel> availableUsers;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.chats = const [],
    this.directChats = const [],
    this.groupChats = const [],
    this.searchResults = const [],
    this.availableUsers = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatModel>? chats,
    List<ChatModel>? directChats,
    List<ChatModel>? groupChats,
    List<ChatModel>? searchResults,
    List<UserModel>? availableUsers,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      directChats: directChats ?? this.directChats,
      groupChats: groupChats ?? this.groupChats,
      searchResults: searchResults ?? this.searchResults,
      availableUsers: availableUsers ?? this.availableUsers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    chats,
    directChats,
    groupChats,
    searchResults,
    availableUsers,
    isLoading,
    error,
  ];

  @override
  String toString() {
    return 'ChatState(chats: ${chats.length}, directChats: ${directChats.length}, groupChats: ${groupChats.length}, isLoading: $isLoading, error: $error)';
  }
}
