import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';
import '../../state/cart_state.dart';
import '../cart/cart_screen.dart';

class StoreMenuScreen extends StatefulWidget {
  final Store store;

  const StoreMenuScreen({super.key, required this.store});

  @override
  State<StoreMenuScreen> createState() => _StoreMenuScreenState();
}

class _StoreMenuScreenState extends State<StoreMenuScreen> {
  StoreDetail? _detail;
  bool _isLoading = true;
  String? _error;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final detail = await api.getStoreDetail(widget.store.id);
      setState(() {
        _detail = detail;
        if (detail.categories.isNotEmpty) {
          _selectedCategoryId = detail.categories.first.id;
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddToCartBottomSheet(MenuItem item) {
    int quantity = 1;
    final instructionsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final cart = context.read<CartState>();
            final hasConflict = cart.activeStore != null && cart.activeStore!.id != widget.store.id;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                      Text(Formatters.currency(item.price), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: 8),
                    Text(item.description!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                  if (hasConflict) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(8)),
                      child: const Text(
                        'Adding from this store will replace items in your current cart.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF856404)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: instructionsCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Special instructions (e.g. less sauce)',
                      labelText: 'Special Notes',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: quantity > 1 ? () => setModalState(() => quantity--) : null,
                          ),
                          Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setModalState(() => quantity++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: 'Add to Cart • ${Formatters.currency(item.price * quantity)}',
                    onPressed: () {
                      cart.addItem(widget.store, item, quantity: quantity, specialInstructions: instructionsCtrl.text.trim().isNotEmpty ? instructionsCtrl.text.trim() : null);
                      Navigator.of(modalCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${item.name} to cart'),
                          action: SnackBarAction(
                            label: 'View Cart',
                            textColor: AppColors.accent,
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.store.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: !cart.isEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: AppButton(
                text: 'View Cart (${cart.totalItemCount} items) • ${Formatters.currency(cart.subtotal)}',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)));
    }

    if (_error != null || _detail == null) {
      return EmptyStateView(
        icon: Icons.error_outline,
        title: 'Unable to Load Menu',
        description: _error ?? 'Store menu is unavailable.',
        actionText: 'Retry',
        onAction: _loadMenu,
      );
    }

    final categories = _detail!.categories;
    final items = _detail!.items;
    final filteredItems = _selectedCategoryId == null
        ? items
        : items.where((i) => i.categoryId == _selectedCategoryId).toList();

    return Column(
      children: [
        if (categories.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: categories.length + 1,
              itemBuilder: (ctx, idx) {
                if (idx == 0) {
                  final isSelected = _selectedCategoryId == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategoryId = null),
                    ),
                  );
                }
                final cat = categories[idx - 1];
                final isSelected = _selectedCategoryId == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat.name),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: filteredItems.isEmpty
              ? const EmptyStateView(
                  icon: Icons.fastfood_outlined,
                  title: 'No Items in Category',
                  description: 'Check out other categories in this store.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 24, color: AppColors.border),
                  itemBuilder: (ctx, idx) {
                    final item = filteredItems[idx];
                    return InkWell(
                      onTap: item.isAvailable ? () => _showAddToCartBottomSheet(item) : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                if (item.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(item.description!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                                const SizedBox(height: 8),
                                Text(Formatters.currency(item.price), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Icon(Icons.lunch_dining, size: 36, color: AppColors.primary.withOpacity(0.4)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
