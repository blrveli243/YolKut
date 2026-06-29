import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'community_provider.dart';
import 'create_post_screen.dart';
import 'inbox_screen.dart';
import 'user_profile_screen.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(communityProvider).posts;
    final themeMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Topluluk', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.maps_ugc_rounded, color: Theme.of(context).colorScheme.onSurface, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const InboxScreen()));
            },
          ),
          IconButton(
            icon: Icon(Icons.add_box_rounded, color: Theme.of(context).colorScheme.onSurface, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _buildPostCard(context, ref, post);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
        },
        backgroundColor: const Color(0xFF0A84FF),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, WidgetRef ref, Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (post.authorId != 'me') {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: post.authorId)));
                    }
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).dividerColor,
                    backgroundImage: AssetImage(post.authorAvatar),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (post.authorId != 'me') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: post.authorId)));
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.authorName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(post.timeAgo, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Content Text
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(post.content, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, height: 1.4)),
            ),

          const SizedBox(height: 12),

          // Optional Image
          if (post.imageUrl != null)
            _buildPostImage(post.imageUrl!),

          // Footer (Actions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => ref.read(communityProvider.notifier).toggleLike(post.id),
                  child: Row(
                    children: [
                      Icon(
                        post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                        color: post.isLikedByMe ? const Color(0xFFFF375F) : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Text('${post.initialLikes}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 22),
                    const SizedBox(width: 6),
                    Text('${post.initialComments}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w600)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.share_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage(String urlOrPath) {
    if (urlOrPath.startsWith('http')) {
      return Image.network(
        urlOrPath,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          color: Colors.grey.withOpacity(0.2),
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
          color: Colors.grey.withOpacity(0.2),
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    }
  }
}
