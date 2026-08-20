import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:auth_session/auth_session.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final auth = context.read<AuthSessionManager>();
      if (auth.accessToken != null) {
        api.setAuthToken(auth.accessToken);
      }
      final orders = await api.getOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        if (errStr.contains('401') || errStr.contains('User not found')) {
          context.read<AuthSessionManager>().logout();
        } else {
          setState(() {
            _error = errStr.replaceAll('ApiException: ', '');
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary)));
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
        description: 'Your past and current orders will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (ctx, idx) {
          final order = _orders[idx];
          return Card(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => OrderTrackingScreen(orderId: order.id),
                ));
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.brandPrimary)),
                        StatusBadge(status: order.status, isSmall: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(order.storeName ?? 'Restaurant', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(order.deliveryAddress, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cash on Delivery', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            Text(Formatters.currency(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.brandPrimary)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.brandPrimary),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
