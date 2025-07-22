import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/models/chat_space.dart';
import '../../../core/models/message.dart';
import '../../../core/theme/app_theme.dart';
import '../../chat/presentation/chat_screen.dart';

class ChatSpacesTab extends StatelessWidget {
  const ChatSpacesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (!chatProvider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final chatSpaces = chatProvider.chatSpaces;

        if (chatSpaces.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: AppTheme.mediumSpacing),
                Text(
                  'No chat spaces yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: AppTheme.smallSpacing),
                Text(
                  'Tap + to create your first chat space',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: chatSpaces.length,
          itemBuilder: (context, index) {
            final chatSpace = chatSpaces[index];
            return ChatSpaceCard(chatSpace: chatSpace);
          },
        );
      },
    );
  }
}

class ChatSpaceCard extends StatelessWidget {
  final ChatSpace chatSpace;

  const ChatSpaceCard({super.key, required this.chatSpace});

  @override
  Widget build(BuildContext context) {
    final messages = context.read<ChatProvider>().getMessagesForChatSpace(
      chatSpace.id,
    );
    final lastMessage = messages.isNotEmpty ? messages.last : null;

    return Card(
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chatSpace.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (chatSpace.isEncrypted)
              const Icon(Icons.lock, size: 16, color: Colors.green),
            if (chatSpace.type == ChatSpaceType.temporary)
              const Icon(Icons.schedule, size: 16, color: Colors.orange),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chatSpace.description != null) ...[
              Text(
                chatSpace.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
            ],
            if (lastMessage != null) ...[
              Text(
                '${lastMessage.senderNickname}: ${lastMessage.content}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ] else ...[
              const Text(
                'No messages yet',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${chatSpace.participants.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.people, size: 16),
          ],
        ),
        onTap: () => _openChatSpace(context),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    IconData iconData;
    Color color;

    switch (chatSpace.type) {
      case ChatSpaceType.temporary:
        iconData = Icons.group_work;
        color = Colors.orange;
        break;
      case ChatSpaceType.permanent:
        iconData = Icons.forum;
        color = AppTheme.primaryColor;
        break;
      case ChatSpaceType.noticeBoard:
        iconData = Icons.campaign;
        color = Colors.red;
        break;
      case ChatSpaceType.forum:
        iconData = Icons.forum;
        color = AppTheme.primaryColor;
        break;
      case ChatSpaceType.thread:
        iconData = Icons.list;
        color = Colors.blue;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  void _openChatSpace(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ChatScreen(chatSpace: chatSpace)),
    );
  }
}
