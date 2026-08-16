import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';
import 'package:realtime_client/realtime_client.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  OrderDetail? _orderDetail;
  RealtimeDeliveryClient? _realtimeClient;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialOrder();
  }

  Future<void> _loadInitialOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final detail = await api.getOrderDetail(widget.orderId);
      setState(() => _orderDetail = detail);

      if (detail.delivery != null) {
        _realtimeClient = RealtimeDeliveryClient(
          apiClient: api,
        );
        _realtimeClient!.startTracking(detail.delivery!.id);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _realtimeClient?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Delivery Tracking')),
        body: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary))),
      );
    }

    if (_error != null || _orderDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: EmptyStateView(
          icon: Icons.error_outline,
          title: 'Order Not Found',
          description: _error ?? 'Unable to retrieve tracking details.',
          actionText: 'Retry',
          onAction: _loadInitialOrder,
        ),
      );
    }

    final order = _orderDetail!.order;
    final delivery = _orderDetail!.delivery;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialOrder,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Live Status Banner Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delivery_dining, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.status.label.toUpperCase(),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.status == OrderStatus.onTheWay
                            ? 'Courier is heading to your destination in Kabacan.'
                            : (order.status == OrderStatus.delivered
                                ? 'Order successfully delivered. Enjoy your meal!'
                                : 'Store is preparing your delicious order.'),
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Map Simulation Canvas
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                color: AppColors.brandSecondary,
              ),
              child: Stack(
                children: [
                  // Map Background Graphic
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.map_outlined, size: 54, color: Colors.white24),
                        SizedBox(height: 8),
                        Text(
                          'Mapbox Live Route Overlay • Kabacan Area',
                          style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  // Store Marker
                  Positioned(
                    top: 40,
                    left: 40,
                    child: _buildMapPin(Icons.storefront, AppColors.brandAccent, order.storeName ?? 'Store'),
                  ),
                  // Customer Destination Marker
                  Positioned(
                    bottom: 40,
                    right: 40,
                    child: _buildMapPin(Icons.home, AppColors.error, 'Purok Miracle'),
                  ),
                  // Moving Rider Marker
                  Positioned(
                    top: 100,
                    left: 140,
                    child: _buildMapPin(Icons.two_wheeler, AppColors.brandPrimary, 'Carlos (Courier)'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Courier Contact Card (if assigned)
          if (delivery != null && delivery.riderName != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.brandPrimary.withOpacity(0.15),
                      child: const Icon(Icons.two_wheeler, color: AppColors.brandPrimary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(delivery.riderName!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 2),
                          const Text('Yamaha NMAX 155 • Plate MNS-7788', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone, color: AppColors.brandAccent),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling courier ${delivery.riderName}...')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Order Items Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ..._orderDetail!.items.map((it) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${it.quantity}x ${it.itemName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          Text(Formatters.currency(it.subtotal), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Fee', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(Formatters.currency(order.deliveryFee), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total (Pay with Cash on Delivery)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(Formatters.currency(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.brandPrimary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin(IconData icon, Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
