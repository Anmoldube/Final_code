import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/chat/presentation/widgets/user_avatar.dart';

void main() {
  runApp(const ProviderScope(child: ADRDEChatDemo()));
}

class ADRDEChatDemo extends StatelessWidget {
  const ADRDEChatDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ADRDE Professional Chat - Demo',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const ChatDemoScreen(),
    );
  }
}

class ChatDemoScreen extends StatefulWidget {
  const ChatDemoScreen({super.key});

  @override
  State<ChatDemoScreen> createState() => _ChatDemoScreenState();
}

class _ChatDemoScreenState extends State<ChatDemoScreen> {
  int _selectedIndex = 0;
  final TextEditingController _messageController = TextEditingController();

  // Demo data
  final List<ChatItem> _chats = [
    ChatItem(
      name: 'ADRDE General',
      lastMessage: 'Welcome to ADRDE Professional Chat!',
      time: '2:30 PM',
      unreadCount: 3,
      isGroup: true,
      status: UserStatus.available,
    ),
    ChatItem(
      name: 'Dr. Smith',
      lastMessage: 'Meeting scheduled for tomorrow',
      time: '1:45 PM',
      unreadCount: 1,
      isGroup: false,
      status: UserStatus.inMeeting,
    ),
    ChatItem(
      name: 'Project Team',
      lastMessage: 'Updated requirements document',
      time: '12:15 PM',
      unreadCount: 0,
      isGroup: true,
      status: UserStatus.available,
    ),
    ChatItem(
      name: 'Sarah Johnson',
      lastMessage: 'Thanks for the quick response!',
      time: '11:30 AM',
      unreadCount: 0,
      isGroup: false,
      status: UserStatus.away,
    ),
  ];

  final List<Message> _messages = [
    Message(
      sender: 'Dr. Smith',
      content: 'Welcome to ADRDE Professional Chat!',
      time: '2:30 PM',
      isMe: false,
    ),
    Message(
      sender: 'You',
      content: 'Thank you! This looks great.',
      time: '2:31 PM',
      isMe: true,
    ),
    Message(
      sender: 'Dr. Smith',
      content:
          'We can now communicate securely.',
      time: '2:32 PM',
      isMe: false,
    ),
    Message(
      sender: 'You',
      content: 'Perfect for our ADRDE requirements!',
      time: '2:33 PM',
      isMe: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text(
                        'ADRDE Chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // User Status
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      UserAvatar(name: 'Current User', size: 40),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Available',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Chat List
                Expanded(
                  child: ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      return ListTile(
                        selected: index == _selectedIndex,
                        leading: chat.isGroup
                            ? CustomAvatar(
                                size: 40,
                                child: const Icon(
                                  Icons.group,
                                  color: Colors.white,
                                ),
                              )
                            : UserAvatar(
                                name: chat.name,
                                size: 40,
                                showStatus: true,
                              ),
                        title: Text(
                          chat.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              chat.time,
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (chat.unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${chat.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Chat Area
          Expanded(
            child: Column(
              children: [
                // Chat Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _chats[_selectedIndex].isGroup
                          ? CustomAvatar(
                              size: 40,
                              child: const Icon(
                                Icons.group,
                                color: Colors.white,
                              ),
                            )
                          : UserAvatar(
                              name: _chats[_selectedIndex].name,
                              size: 40,
                              showStatus: true,
                            ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _chats[_selectedIndex].name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _getStatusText(_chats[_selectedIndex].status),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.videocam),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.call),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // Messages
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!message.isMe) ...[
                              UserAvatar(
                                name: message.sender,
                                size: 32, // radius 16 * 2 = diameter 32
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: message.isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!message.isMe)
                                    Text(
                                      message.sender,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: message.isMe
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      message.content,
                                      style: TextStyle(
                                        color: message.isMe
                                            ? Colors.white
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      message.time,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (message.isMe) ...[
                              const SizedBox(width: 8),
                              UserAvatar(
                                name: 'You',
                                size: 32, // radius 16 * 2 = diameter 32
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Message Input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () {},
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          if (_messageController.text.isNotEmpty) {
                            setState(() {
                              _messages.add(
                                Message(
                                  sender: 'You',
                                  content: _messageController.text,
                                  time:
                                      '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                                  isMe: true,
                                ),
                              );
                              _messageController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.available:
        return Colors.green;
      case UserStatus.away:
        return Colors.orange;
      case UserStatus.inMeeting:
        return Colors.red;
      case UserStatus.doNotDisturb:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(UserStatus status) {
    switch (status) {
      case UserStatus.available:
        return 'Available';
      case UserStatus.away:
        return 'Away';
      case UserStatus.inMeeting:
        return 'In a Meeting';
      case UserStatus.doNotDisturb:
        return 'Do Not Disturb';
      default:
        return '';
    }
  }
}

class ChatItem {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isGroup;
  final UserStatus status;

  ChatItem({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isGroup,
    required this.status,
  });
}

class Message {
  final String sender;
  final String content;
  final String time;
  final bool isMe;

  Message({
    required this.sender,
    required this.content,
    required this.time,
    required this.isMe,
  });
}

enum UserStatus { available, away, inMeeting, doNotDisturb, offline }
