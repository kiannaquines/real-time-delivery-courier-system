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
  StoreDetail? _storeDetail;
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'All';

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
      setState(() => _storeDetail = detail);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showItemDetailModal(MenuItem item) {
    int quantity = 1;
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: 6),
                    Text(item.description!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    Formatters.currency(item.price),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.brandPrimary),
                  ),
                  const Divider(height: 32),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Special Instructions (Optional)',
                      hintText: 'e.g. Less spicy, separate sauce, extra napkins',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_rounded, size: 18),
                              onPressed: quantity > 1 ? () => setModalState(() => quantity--) : null,
                            ),
                            Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, size: 18),
                              onPressed: () => setModalState(() => quantity++),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          text: 'Add to Cart • ${Formatters.currency(item.price * quantity)}',
                          onPressed: () {
                            context.read<CartState>().addItem(
                                  widget.store,
                                  item,
                                  quantity: quantity,
                                  specialInstructions: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                                );
                            Navigator.of(modalCtx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item.name} added to cart!'),
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'View Cart',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => const CartScreen(),
                                    ));
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.store.name)),
        body: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary))),
      );
    }

    if (_error != null || _storeDetail == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.store.name)),
        body: EmptyStateView(
          icon: Icons.error_outline,
          title: 'Unable to Load Menu',
          description: _error ?? 'Failed to load restaurant details.',
          actionText: 'Retry',
          onAction: _loadMenu,
        ),
      );
    }

    final categories = ['All', ..._storeDetail!.categories.map((c) => c.name)];
    final filteredItems = _storeDetail!.items.where((i) {
      if (_selectedCategory == 'All') return true;
      final cat = _storeDetail!.categories.firstWhere((c) => c.name == _selectedCategory, orElse: () => _storeDetail!.categories.first);
      return i.categoryId == cat.id;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.store.name, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: cart.itemCount > 0,
              label: Text('${cart.itemCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CartScreen(),
              ));
            },
          ),
        ],
      ),
      bottomNavigationBar: cart.itemCount > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppButton(
                  text: 'View Cart (${cart.totalItemCount} items) • ${Formatters.currency(cart.subtotal)}',
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CartScreen(),
                    ));
                  },
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Restaurant Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.heroLightGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.premiumShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.store.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text(widget.store.address, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                if (widget.store.description != null) ...[
                  const SizedBox(height: 8),
                  Text(widget.store.description!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.delivery_dining_rounded, size: 16, color: AppColors.brandPrimary),
                        SizedBox(width: 6),
                        Text('₱49 Delivery Fee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandPrimary)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.payments_outlined, size: 16, color: AppColors.textSecondary),
                        SizedBox(width: 6),
                        Text('Cash on Delivery (COD)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Categories Chips Bar
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, idx) {
                final cat = categories[idx];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppColors.brandPrimaryLight,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.brandPrimary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Dishes List
          if (filteredItems.isEmpty)
            const EmptyStateView(
              icon: Icons.restaurant_menu_rounded,
              title: 'No Items in Category',
              description: 'Please select another category.',
            )
          else
            ...filteredItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Card(
                  child: InkWell(
                    onTap: () => _showItemDetailModal(item),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimaryLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.lunch_dining_rounded, size: 30, color: AppColors.brandPrimary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)),
                                if (item.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(item.description!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  Formatters.currency(item.price),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.brandPrimary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_rounded, size: 20, color: AppColors.brandPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
