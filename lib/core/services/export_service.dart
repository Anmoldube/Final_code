import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ExportService {
  /// Export chat data in JSON format
  static Future<Uint8List> exportAsJson({
    required List<ConversationModel> conversations,
    required Map<String, List<MessageModel>> conversationMessages,
    required UserModel currentUser,
  }) async {
    try {
      final exportData = {
        'exportInfo': {
          'exportDate': DateTime.now().toIso8601String(),
          'exportedBy': currentUser.username,
          'exportedByEmail': currentUser.email,
          'version': '1.0.0',
        },
        'user': {
          'id': currentUser.id,
          'username': currentUser.username,
          'email': currentUser.email,
          'displayName': currentUser.displayName,
        },
        'conversations': conversations.map((conversation) {
          final messages = conversationMessages[conversation.id] ?? [];
          return {
            'id': conversation.id,
            'name': conversation.name,
            'isGroupChat': conversation.isGroupChat,
            'participants': conversation.participants
                .map(
                  (user) => {
                    'id': user.id,
                    'username': user.username,
                    'email': user.email,
                    'displayName': user.displayName,
                  },
                )
                .toList(),
            'createdAt': conversation.createdAt.toIso8601String(),
            'lastMessage': conversation.lastMessageTimestamp?.toIso8601String(),
            'messageCount': messages.length,
            'messages': messages
                .map(
                  (message) => {
                    'id': message.id,
                    'content': message.content,
                    'type': message.type.name,
                    'senderId': message.senderId,
                    'senderName': message.sender.displayName,
                    'timestamp': message.createdAt.toIso8601String(),
                    'status': message.status.name,
                    'isEdited': message.isEdited,
                    'editedAt': message.updatedAt?.toIso8601String(),
                    'replyToId': message.replyToId,
                    'reactions': message.readBy,
                    'attachments': message.attachments
                        .map(
                          (attachment) => {
                            'id': attachment.id,
                            'filename': attachment.originalName,
                            'size': attachment.size,
                            'type': attachment.type,
                            'url': attachment.url,
                          },
                        )
                        .toList(),
                  },
                )
                .toList(),
          };
        }).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      return Uint8List.fromList(utf8.encode(jsonString));
    } catch (e) {
      throw Exception('Failed to export as JSON: $e');
    }
  }

  /// Export chat data in HTML format
  static Future<Uint8List> exportAsHtml({
    required List<ConversationModel> conversations,
    required Map<String, List<MessageModel>> conversationMessages,
    required UserModel currentUser,
  }) async {
    try {
      final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
      final exportDate = dateFormat.format(DateTime.now());

      final html = StringBuffer();

      html.writeln('<!DOCTYPE html>');
      html.writeln('<html lang="en">');
      html.writeln('<head>');
      html.writeln('<meta charset="UTF-8">');
      html.writeln(
        '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
      );
      html.writeln('<title>Chat Export - ${currentUser.username}</title>');
      html.writeln('<style>');
      html.writeln(_getChatExportCSS());
      html.writeln('</style>');
      html.writeln('</head>');
      html.writeln('<body>');

      html.writeln('<div class="header">');
      html.writeln('<h1>Chat Export</h1>');
      html.writeln('<div class="export-info">');
      html.writeln(
        '<p><strong>Exported by:</strong> ${currentUser.displayName} (${currentUser.email})</p>',
      );
      html.writeln('<p><strong>Export date:</strong> $exportDate</p>');
      html.writeln(
        '<p><strong>Total conversations:</strong> ${conversations.length}</p>',
      );
      html.writeln('</div>');
      html.writeln('</div>');

      html.writeln('<div class="conversations">');

      for (final conversation in conversations) {
        final messages = conversationMessages[conversation.id] ?? [];
        final displayName = conversation.getDisplayName(currentUser.id);

        html.writeln('<div class="conversation">');
        html.writeln('<div class="conversation-header">');
        html.writeln('<h2>${_escapeHtml(displayName)}</h2>');
        html.writeln('<div class="conversation-info">');
        html.writeln(
          '<span class="chat-type">${conversation.isGroupChat ? "Group Chat" : "One-on-One"}</span>',
        );
        html.writeln(
          '<span class="message-count">${messages.length} messages</span>',
        );
        html.writeln(
          '<span class="date">Created: ${dateFormat.format(conversation.createdAt)}</span>',
        );
        html.writeln('</div>');
        html.writeln('</div>');

        if (messages.isNotEmpty) {
          html.writeln('<div class="messages">');

          for (final message in messages) {
            final isMe = message.senderId == currentUser.id;
            final messageClass = isMe ? 'message-me' : 'message-other';

            html.writeln('<div class="message $messageClass">');
            html.writeln('<div class="message-header">');
            html.writeln(
              '<span class="sender">${_escapeHtml(message.sender.displayName)}</span>',
            );
            html.writeln(
              '<span class="timestamp">${dateFormat.format(message.createdAt)}</span>',
            );
            html.writeln('</div>');
            html.writeln('<div class="message-content">');
            html.writeln('<p>${_escapeHtml(message.content)}</p>');
            html.writeln('</div>');

            if (message.isEdited) {
              html.writeln('<div class="message-edited">Edited</div>');
            }

            if (message.attachments.isNotEmpty == true) {
              html.writeln('<div class="attachments">');
              for (final attachment in message.attachments) {
                html.writeln('<div class="attachment">');
                html.writeln(
                  '<span class="attachment-name">${_escapeHtml(attachment.originalName ?? 'Unknown')}</span>',
                );
                html.writeln(
                  '<span class="attachment-size">${_formatFileSize(attachment.size ?? 0)}</span>',
                );
                html.writeln('</div>');
              }
              html.writeln('</div>');
            }

            html.writeln('</div>');
          }

          html.writeln('</div>');
        } else {
          html.writeln(
            '<div class="empty-conversation">No messages in this conversation</div>',
          );
        }

        html.writeln('</div>');
      }

      html.writeln('</div>');
      html.writeln('</body>');
      html.writeln('</html>');

      return Uint8List.fromList(utf8.encode(html.toString()));
    } catch (e) {
      throw Exception('Failed to export as HTML: $e');
    }
  }

  /// Export chat data in plain text format
  static Future<Uint8List> exportAsText({
    required List<ConversationModel> conversations,
    required Map<String, List<MessageModel>> conversationMessages,
    required UserModel currentUser,
  }) async {
    try {
      final buffer = StringBuffer();
      final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

      buffer.writeln('=== CHAT EXPORT ===');
      buffer.writeln(
        'Exported by: ${currentUser.displayName} (${currentUser.email})',
      );
      buffer.writeln('Export date: ${dateFormat.format(DateTime.now())}');
      buffer.writeln('Total conversations: ${conversations.length}');
      buffer.writeln();

      for (int i = 0; i < conversations.length; i++) {
        final conversation = conversations[i];
        final messages = conversationMessages[conversation.id] ?? [];
        final displayName = conversation.getDisplayName(currentUser.id);

        buffer.writeln('=' * 60);
        buffer.writeln('CONVERSATION ${i + 1}: $displayName');
        buffer.writeln(
          'Type: ${conversation.isGroupChat ? "Group Chat" : "One-on-One"}',
        );
        buffer.writeln('Messages: ${messages.length}');
        buffer.writeln('Created: ${dateFormat.format(conversation.createdAt)}');
        buffer.writeln('=' * 60);
        buffer.writeln();

        if (messages.isNotEmpty) {
          for (final message in messages) {
            buffer.writeln(
              '[${dateFormat.format(message.createdAt)}] ${message.sender.displayName}: ${message.content}',
            );

            if (message.isEdited) {
              buffer.writeln('  (Edited)');
            }

            if (message.attachments.isNotEmpty == true) {
              buffer.writeln('  Attachments:');
              for (final attachment in message.attachments) {
                buffer.writeln(
                  '    - ${attachment.originalName ?? 'Unknown'} (${_formatFileSize(attachment.size ?? 0)})',
                );
              }
            }

            buffer.writeln();
          }
        } else {
          buffer.writeln('No messages in this conversation');
          buffer.writeln();
        }

        buffer.writeln();
      }

      return Uint8List.fromList(utf8.encode(buffer.toString()));
    } catch (e) {
      throw Exception('Failed to export as text: $e');
    }
  }

  /// Download file in web environment
  static Future<void> downloadFile(Uint8List bytes, String filename) async {
    try {
      if (kIsWeb) {
        // For web, we'll use the clipboard instead of direct download
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:application/octet-stream;base64,$base64String';

        // Copy to clipboard for now - can be enhanced later
        await Clipboard.setData(
          ClipboardData(
            text: 'Export data ready. File: $filename\nData: $dataUrl',
          ),
        );

        throw UnsupportedError(
          'File download via clipboard - copy the data URL and save manually',
        );
      } else {
        // For mobile/desktop, we would use file system APIs
        // This is a placeholder for mobile implementation
        throw UnsupportedError(
          'File download not implemented for this platform',
        );
      }
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  static String _getChatExportCSS() {
    return '''
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
      background: #f5f5f5;
    }
    
    .header {
      background: white;
      padding: 20px;
      border-radius: 8px;
      margin-bottom: 20px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .header h1 {
      margin: 0 0 15px 0;
      color: #2c3e50;
    }
    
    .export-info p {
      margin: 5px 0;
      font-size: 14px;
      color: #666;
    }
    
    .conversation {
      background: white;
      margin-bottom: 20px;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .conversation-header {
      background: #3498db;
      color: white;
      padding: 15px 20px;
    }
    
    .conversation-header h2 {
      margin: 0 0 10px 0;
      font-size: 18px;
    }
    
    .conversation-info {
      display: flex;
      gap: 15px;
      font-size: 12px;
      opacity: 0.9;
    }
    
    .chat-type {
      background: rgba(255,255,255,0.2);
      padding: 2px 8px;
      border-radius: 10px;
    }
    
    .messages {
      padding: 20px;
    }
    
    .message {
      margin-bottom: 15px;
      padding: 10px;
      border-radius: 8px;
      position: relative;
    }
    
    .message-me {
      background: #e3f2fd;
      margin-left: 50px;
    }
    
    .message-other {
      background: #f5f5f5;
      margin-right: 50px;
    }
    
    .message-header {
      display: flex;
      justify-content: space-between;
      margin-bottom: 5px;
      font-size: 12px;
    }
    
    .sender {
      font-weight: 600;
      color: #2c3e50;
    }
    
    .timestamp {
      color: #666;
    }
    
    .message-content p {
      margin: 0;
      word-wrap: break-word;
    }
    
    .message-edited {
      font-size: 11px;
      color: #666;
      font-style: italic;
      margin-top: 5px;
    }
    
    .attachments {
      margin-top: 8px;
      padding-top: 8px;
      border-top: 1px solid #eee;
    }
    
    .attachment {
      display: flex;
      justify-content: space-between;
      font-size: 12px;
      color: #666;
      margin-bottom: 5px;
    }
    
    .attachment-name {
      font-weight: 500;
    }
    
    .empty-conversation {
      padding: 20px;
      text-align: center;
      color: #666;
      font-style: italic;
    }
    
    @media (max-width: 600px) {
      body {
        padding: 10px;
      }
      
      .message-me {
        margin-left: 20px;
      }
      
      .message-other {
        margin-right: 20px;
      }
      
      .conversation-info {
        flex-direction: column;
        gap: 5px;
      }
    }
    ''';
  }
}
