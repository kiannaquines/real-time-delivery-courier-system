import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';

class SavedAddressesScreen extends StatefulWidget {
  final bool isSelecting;
  const SavedAddressesScreen({super.key, this.isSelecting = false});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<Address> _addresses = [];
  bool _isLoading = true;
  String? _error;

  final List<Map<String, dynamic>> _kabacanPresets = const [
    {
      'label': 'Home (Purok Miracle)',
      'address': 'Purok Miracle, Poblacion, Kabacan, Cotabato',
      'lat': 7.1280,
      'lng': 124.8310,
      'icon': Icons.home_rounded,
    },
    {
      'label': 'USM Campus (Gate 1)',
      'address': 'USM Avenue, University of Southern Mindanao, Kabacan',
      'lat': 7.1245,
      'lng': 124.8350,
      'icon': Icons.school_rounded,
    },
    {
      'label': 'Barangay Osias',
      'address': 'Barangay Osias Highway, Kabacan, Cotabato',
      'lat': 7.1350,
      'lng': 124.8250,
      'icon': Icons.location_city_rounded,
    },
    {
      'label': 'Barangay Kayaga',
      'address': 'Barangay Kayaga Junction, Kabacan, Cotabato',
      'lat': 7.1420,
      'lng': 124.8150,
      'icon': Icons.storefront_rounded,
    },
    {
      'label': 'Barangay Bannawag',
      'address': 'Purok 3, Barangay Bannawag, Kabacan, Cotabato',
      'lat': 7.1210,
      'lng': 124.8450,
      'icon': Icons.pin_drop_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final addresses = await api.getAddresses();
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setDefaultAddress(Address addr) async {
    try {
      final api = context.read<ApiClient>();
      await api.setDefaultAddress(addr.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Default delivery address set to ${addr.label}')),
      );
      _loadAddresses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update default address: $e')),
      );
    }
  }

  Future<void> _deleteAddress(Address addr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Address',
        content: 'Are you sure you want to remove "${addr.label}" from your saved locations?',
        confirmText: 'Delete',
        isDestructive: true,
      ),
    );

    if (confirmed == true) {
      try {
        final api = context.read<ApiClient>();
        await api.deleteAddress(addr.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted successfully.')),
        );
        _loadAddresses();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete address: $e')),
        );
      }
    }
  }

  void _showAddAddressDialog() {
    String selectedTag = 'Home';
    final labelCtrl = TextEditingController(text: 'Home');
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    double lat = 7.1280;
    double lng = 124.8310;
    bool isDefault = _addresses.isEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add New Address',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(modalCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Kabacan Location Presets
                const Text('Popular Locations in Kabacan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _kabacanPresets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, idx) {
                      final p = _kabacanPresets[idx];
                      return ActionChip(
                        avatar: Icon(p['icon'] as IconData, size: 14, color: AppColors.brandPrimary),
                        label: Text(p['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        backgroundColor: AppColors.brandPrimaryLight,
                        side: BorderSide.none,
                        onPressed: () {
                          setModalState(() {
                            labelCtrl.text = p['label'] as String;
                            addressCtrl.text = p['address'] as String;
                            lat = p['lat'] as double;
                            lng = p['lng'] as double;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Address Label Tag Selector
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Home', 'Work', 'School', 'Other'].map((tag) {
                    final isSel = selectedTag == tag;
                    return ChoiceChip(
                      label: Text(tag),
                      selected: isSel,
                      selectedColor: AppColors.brandPrimary,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setModalState(() {
                            selectedTag = tag;
                            if (labelCtrl.text.isEmpty || ['Home', 'Work', 'School', 'Other'].contains(labelCtrl.text)) {
                              labelCtrl.text = tag;
                            }
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Address Name / Label
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Label (e.g. Home, Dorm, Office)',
                    prefixIcon: Icon(Icons.bookmark_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),

                // Full Street Address Line
                TextField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Street Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    hintText: 'e.g. Purok Miracle, Poblacion, Kabacan, Cotabato',
                  ),
                ),
                const SizedBox(height: 12),

                // Landmarks & Delivery Notes
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Landmark / Delivery Notes (Optional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                    hintText: 'e.g. Green gate beside sari-sari store',
                  ),
                ),
                const SizedBox(height: 12),

                // Default Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Set as default address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  value: isDefault,
                  activeColor: AppColors.brandPrimary,
                  onChanged: (val) => setModalState(() => isDefault = val),
                ),
                const SizedBox(height: 16),

                // Save Button
                ElevatedButton(
                  onPressed: () async {
                    if (addressCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid street address.')),
                      );
                      return;
                    }

                    try {
                      final api = context.read<ApiClient>();
                      final newAddr = await api.createAddress(
                        label: labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : selectedTag,
                        addressLine: addressCtrl.text.trim(),
                        latitude: lat,
                        longitude: lng,
                        deliveryNotes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                        isDefault: isDefault,
                      );

                      if (modalCtx.mounted) Navigator.of(modalCtx).pop();

                      if (widget.isSelecting && mounted) {
                        Navigator.of(context).pop(newAddr);
                      } else {
                        _loadAddresses();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save address: $e')),
                      );
                    }
                  },
                  child: const Text('Save Address'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('home')) return Icons.home_rounded;
    if (lower.contains('work') || lower.contains('office')) return Icons.business_rounded;
    if (lower.contains('school') || lower.contains('usm') || lower.contains('dorm')) return Icons.school_rounded;
    return Icons.pin_drop_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isSelecting ? 'Select Delivery Address' : 'Saved Addresses',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded, color: AppColors.brandPrimary),
            tooltip: 'Add Address',
            onPressed: _showAddAddressDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary)))
          : _error != null
              ? EmptyStateView(
                  icon: Icons.error_outline,
                  title: 'Failed to load addresses',
                  description: _error!,
                  actionText: 'Retry',
                  onAction: _loadAddresses,
                )
              : _addresses.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const EmptyStateView(
                              icon: Icons.location_off_outlined,
                              title: 'No Saved Addresses',
                              description: 'Add your delivery addresses for faster checkout.',
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_location_alt_rounded),
                              label: const Text('Add Address'),
                              onPressed: _showAddAddressDialog,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) {
                        final addr = _addresses[idx];
                        return Card(
                          elevation: addr.isDefault ? 2 : 0.8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide.none,
                          ),
                          child: InkWell(
                            onTap: widget.isSelecting ? () => Navigator.of(context).pop(addr) : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: addr.isDefault ? AppColors.brandPrimary : AppColors.brandPrimaryLight,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _getIconForLabel(addr.label),
                                          size: 18,
                                          color: addr.isDefault ? Colors.white : AppColors.brandPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    addr.label,
                                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (addr.isDefault) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.brandPrimaryLight,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Text(
                                                      'Default',
                                                      style: TextStyle(
                                                        color: AppColors.brandPrimary,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              addr.addressLine,
                                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                                        onSelected: (action) {
                                          if (action == 'default') {
                                            _setDefaultAddress(addr);
                                          } else if (action == 'delete') {
                                            _deleteAddress(addr);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          if (!addr.isDefault)
                                            const PopupMenuItem(
                                              value: 'default',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.brandPrimary),
                                                  SizedBox(width: 10),
                                                  Text('Set as Default', style: TextStyle(fontWeight: FontWeight.w700)),
                                                ],
                                              ),
                                            ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                                SizedBox(width: 10),
                                                Text('Delete Address', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (addr.deliveryNotes != null && addr.deliveryNotes!.isNotEmpty) ...[
                                    const Divider(height: 20),
                                    Row(
                                      children: [
                                        const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Note: ${addr.deliveryNotes!}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: _showAddAddressDialog,
      ),
    );
  }
}
