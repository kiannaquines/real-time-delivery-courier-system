import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';
import '../../state/cart_state.dart';
import '../tracking/order_tracking_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Address> _addresses = [];
  Address? _selectedAddress;
  bool _isLoadingAddresses = true;
  bool _isSubmitting = false;
  double _deliveryFee = 49.00;
  int _estimatedDurationMins = 25;
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
          _addresses = addresses;
          if (addresses.isNotEmpty) {
            _selectedAddress = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
            _calculateDeliveryFee();
          }
          _isLoadingAddresses = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> _calculateDeliveryFee() async {
    final cart = context.read<CartState>();
    if (cart.activeStore == null || _selectedAddress == null) return;

    try {
      final api = context.read<ApiClient>();
      final preview = await api.previewFee(
        storeId: cart.activeStore!.id,
        deliveryLatitude: _selectedAddress!.latitude,
        deliveryLongitude: _selectedAddress!.longitude,
      );
      if (mounted) {
        setState(() {
          _deliveryFee = (preview['total_delivery_fee'] as num).toDouble();
          _estimatedDurationMins = preview['estimated_duration_minutes'] as int;
        });
      }
    } catch (_) {}
  }

  Future<void> _addNewAddressDialog() async {
    final labelCtrl = TextEditingController(text: 'Home');
    final lineCtrl = TextEditingController(text: 'Unit 12A Tower 1, BGC, Taguig');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Delivery Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label (e.g. Home, Office)')),
            const SizedBox(height: 12),
            TextField(controller: lineCtrl, decoration: const InputDecoration(labelText: 'Address Line')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && lineCtrl.text.isNotEmpty) {
      try {
        final api = context.read<ApiClient>();
        final newAddr = await api.createAddress(
          label: labelCtrl.text.trim(),
          addressLine: lineCtrl.text.trim(),
          latitude: 14.5540 + Random().nextDouble() * 0.01,
          longitude: 121.0480 + Random().nextDouble() * 0.01,
          isDefault: true,
        );
        setState(() {
          _addresses.insert(0, newAddr);
          _selectedAddress = newAddr;
        });
        _calculateDeliveryFee();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save address: $e')));
      }
    }
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartState>();
    if (cart.isEmpty || _selectedAddress == null || cart.activeStore == null) {
      setState(() => _error = 'Please select a delivery address.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final idempotencyKey = 'order-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99999)}';

      final itemsPayload = cart.items.map((i) => {
        'menu_item_id': i.item.id,
        'quantity': i.quantity,
        if (i.specialInstructions != null) 'special_instructions': i.specialInstructions,
      }).toList();

      final order = await api.createOrder(
        storeId: cart.activeStore!.id,
        addressId: _selectedAddress!.id,
        items: itemsPayload,
        idempotencyKey: idempotencyKey,
      );

      cart.clear();

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: order.id),
        ));
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Cart')),
        body: EmptyStateView(
          icon: Icons.remove_shopping_cart_outlined,
          title: 'Your Cart is Empty',
          description: 'Explore our stores and add fresh meals to your cart.',
          actionText: 'Browse Stores',
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    final totalAmount = cart.subtotal + _deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Cart')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('New Address'),
                            onPressed: _addNewAddressDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_addresses.isEmpty)
                        TextButton(
                          onPressed: _addNewAddressDialog,
                          child: const Text('Add an address to proceed'),
                        )
                      else
                        DropdownButtonFormField<Address>(
                          value: _selectedAddress,
                          items: _addresses.map((a) => DropdownMenuItem(
                            value: a,
                            child: Text('${a.label}: ${a.addressLine}', overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (val) {
                            setState(() => _selectedAddress = val);
                            _calculateDeliveryFee();
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cart.activeStore!.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      const Divider(height: 20, color: AppColors.border),
                      ...cart.items.map((cartItem) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cartItem.item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                    Text(Formatters.currency(cartItem.item.price), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                                    onPressed: () => cart.updateQuantity(cartItem.item.id, cartItem.quantity - 1),
                                  ),
                                  Text('${cartItem.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                    onPressed: () => cart.updateQuantity(cartItem.item.id, cartItem.quantity + 1),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Text(Formatters.currency(cartItem.subtotal), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment Method', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.payments_outlined, color: AppColors.primary),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  Text('Pay our rider in cash upon receiving your order.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary)),
                          Text(Formatters.currency(cart.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Delivery Fee (Est. $_estimatedDurationMins mins)', style: const TextStyle(color: AppColors.textSecondary)),
                          Text(Formatters.currency(_deliveryFee), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          Text(Formatters.currency(totalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Place Cash on Delivery Order • ${Formatters.currency(totalAmount)}',
                isLoading: _isSubmitting,
                onPressed: _placeOrder,
              ),
              const SizedBox(height: 32),
            ],
          ),
          if (_isSubmitting) const LoadingOverlay(message: 'Placing your order...'),
        ],
      ),
    );
  }
}
