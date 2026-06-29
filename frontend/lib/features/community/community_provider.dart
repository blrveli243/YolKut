import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FriendStatus { none, pending, accepted }

class SocialUser {
  final String id;
  final String name;
  final String avatar;
  final String bio;
  final FriendStatus friendStatus;

  SocialUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.bio,
    this.friendStatus = FriendStatus.none,
  });

  SocialUser copyWith({FriendStatus? friendStatus}) {
    return SocialUser(
      id: id,
      name: name,
      avatar: avatar,
      bio: bio,
      friendStatus: friendStatus ?? this.friendStatus,
    );
  }
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
  final List<Post> posts;
  final Map<String, SocialUser> users;
  final Map<String, ChatSession> chats;

  CommunityState({required this.posts, required this.users, required this.chats});

  CommunityState copyWith({
    List<Post>? posts,
    Map<String, SocialUser>? users,
    Map<String, ChatSession>? chats,
  }) {
    return CommunityState(
      posts: posts ?? this.posts,
      users: users ?? this.users,
      chats: chats ?? this.chats,
    );
  }
}

class CommunityNotifier extends Notifier<CommunityState> {
  @override
  CommunityState build() {
    final Map<String, SocialUser> initialUsers = {
      'u1': SocialUser(
        id: 'u1',
        name: 'Ahmet Yılmaz',
        avatar: 'assets/avatars/male_slim.png',
        bio: 'Fitness tutkunu, yeni hedeflere doğru! 🏋️‍♂️',
      ),
      'u2': SocialUser(
        id: 'u2',
        name: 'Ayşe Demir',
        avatar: 'assets/avatars/female_slim.png',
        bio: 'Sağlıklı yaşam ve dengeli beslenme üzerine paylaşımlar. 🥗',
        friendStatus: FriendStatus.accepted,
      ),
      'u3': SocialUser(
        id: 'u3',
        name: 'Can Korkmaz',
        avatar: 'assets/avatars/male_overweight.png',
        bio: 'Maraton koşucusu adayı 🏃‍♂️',
      ),
    };

    final List<Post> initialPosts = [
      Post(
        id: '1',
        authorId: 'u1',
        authorName: 'Ahmet Yılmaz',
        authorAvatar: 'assets/avatars/male_slim.png',
        timeAgo: '2 saat önce',
        content: 'Bugün göğüs antrenmanını bitirdim! Harika bir histi. 💪',
        initialLikes: 24,
        initialComments: 5,
      ),
      Post(
        id: '2',
        authorId: 'u2',
        authorName: 'Ayşe Demir',
        authorAvatar: 'assets/avatars/female_slim.png',
        timeAgo: '4 saat önce',
        content: 'Öğle yemeği için hazırladığım sağlıklı somon salatası. Bol protein! 🥗🐟',
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop&q=60',
        initialLikes: 112,
        initialComments: 18,
      ),
      Post(
        id: '3',
        authorId: 'u3',
        authorName: 'Can Korkmaz',
        authorAvatar: 'assets/avatars/male_overweight.png',
        timeAgo: '6 saat önce',
        content: 'İlk defa 5 km koştum, hedefim yıl sonuna kadar 10 km! 🏃‍♂️',
        initialLikes: 45,
        initialComments: 3,
      ),
    ];

    final Map<String, ChatSession> initialChats = {
      'u2': ChatSession(
        userId: 'u2',
        messages: [
          ChatMessage(text: 'Merhaba, somon tarifini alabilir miyim?', isMine: true, time: '14:30'),
          ChatMessage(text: 'Selam! Tabii ki, birazdan yazıyorum.', isMine: false, time: '14:35'),
        ],
      )
    };

    return CommunityState(posts: initialPosts, users: initialUsers, chats: initialChats);
  }

  void toggleLike(String postId) {
    final newPosts = state.posts.map((post) {
      if (post.id == postId) {
        final isLiked = !post.isLikedByMe;
        return post.copyWith(
          isLikedByMe: isLiked,
          initialLikes: post.initialLikes + (isLiked ? 1 : -1),
        );
      }
      return post;
    }).toList();
    state = state.copyWith(posts: newPosts);
  }

  void toggleFriendStatus(String userId) {
    final user = state.users[userId];
    if (user == null) return;

    FriendStatus newStatus;
    if (user.friendStatus == FriendStatus.none) {
      newStatus = FriendStatus.pending;
    } else if (user.friendStatus == FriendStatus.pending) {
      newStatus = FriendStatus.none; // Cancel request
    } else {
      newStatus = FriendStatus.none; // Unfriend
    }

    final newUsers = Map<String, SocialUser>.from(state.users);
    newUsers[userId] = user.copyWith(friendStatus: newStatus);
    state = state.copyWith(users: newUsers);
  }

  void addMessage(String userId, String text) {
    final chat = state.chats[userId] ?? ChatSession(userId: userId, messages: []);
    final newMessages = List<ChatMessage>.from(chat.messages)
      ..add(ChatMessage(text: text, isMine: true, time: 'Şimdi'));
    
    final newChats = Map<String, ChatSession>.from(state.chats);
    newChats[userId] = ChatSession(userId: userId, messages: newMessages);
    state = state.copyWith(chats: newChats);
  }

  void addPost(String content, String? imagePath) {
    final newPost = Post(
      id: DateTime.now().toString(),
      authorId: 'me',
      authorName: 'Sen', 
      authorAvatar: 'assets/avatars/male_average.png',
      timeAgo: 'Az önce',
      content: content,
      imageUrl: imagePath,
      initialLikes: 0,
      initialComments: 0,
    );
    state = state.copyWith(posts: [newPost, ...state.posts]);
  }
}

final communityProvider = NotifierProvider<CommunityNotifier, CommunityState>(() {
  return CommunityNotifier();
});
