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
        title: const Text('Add New Store'),
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
            child: const Text('Add Store'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final api = context.read<ApiClient>();
        await api.createStore(
          name: nameCtrl.text.trim(),
          address: addressCtrl.text.trim(),
          latitude: 7.1280,
          longitude: 124.8310,
          description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
        );
        _loadStores();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create store: $e')));
      }
    }
  }

  Future<void> _showAddMenuItemDialog(Store store) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Menu Item - ${store.name}'),
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
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary)));
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isNarrow = constraints.maxWidth < 950;
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : 24.0;

        final storeListWidget = Card(
          child: ListView.separated(
            shrinkWrap: isNarrow,
            physics: isNarrow ? const NeverScrollableScrollPhysics() : null,
            itemCount: _stores.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, idx) {
              final s = _stores[idx];
              final isSelected = _selectedStoreDetail?.store.id == s.id;
              return ListTile(
                selected: isSelected,
                selectedTileColor: AppColors.brandPrimaryLight,
                leading: CircleAvatar(
                  backgroundColor: isSelected ? AppColors.brandPrimary : AppColors.brandPrimaryLight,
                  child: Icon(Icons.storefront, color: isSelected ? Colors.white : AppColors.brandPrimary),
                ),
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(s.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _loadStoreDetail(s.id),
              );
            },
          ),
        );

        final detailWidget = _selectedStoreDetail == null
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.storefront_outlined, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'Select a store to view menu items',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedStoreDetail!.store.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                Text(_selectedStoreDetail!.store.address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ],
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Menu Item'),
                              onPressed: () => _showAddMenuItemDialog(_selectedStoreDetail!.store),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text('Menu Items (${_selectedStoreDetail!.items.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: isNarrow ? constraints.maxWidth - (padding * 2) : constraints.maxWidth - 400),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                              columns: const [
                                DataColumn(label: Text('Item Name', style: TextStyle(fontWeight: FontWeight.w800))),
                                DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.w800))),
                                DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.w800))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800))),
                              ],
                              rows: _selectedStoreDetail!.items.map((item) {
                                return DataRow(cells: [
                                  DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                                  DataCell(SizedBox(width: 220, child: Text(item.description ?? '—', overflow: TextOverflow.ellipsis))),
                                  DataCell(Text(Formatters.currency(item.price), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brandPrimary))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: item.isAvailable ? AppColors.brandAccentLight : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item.isAvailable ? 'Available' : 'Sold Out',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: item.isAvailable ? AppColors.brandAccent : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

        return Padding(
          padding: EdgeInsets.all(padding),
          child: isNarrow
              ? ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Stores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Store'),
                          onPressed: _showCreateStoreDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    storeListWidget,
                    const SizedBox(height: 20),
                    detailWidget,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          Expanded(child: storeListWidget),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(child: detailWidget),
                  ],
                ),
        );
      },
    );
  }
}
