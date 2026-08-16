import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';
import '../../state/location_engine.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final OrderDetail orderDetail;

  const ActiveDeliveryScreen({super.key, required this.orderDetail});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  late OrderDetail _currentDetail;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentDetail = widget.orderDetail;
  }

  Future<void> _updateStatus(OrderStatus newStatus, {bool codCollected = false}) async {
    final delivery = _currentDetail.delivery;
    if (delivery == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final locationEngine = context.read<LocationEngine>();

      await api.updateDeliveryStatus(
        delivery.id,
        newStatus,
        codCollected: codCollected,
      );

      // Manage location sharing lifecycle
      if (newStatus == OrderStatus.onTheWay || newStatus == OrderStatus.pickedUp) {
        locationEngine.startTracking(delivery.id);
      } else if (newStatus == OrderStatus.delivered || newStatus == OrderStatus.cancelled) {
        locationEngine.stopTracking();
      }

      // Fetch refreshed detail
      final updated = await api.getOrderDetail(_currentDetail.order.id);
      if (mounted) {
        setState(() => _currentDetail = updated);
        if (newStatus == OrderStatus.delivered) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Delivery finalized and Cash on Delivery confirmed!')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _currentDetail.order;
    final delivery = _currentDetail.delivery;
    final status = delivery?.status ?? order.status;

    return Scaffold(
      appBar: AppBar(
        title: Text('Task: ${order.orderNumber}'),
      ),
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

              // Current Stage Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Status', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(status.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ],
                      ),
                      StatusBadge(status: status),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pickup Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.store, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('1. Pickup Store', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(order.storeName ?? 'M&S Store', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const Divider(height: 20, color: AppColors.border),
                      const Text('Items to Collect:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      ..._currentDetail.items.map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('• ${it.quantity}x ${it.itemName}', style: const TextStyle(fontSize: 14)),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Dropoff Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.pin_drop, color: AppColors.error, size: 20),
                          SizedBox(width: 8),
                          Text('2. Dropoff Destination', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(order.deliveryAddress, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      if (order.customerName != null) ...[
                        const SizedBox(height: 4),
                        Text('Customer: ${order.customerName!} (${order.customerPhone ?? ""})', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Collection Notice (COD ONLY)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.payments, color: Color(0xFF856404)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Collect Cash On Delivery', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                            Text(
                              Formatters.currency(order.totalAmount),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Delivery State Transitions
              if (status == OrderStatus.assigned)
                AppButton(
                  text: 'Mark Picked Up from Store',
                  isLoading: _isProcessing,
                  onPressed: () => _updateStatus(OrderStatus.pickedUp),
                )
              else if (status == OrderStatus.pickedUp)
                AppButton(
                  text: 'Start Journey (On the Way)',
                  isLoading: _isProcessing,
                  onPressed: () => _updateStatus(OrderStatus.onTheWay),
                )
              else if (status == OrderStatus.onTheWay)
                AppButton(
                  text: 'Confirm Cash Collected & Completed',
                  isLoading: _isProcessing,
                  variant: ButtonVariant.primary,
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => ConfirmationDialog(
                        title: 'Confirm COD Collection',
                        content: 'Did you collect ${Formatters.currency(order.totalAmount)} in cash from the customer?',
                        confirmText: 'Yes, Collected & Delivered',
                      ),
                    );
                    if (confirmed == true) {
                      _updateStatus(OrderStatus.delivered, codCollected: true);
                    }
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
          if (_isProcessing) const LoadingOverlay(message: 'Updating delivery status...'),
        ],
      ),
    );
  }
}
