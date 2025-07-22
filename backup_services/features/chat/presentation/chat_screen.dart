import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/chat_space.dart';
import '../../../core/models/message.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/identity_provider.dart';
import '../../../core/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final ChatSpace chatSpace;

  const ChatScreen({super.key, required this.chatSpace});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Set this as the current chat space
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().setCurrentChatSpace(widget.chatSpace);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chatSpace.name),
            Text(
              _getSubtitleText(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showChatSpaceInfo,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.getCurrentMessages();

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageBubble(message: message);
                  },
                );
              },
            ),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText:
                    widget.chatSpace.allowReplies
                        ? 'Type a message...'
                        : 'Replies not allowed',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              enabled: widget.chatSpace.allowReplies,
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: AppTheme.smallSpacing),
          FloatingActionButton(
            onPressed: widget.chatSpace.allowReplies ? _sendMessage : null,
            mini: true,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  String _getSubtitleText() {
    final typeText = widget.chatSpace.type.name;
    final participantCount = widget.chatSpace.participants.length;
    return '$typeText • $participantCount participants';
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatProvider>().sendMessage(content: text);
    _messageController.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showChatSpaceInfo() {
    showDialog(
      context: context,
      builder: (context) => ChatSpaceInfoDialog(chatSpace: widget.chatSpace),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<IdentityProvider>().currentIdentity?.id;
    final isOwnMessage = message.senderId == currentUserId;
    final isSystemMessage = message.type == MessageType.system;

    if (isSystemMessage) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isOwnMessage) ...[
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: Text(
                  message.senderNickname,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isOwnMessage
                        ? AppTheme.messageBubbleSent
                        : AppTheme.messageBubbleReceived.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isOwnMessage ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              isOwnMessage ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (message.isEncrypted) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock,
                          size: 10,
                          color:
                              isOwnMessage ? Colors.white70 : Colors.grey[600],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatSpaceInfoDialog extends StatelessWidget {
  final ChatSpace chatSpace;

  const ChatSpaceInfoDialog({super.key, required this.chatSpace});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(chatSpace.name),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chatSpace.description != null) ...[
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(chatSpace.description!),
              const SizedBox(height: 16),
            ],

            const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(chatSpace.type.name),
            const SizedBox(height: 8),

            const Text(
              'Participants:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${chatSpace.participants.length}'),
            const SizedBox(height: 8),

            const Text(
              'Created:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_formatDate(chatSpace.createdAt)),
            const SizedBox(height: 8),

            if (chatSpace.expiresAt != null) ...[
              const Text(
                'Expires:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_formatDate(chatSpace.expiresAt!)),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                if (chatSpace.isEncrypted) ...[
                  const Icon(Icons.lock, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  const Text('Encrypted'),
                ],
                if (chatSpace.isPublic) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.public, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  const Text('Public'),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (chatSpace.type == ChatSpaceType.temporary) ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _leaveChatSpace(context);
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _leaveChatSpace(BuildContext context) {
    context.read<ChatProvider>().leaveChatSpace(chatSpace.id);
    Navigator.of(context).pop(); // Go back to home screen
  }
}
