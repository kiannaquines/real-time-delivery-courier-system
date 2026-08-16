import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';

class AdminOverviewDashboard extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const AdminOverviewDashboard({super.key, this.onNavigateTab});

  @override
  State<AdminOverviewDashboard> createState() => _AdminOverviewDashboardState();
}

class _AdminOverviewDashboardState extends State<AdminOverviewDashboard> {
  List<Order> _orders = [];
  List<RiderProfile> _riders = [];
  List<Store> _stores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiClient>();
      final orders = await api.getOrders();
      final riders = await api.getRiders();
      final stores = await api.getStores();
      if (mounted) {
        setState(() {
          _orders = orders;
          _riders = riders;
          _stores = stores;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary)));
    }

    final pendingOrders = _orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.confirmed).toList();
    final inTransitOrders = _orders.where((o) => o.status == OrderStatus.onTheWay || o.status == OrderStatus.pickedUp || o.status == OrderStatus.assigned).toList();
    final deliveredOrders = _orders.where((o) => o.status == OrderStatus.delivered).toList();
    final totalRevenue = deliveredOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final activeRiders = _riders.where((r) => r.status != RiderStatus.offline).toList();

    return RefreshIndicator(
      onRefresh: _loadOverview,
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.brandPrimary.withOpacity(0.5)),
                        ),
                        child: const Text(
                          'M&S KABACAN COMMAND CENTER',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Operations & Dispatch Mission Control',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Real-time fleet tracking, instant courier dispatch, and live revenue analytics.',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Live Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onPressed: _loadOverview,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // KPI Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: "Today's Revenue (COD)",
                  value: Formatters.currency(totalRevenue),
                  subtitle: '${deliveredOrders.length} delivered orders',
                  icon: Icons.payments_outlined,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _buildKpiCard(
                  title: 'Pending Dispatch',
                  value: '${pendingOrders.length}',
                  subtitle: 'Awaiting rider assignment',
                  icon: Icons.pending_actions_outlined,
                  color: AppColors.warning,
                  onTap: () => widget.onNavigateTab?.call(1),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _buildKpiCard(
                  title: 'Active In-Transit',
                  value: '${inTransitOrders.length}',
                  subtitle: 'Streaming live GPS telemetry',
                  icon: Icons.two_wheeler_outlined,
                  color: AppColors.info,
                  onTap: () => widget.onNavigateTab?.call(3),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _buildKpiCard(
                  title: 'Couriers on Duty',
                  value: '${activeRiders.length} / ${_riders.length}',
                  subtitle: 'Online fleet availability',
                  icon: Icons.person_pin_circle_outlined,
                  color: AppColors.success,
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Two-column layout: Recent Orders & Quick Dispatch Triage
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Live Orders Feed
              Expanded(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Live Dispatch Feed', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            TextButton(
                              onPressed: () => widget.onNavigateTab?.call(1),
                              child: const Text('View All Orders →'),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (_orders.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No orders placed yet.', style: TextStyle(color: AppColors.textMuted))),
                          )
                        else
                          ..._orders.take(5).map((order) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPrimary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.receipt_long, color: AppColors.brandPrimary, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                        Text('${order.customerName ?? "Customer"} • ${order.storeName ?? "Store"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(status: order.status, isSmall: true),
                                  const SizedBox(width: 16),
                                  Text(
                                    Formatters.currency(order.totalAmount),
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Right Column: Fleet Status Overview & Hub Summary
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fleet Couriers On Duty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 14),
                            if (_riders.isEmpty)
                              const Text('No riders registered yet.', style: TextStyle(color: AppColors.textMuted))
                            else
                              ..._riders.take(4).map((r) {
                                final isAvailable = r.status == RiderStatus.available;
                                final isBusy = r.status == RiderStatus.busy;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.brandPrimary.withOpacity(0.1),
                                        child: const Icon(Icons.two_wheeler, size: 16, color: AppColors.brandPrimary),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(r.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                            Text('${r.vehicleType} • ${r.plateNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isAvailable ? AppColors.statusDeliveredBg : (isBusy ? AppColors.statusPendingBg : Colors.grey.shade200),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          r.status.label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isAvailable ? AppColors.statusDeliveredFg : (isBusy ? AppColors.statusPendingFg : Colors.grey.shade700),
                                          ),
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
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Partner Stores & Kitchens', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            ..._stores.map((s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.storefront, size: 16, color: AppColors.brandPrimary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  ),
                                  const Text('Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
