import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wishlist_provider.dart';

class WishlistSheet extends ConsumerStatefulWidget {
  const WishlistSheet({super.key});

  @override
  ConsumerState<WishlistSheet> createState() => _WishlistSheetState();
}

class _WishlistSheetState extends ConsumerState<WishlistSheet> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final priceStr = _priceController.text.replaceAll(',', '.');
    final price = double.tryParse(priceStr);
    final link = _linkController.text.trim();

    ref
        .read(wishlistProvider.notifier)
        .addItem(title, link: link, price: price);

    _titleController.clear();
    _priceController.clear();
    _linkController.clear();
    setState(() {
      _isAdding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wishlistProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alacaklarım & İsteklerim',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppColors.info,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _isAdding = !_isAdding;
                    });
                  },
                ),
              ],
            ),
          ),

          if (_isAdding) _buildAddForm(),

          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Hata: $err',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'Henüz istek listenizde bir şey yok.',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  onReorder: (oldIndex, newIndex) {
                    ref
                        .read(wishlistProvider.notifier)
                        .reorder(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isPurchased = item['isPurchased'] ?? false;

                    return Dismissible(
                      key: ValueKey(item['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        ref
                            .read(wishlistProvider.notifier)
                            .removeItem(item['id']);
                      },
                      child: Card(
                        key: ValueKey(item['id']),
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: GestureDetector(
                            onTap: () {
                              ref
                                  .read(wishlistProvider.notifier)
                                  .togglePurchased(item['id'], isPurchased);
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPurchased
                                    ? AppColors.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isPurchased
                                      ? AppColors.primary
                                      : Theme.of(context).colorScheme.onSurface
                                            .withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: isPurchased
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          title: Text(
                            item['title'],
                            style: TextStyle(
                              color: isPurchased
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withValues(alpha: 0.5)
                                  : Theme.of(context).colorScheme.onSurface,
                              decoration: isPurchased
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle:
                              (item['price'] != null || item['link'] != null)
                              ? Row(
                                  children: [
                                    if (item['price'] != null)
                                      Text(
                                        '${item['price']} TL',
                                        style: const TextStyle(
                                          color: AppColors.info,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    if (item['price'] != null &&
                                        item['link'] != null)
                                      const SizedBox(width: 8),
                                    if (item['link'] != null &&
                                        item['link'].toString().isNotEmpty)
                                      Icon(
                                        Icons.link,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                  ],
                                )
                              : null,
                          trailing: const Icon(
                            Icons.drag_handle,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Ne almak istiyorsunuz?',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Fiyat (Opsiyonel)',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    icon: const Icon(Icons.attach_money, color: Colors.grey),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _linkController,
                  decoration: InputDecoration(
                    hintText: 'Link (Opsiyonel)',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    icon: const Icon(Icons.link, color: Colors.grey),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Listeye Ekle',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
