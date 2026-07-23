import '../../core/api_client.dart';

class CommunityRepository {
  Future<List<dynamic>> getPosts() async {
    final response = await apiClient.dio.get('/community/posts');
    return response.data;
  }

  Future<Map<String, dynamic>> createPost(String content, String? imageUrl) async {
    final response = await apiClient.dio.post(
      '/community/posts',
      data: {
        'content': content,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    );
    return response.data;
  }

  Future<bool> toggleLike(int postId) async {
    final response = await apiClient.dio.post('/community/posts/$postId/like');
    return response.data['liked'];
  }

  Future<List<dynamic>> getUsers() async {
    final response = await apiClient.dio.get('/community/users');
    return response.data;
  }

  Future<List<dynamic>> getMessages(int userId) async {
    final response = await apiClient.dio.get('/community/messages/$userId');
    return response.data;
  }

  Future<Map<String, dynamic>> sendMessage(int userId, String content) async {
    final response = await apiClient.dio.post(
      '/community/messages/$userId',
      data: {'content': content},
    );
    return response.data;
  }

  Future<void> deletePost(int postId) async {
    await apiClient.dio.delete('/community/posts/$postId');
  }

  Future<List<dynamic>> getComments(int postId) async {
    final response = await apiClient.dio.get('/community/posts/$postId/comments');
    return response.data;
  }

  Future<Map<String, dynamic>> createComment(int postId, String content) async {
    final response = await apiClient.dio.post(
      '/community/posts/$postId/comments',
      data: {'content': content},
    );
    return response.data;
  }

  Future<String> toggleFriendStatus(int userId) async {
    final response = await apiClient.dio.post('/community/friends/$userId');
    return response.data['status'];
  }

  Future<List<dynamic>> getConversations() async {
    final response = await apiClient.dio.get('/community/conversations');
    return response.data;
  }
}
