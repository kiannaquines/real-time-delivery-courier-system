import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';
import '../../state/cart_state.dart';
import '../tracking/order_tracking_screen.dart';
import '../profile/saved_addresses_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Address? _selectedAddress;
  List<Address> _savedAddresses = [];
  bool _isLoadingAddresses = true;
  final _notesCtrl = TextEditingController(text: 'Near USM Gate 1');
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final api = context.read<ApiClient>();
      final addresses = await api.getAddresses();
      if (mounted) {
        setState(() {
          _savedAddresses = addresses;
          _isLoadingAddresses = false;
          if (_selectedAddress == null && addresses.isNotEmpty) {
            _selectedAddress = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> _selectOrAddAddress() async {
    final selected = await Navigator.of(context).push<Address>(
      MaterialPageRoute(builder: (_) => const SavedAddressesScreen(isSelecting: true)),
    );
    if (selected != null && mounted) {
      setState(() => _selectedAddress = selected);
      _loadAddresses();
    }
  }

  Future<void> _placeOrder(CartState cart) async {
    if (cart.isEmpty || cart.activeStore == null) return;

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add a delivery address.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final order = await api.createOrder(
        storeId: cart.activeStore!.id,
        addressId: _selectedAddress!.id,
        items: cart.items
            .map((i) => {
                  'menu_item_id': i.item.id,
                  'quantity': i.quantity,
                  if (i.specialInstructions != null) 'special_instructions': i.specialInstructions,
                })
            .toList(),
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        idempotencyKey: 'order-${DateTime.now().millisecondsSinceEpoch}',
      );

      cart.clear();

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: order.id),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('ApiException: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();

    if (cart.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: EmptyStateView(
            icon: Icons.shopping_bag_outlined,
            title: 'Your Cart is Empty',
            description: 'Browse partner restaurants in Kabacan and add delicious dishes to your order.',
          ),
        ),
      );
    }

    const deliveryFee = 49.0;
    final totalAmount = cart.subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cart', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          TextButton(
            onPressed: () => cart.clear(),
            child: const Text('Clear', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(Formatters.currency(cart.subtotal), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery Fee', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('₱49.00', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total (COD)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  Text(
                    Formatters.currency(totalAmount),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.brandPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _placeOrder(cart),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Place Order (COD)'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.statusCancelledBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.statusCancelledFg.withOpacity(0.3)),
              ),
              child: Text(_error!, style: const TextStyle(color: AppColors.statusCancelledFg, fontSize: 13)),
            ),
            const SizedBox(height: 16),
          ],

          // Store Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.brandPrimaryLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.brandPrimary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ORDER FROM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(cart.activeStore!.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cart Items
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ...cart.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text(Formatters.currency(item.item.price), style: const TextStyle(fontSize: 13, color: AppColors.brandPrimary, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_rounded, size: 16),
                                  onPressed: () => cart.updateQuantity(item.item.id, item.quantity - 1),
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                IconButton(
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  onPressed: () => cart.updateQuantity(item.item.id, item.quantity + 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Delivery Address Selector Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.pin_drop_rounded, size: 18, color: AppColors.brandPrimary),
                          SizedBox(width: 8),
                          Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
                        label: Text(_selectedAddress != null ? 'Change' : 'Select'),
                        onPressed: _selectOrAddAddress,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingAddresses)
                    const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                  else if (_selectedAddress == null)
                    InkWell(
                      onTap: _selectOrAddAddress,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.brandPrimary.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_location_alt_rounded, color: AppColors.brandPrimary, size: 18),
                            SizedBox(width: 8),
                            Text('Choose or Add Delivery Address', style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _selectedAddress!.label,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              if (_selectedAddress!.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.brandPrimaryLight, borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brandPrimary)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_selectedAddress!.addressLine, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          if (_selectedAddress!.deliveryNotes != null && _selectedAddress!.deliveryNotes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Landmark: ${_selectedAddress!.deliveryNotes}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Notes (Optional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                      hintText: 'e.g. Ring doorbell, leave at front gate',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Notice (COD)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandPrimaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.payments_rounded, color: AppColors.brandPrimary, size: 24),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.brandPrimary)),
                      SizedBox(height: 2),
                      Text('Please prepare exact cash payment upon delivery.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
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
