import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';

class AdminStoresScreen extends StatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen> {
  List<Store> _stores = [];
  StoreDetail? _selectedStoreDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final stores = await api.getStores();
      if (mounted) {
        setState(() {
          _stores = stores;
          _isLoading = false;
        });
        if (stores.isNotEmpty) {
          _loadStoreDetail(stores.first.id);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStoreDetail(String storeId) async {
    try {
      final api = context.read<ApiClient>();
      final detail = await api.getStoreDetail(storeId);
      if (mounted) {
        setState(() => _selectedStoreDetail = detail);
      }
    } catch (_) {}
  }

  Future<void> _showCreateStoreDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New M&S Store Location'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Store Name')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && addressCtrl.text.isNotEmpty) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Create Store'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final api = context.read<ApiClient>();
        await api.createStore(
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
          address: addressCtrl.text.trim(),
          latitude: 14.5515,
          longitude: 121.0505,
        );
        _loadStores();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create store: $e')));
      }
    }
  }

  Future<void> _showCreateMenuItemDialog() async {
    if (_selectedStoreDetail == null) return;
    final store = _selectedStoreDetail!.store;

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Menu Item to ${store.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price (₱)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && double.tryParse(priceCtrl.text) != null) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final api = context.read<ApiClient>();
        await api.createMenuItem(
          storeId: store.id,
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
          price: double.parse(priceCtrl.text.trim()),
        );
        _loadStoreDetail(store.id);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add item: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stores Master List
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Stores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Store'),
                      onPressed: _showCreateStoreDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    child: ListView.separated(
                      itemCount: _stores.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (ctx, idx) {
                        final store = _stores[idx];
                        final isSelected = _selectedStoreDetail?.store.id == store.id;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: AppColors.primary.withOpacity(0.08),
                          title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(store.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () => _loadStoreDetail(store.id),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Menu Items Detail View
          Expanded(
            child: _selectedStoreDetail == null
                ? const EmptyStateView(
                    icon: Icons.storefront,
                    title: 'Select a Store',
                    description: 'Select a store on the left to view and manage its menu items.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedStoreDetail!.store.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                              Text(_selectedStoreDetail!.store.address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Menu Item'),
                            onPressed: _showCreateMenuItemDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Card(
                          child: _selectedStoreDetail!.items.isEmpty
                              ? const EmptyStateView(
                                  icon: Icons.restaurant_menu,
                                  title: 'No Menu Items',
                                  description: 'Add dishes and ready meals to this store\'s menu.',
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _selectedStoreDetail!.items.length,
                                  separatorBuilder: (_, __) => const Divider(height: 20, color: AppColors.border),
                                  itemBuilder: (ctx, idx) {
                                    final item = _selectedStoreDetail!.items[idx];
                                    return Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.fastfood, color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                              if (item.description != null)
                                                Text(item.description!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1),
                                            ],
                                          ),
                                        ),
                                        Text(Formatters.currency(item.price), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
