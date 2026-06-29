import '../../core/api_client.dart';

class WishlistRepository {
  Future<List<dynamic>> fetchItems() async {
    final response = await apiClient.dio.get('/wishlists');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createItem(String title, {String? link, double? price}) async {
    final response = await apiClient.dio.post('/wishlists', data: {
      'title': title,
      if (link != null && link.isNotEmpty) 'link': link,
      if (price != null) 'price': price,
    });
    return response.data;
  }

  Future<void> updateItem(int id, Map<String, dynamic> data) async {
    await apiClient.dio.patch('/wishlists/$id', data: data);
  }

  Future<void> reorderItems(List<Map<String, dynamic>> items) async {
    await apiClient.dio.patch('/wishlists/reorder', data: items);
  }

  Future<void> deleteItem(int id) async {
    await apiClient.dio.delete('/wishlists/$id');
  }
}
