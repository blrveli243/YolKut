import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wishlist_repository.dart';

final wishlistRepositoryProvider = Provider((ref) => WishlistRepository());

class WishlistNotifier extends AsyncNotifier<List<dynamic>> {
  @override
  Future<List<dynamic>> build() async {
    return _fetchItems();
  }

  Future<List<dynamic>> _fetchItems() async {
    final repo = ref.read(wishlistRepositoryProvider);
    return await repo.fetchItems();
  }

  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchItems());
  }

  Future<void> addItem(String title, {String? link, double? price}) async {
    try {
      final repo = ref.read(wishlistRepositoryProvider);
      final newItem = await repo.createItem(title, link: link, price: price);

      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newItem]);
      } else {
        await loadItems();
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> togglePurchased(int id, bool currentStatus) async {
    try {
      final repo = ref.read(wishlistRepositoryProvider);
      await repo.updateItem(id, {'isPurchased': !currentStatus});

      if (state.hasValue) {
        final updatedList = state.value!.map((item) {
          if (item['id'] == id) {
            return {...item, 'isPurchased': !currentStatus};
          }
          return item;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (!state.hasValue) return;

    final list = List<dynamic>.from(state.value!);

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // Update local state immediately for fast UI response
    state = AsyncValue.data(list);

    // Prepare payload for backend
    final payload = list.asMap().entries.map((e) {
      return {'id': e.value['id'], 'orderIndex': e.key};
    }).toList();

    try {
      final repo = ref.read(wishlistRepositoryProvider);
      await repo.reorderItems(payload);
    } catch (e) {
      // Revert if error
      await loadItems();
    }
  }

  Future<void> removeItem(int id) async {
    try {
      final repo = ref.read(wishlistRepositoryProvider);
      await repo.deleteItem(id);

      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.where((item) => item['id'] != id).toList(),
        );
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final wishlistProvider = AsyncNotifierProvider<WishlistNotifier, List<dynamic>>(
  () {
    return WishlistNotifier();
  },
);
