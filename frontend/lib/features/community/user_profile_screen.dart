import '../../core/theme/app_colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'community_provider.dart';
import 'chat_screen.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityProvider);
    final user = state.users.value?[userId];

    // User might be 'me' or not found, fallback
    if (user == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Kullanıcı bulunamadı')),
      );
    }

    final userPosts = state.posts.value?.where((p) => p.authorId == userId).toList() ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          user.name,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Profile Info
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).dividerColor,
              backgroundImage: AssetImage(user.avatar),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                user.bio,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions (Add Friend & Message)
            if (!user.isMe)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(communityProvider.notifier)
                            .toggleFriendStatus(userId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getFriendButtonColor(
                          user.friendStatus,
                          isDark,
                        ),
                        foregroundColor: user.friendStatus == FriendStatus.none
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _getFriendButtonText(user.friendStatus),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              userId: userId,
                              userName: user.name,
                              avatar: user.avatar,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Mesaj Gönder',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(height: 1),

            // User Posts
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: userPosts.length,
              itemBuilder: (context, index) {
                final post = userPosts[index];
                return _buildPostCard(context, ref, post);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getFriendButtonText(FriendStatus status) {
    switch (status) {
      case FriendStatus.none:
        return 'Arkadaş Ekle';
      case FriendStatus.pending:
        return 'İstek Gönderildi';
      case FriendStatus.accepted:
        return 'Arkadaşsınız';
    }
  }

  Color _getFriendButtonColor(FriendStatus status, bool isDark) {
    switch (status) {
      case FriendStatus.none:
        return AppColors.info;
      case FriendStatus.pending:
        return isDark ? Colors.grey[800]! : Colors.grey[300]!;
      case FriendStatus.accepted:
        return isDark ? Colors.grey[800]! : Colors.grey[300]!;
    }
  }

  Widget _buildPostCard(BuildContext context, WidgetRef ref, Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).dividerColor,
                  backgroundImage: AssetImage(post.authorAvatar),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        post.timeAgo,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Text(
                post.content,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (post.imageUrl != null) _buildPostImage(post.imageUrl!),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      ref.read(communityProvider.notifier).toggleLike(post.id),
                  child: Row(
                    children: [
                      Icon(
                        post.isLikedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: post.isLikedByMe
                            ? AppColors.error
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.initialLikes}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildPostImage(String urlOrPath) {
    if (urlOrPath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: urlOrPath,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: Colors.grey.withValues(alpha: 0.2),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: Colors.grey.withValues(alpha: 0.2),
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    } else {
      return Image.file(
        File(urlOrPath),
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          color: Colors.grey.withValues(alpha: 0.2),
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    }
  }
}
