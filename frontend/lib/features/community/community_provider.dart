import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'community_repository.dart';

enum FriendStatus { none, pending, accepted }

class SocialUser {
  final String id;
  final String name;
  final String avatar;
  final String bio;
  final FriendStatus friendStatus;
  final bool isMe;

  SocialUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.bio,
    this.friendStatus = FriendStatus.none,
    this.isMe = false,
  });

  SocialUser copyWith({
    String? id,
    String? name,
    String? avatar,
    String? bio,
    FriendStatus? friendStatus,
    bool? isMe,
  }) {
    return SocialUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      friendStatus: friendStatus ?? this.friendStatus,
      isMe: isMe ?? this.isMe,
    );
  }
}

class PostComment {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String timeAgo;
  final String content;

  PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.timeAgo,
    required this.content,
  });
}

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String timeAgo;
  final String content;
  final String? imageUrl;
  final int initialLikes;
  final int initialComments;
  final bool isLikedByMe;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.timeAgo,
    required this.content,
    this.imageUrl,
    required this.initialLikes,
    required this.initialComments,
    this.isLikedByMe = false,
  });

  Post copyWith({bool? isLikedByMe, int? initialLikes}) {
    return Post(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      timeAgo: timeAgo,
      content: content,
      imageUrl: imageUrl,
      initialLikes: initialLikes ?? this.initialLikes,
      initialComments: initialComments,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }
}

class ChatMessage {
  final String text;
  final bool isMine;
  final String time;

  ChatMessage({required this.text, required this.isMine, required this.time});
}

class ChatSession {
  final String userId;
  final List<ChatMessage> messages;

  ChatSession({required this.userId, required this.messages});
}

class CommunityState {
  final AsyncValue<List<Post>> posts;
  final AsyncValue<Map<String, SocialUser>> users;
  final Map<String, ChatSession> chats;

  CommunityState({
    required this.posts,
    required this.users,
    required this.chats,
  });

  CommunityState copyWith({
    AsyncValue<List<Post>>? posts,
    AsyncValue<Map<String, SocialUser>>? users,
    Map<String, ChatSession>? chats,
  }) {
    return CommunityState(
      posts: posts ?? this.posts,
      users: users ?? this.users,
      chats: chats ?? this.chats,
    );
  }
}

final communityRepositoryProvider = Provider((ref) => CommunityRepository());

class CommunityNotifier extends Notifier<CommunityState> {
  @override
  CommunityState build() {
    timeago.setLocaleMessages('tr', timeago.TrMessages());
    Future.microtask(() => _fetchInitialData());
    return CommunityState(
      posts: const AsyncValue.loading(),
      users: const AsyncValue.loading(),
      chats: {},
    );
  }

  Future<void> refresh() async {
    await _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      final fetchedUsers = await repo.getUsers();
      final fetchedPosts = await repo.getPosts();

      final Map<String, SocialUser> usersMap = {};
      for (var u in fetchedUsers) {
        usersMap[u['id'].toString()] = SocialUser(
          id: u['id'].toString(),
          name: '${u['firstName']} ${u['lastName']}',
          avatar: u['photoUrl'] ?? 'assets/avatars/male_average.png',
          bio: 'YolKut Sporcusu',
          friendStatus: u['friendStatus'] == 'accepted'
              ? FriendStatus.accepted
              : u['friendStatus'] == 'pending'
                  ? FriendStatus.pending
                  : FriendStatus.none,
          isMe: u['isMe'] == true,
        );
      }

      final fetchedConversations = await repo.getConversations();
      final Map<String, ChatSession> initialChats = {};
      for (var c in fetchedConversations) {
        final uid = c['userId'].toString();
        initialChats[uid] = ChatSession(
          userId: uid,
          messages: [
            ChatMessage(
              text: c['lastMessage'],
              isMine: false, // We just need it to show in inbox, we don't know who sent it exactly in this preview, but that's fine for MVP
              time: _formatTimeAgo(DateTime.parse(c['time'])),
            )
          ],
        );
      }

      final List<Post> postsList = fetchedPosts.map((p) {
        return Post(
          id: p['id'].toString(),
          authorId: p['user']['id'].toString(),
          authorName: '${p['user']['firstName']} ${p['user']['lastName']}',
          authorAvatar: p['user']['photoUrl'] ?? 'assets/avatars/male_average.png',
          timeAgo: _formatTimeAgo(DateTime.parse(p['createdAt'])),
          content: p['content'],
          imageUrl: p['imageUrl'],
          initialLikes: p['_count']['likes'],
          initialComments: p['_count']['comments'],
          isLikedByMe: p['isLikedByMe'] == true,
        );
      }).toList();

      state = state.copyWith(
        users: AsyncValue.data(usersMap),
        posts: AsyncValue.data(postsList),
        chats: initialChats,
      );
    } catch (e, st) {
      state = state.copyWith(
        users: AsyncValue.error(e, st),
        posts: AsyncValue.error(e, st),
      );
    }
  }

  String _formatTimeAgo(DateTime date) {
    return timeago.format(date, locale: 'tr');
  }

  Future<void> toggleLike(String postId) async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      final isLiked = await repo.toggleLike(int.parse(postId));
      
      if (state.posts.hasValue) {
        final newPosts = state.posts.value!.map((post) {
          if (post.id == postId) {
            return post.copyWith(
              isLikedByMe: isLiked,
              initialLikes: post.initialLikes + (isLiked ? 1 : -1),
            );
          }
          return post;
        }).toList();
        state = state.copyWith(posts: AsyncValue.data(newPosts));
      }
    } catch (e) {
      // Hata durumu
    }
  }

  Future<void> addPost(String content, String? imagePath) async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.createPost(content, imagePath);
      await _fetchInitialData(); // Yeniden yükle
    } catch (e) {
      // Hata durumu
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.deletePost(int.parse(postId));
      await _fetchInitialData(); // Gönderileri yenile
    } catch (e) {
      // Hata durumu
    }
  }

  Future<List<PostComment>> fetchComments(String postId) async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      final fetched = await repo.getComments(int.parse(postId));
      return fetched.map((c) {
        return PostComment(
          id: c['id'].toString(),
          authorId: c['user']['id'].toString(),
          authorName: '${c['user']['firstName']} ${c['user']['lastName']}',
          authorAvatar: c['user']['photoUrl'] ?? 'assets/avatars/male_average.png',
          timeAgo: _formatTimeAgo(DateTime.parse(c['createdAt'])),
          content: c['content'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addComment(String postId, String content) async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.createComment(int.parse(postId), content);
      await _fetchInitialData(); // Yorum sayısını güncellemek için yenile
    } catch (e) {
      // Hata durumu
    }
  }

  Future<void> fetchMessages(String userId) async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      final messages = await repo.getMessages(int.parse(userId));
      
      final chatMessages = messages.map((m) {
        return ChatMessage(
          text: m['content'],
          isMine: m['senderId'].toString() != userId,
          time: _formatTimeAgo(DateTime.parse(m['createdAt'])),
        );
      }).toList();

      final newChats = Map<String, ChatSession>.from(state.chats);
      newChats[userId] = ChatSession(userId: userId, messages: chatMessages);
      state = state.copyWith(chats: newChats);
    } catch (e) {
      // Hata durumu
    }
  }

  Future<void> addMessage(String userId, String text) async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.sendMessage(int.parse(userId), text);
      await fetchMessages(userId);
    } catch (e) {
      // Hata durumu
    }
  }

  Future<void> toggleFriendStatus(String userId) async {
    if (state.users.hasValue) {
      final user = state.users.value![userId];
      if (user != null) {
        try {
          final repo = ref.read(communityRepositoryProvider);
          final statusString = await repo.toggleFriendStatus(int.parse(userId));
          
          final newStatus = statusString == 'accepted' 
              ? FriendStatus.accepted 
              : FriendStatus.none;

          final newUsers = Map<String, SocialUser>.from(state.users.value!);
          newUsers[userId] = user.copyWith(friendStatus: newStatus);
          state = state.copyWith(users: AsyncValue.data(newUsers));
        } catch (e) {
          // Hata durumu
        }
      }
    }
  }
}

final communityProvider = NotifierProvider<CommunityNotifier, CommunityState>(() {
  return CommunityNotifier();
});
