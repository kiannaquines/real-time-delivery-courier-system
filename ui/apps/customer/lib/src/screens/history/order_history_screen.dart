import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';
import '../tracking/order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final orders = await api.getOrders();
      setState(() => _orders = orders);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)));
    }

    if (_error != null) {
      return EmptyStateView(
        icon: Icons.error_outline,
        title: 'Unable to Load Orders',
        description: _error!,
        actionText: 'Retry',
        onAction: _loadOrders,
      );
    }

    if (_orders.isEmpty) {
      return const EmptyStateView(
        icon: Icons.receipt_long_outlined,
        title: 'No Orders Yet',
        description: 'Your placed orders will show up here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (ctx, idx) {
          final order = _orders[idx];
          return OrderCard(
            order: order,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => OrderTrackingScreen(orderId: order.id),
              ));
            },
          );
        },
      ),
    );
  }
}
