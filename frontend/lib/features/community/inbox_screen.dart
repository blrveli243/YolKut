import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'community_provider.dart';
import 'chat_screen.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityProvider);
    final chats = state.chats.values.toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mesajlar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: chats.isEmpty
          ? Center(child: Text('Henüz mesajınız yok', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))))
          : ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final user = state.users[chat.userId];
                if (user == null) return const SizedBox.shrink();

                final lastMessage = chat.messages.isNotEmpty ? chat.messages.last : null;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage(user.avatar),
                    backgroundColor: Theme.of(context).dividerColor,
                  ),
                  title: Text(user.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: lastMessage != null
                      ? Text(
                          (lastMessage.isMine ? 'Sen: ' : '') + lastMessage.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                        )
                      : null,
                  trailing: lastMessage != null
                      ? Text(lastMessage.time, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12))
                      : null,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ChatScreen(userId: user.id, userName: user.name, avatar: user.avatar)
                    ));
                  },
                );
              },
            ),
    );
  }
}
