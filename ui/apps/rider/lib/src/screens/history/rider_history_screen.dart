import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';

class RiderHistoryScreen extends StatefulWidget {
  const RiderHistoryScreen({super.key});

  @override
  State<RiderHistoryScreen> createState() => _RiderHistoryScreenState();
}

class _RiderHistoryScreenState extends State<RiderHistoryScreen> {
  List<Order> _completedOrders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final all = await api.getOrders();
      final delivered = all.where((o) => o.status == OrderStatus.delivered).toList();
      if (mounted) {
        setState(() {
          _completedOrders = delivered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalFees = _completedOrders.fold(0.0, (sum, o) => sum + o.deliveryFee);
    final totalCashCollected = _completedOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Delivery History', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary)))
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Earnings Banner
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroLightGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.premiumShadow,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TOTAL EARNINGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.8)),
                                const SizedBox(height: 4),
                                Text(Formatters.currency(totalFees), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.brandPrimary)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.brandPrimaryLight, shape: BoxShape.circle),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.brandPrimary, size: 28),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniStat('Completed Deliveries', '${_completedOrders.length}', AppColors.textPrimary),
                            Container(height: 24, width: 1, color: AppColors.border),
                            _buildMiniStat('Cash Collected (COD)', Formatters.currency(totalCashCollected), AppColors.brandAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Past Orders', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),

                  if (_completedOrders.isEmpty)
                    const EmptyStateView(
                      icon: Icons.history_rounded,
                      title: 'No Completed Orders Yet',
                      description: 'Your completed deliveries and earnings will appear here.',
                    )
                  else
                    ..._completedOrders.map((o) => OrderCard(order: o)),
                ],
              ),
            ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: valueColor)),
      ],
    );
  }
}
