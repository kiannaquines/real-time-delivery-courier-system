import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:auth_session/auth_session.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOverview();
    });
  }

  Future<void> _loadOverview() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiClient>();
      final auth = context.read<AuthSessionManager>();
      
      if (auth.accessToken != null) {
        api.setAuthToken(auth.accessToken);
      }

      final ordersFuture = api.getOrders();
      final ridersFuture = api.getRiders();
      final storesFuture = api.getStores();

      final results = await Future.wait([ordersFuture, ridersFuture, storesFuture]);

      if (mounted) {
        setState(() {
          _orders = results[0] as List<Order>;
          _riders = results[1] as List<RiderProfile>;
          _stores = results[2] as List<Store>;
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
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary)),
      );
    }

    final pendingOrders = _orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.confirmed).toList();
    final inTransitOrders = _orders.where((o) => o.status == OrderStatus.onTheWay || o.status == OrderStatus.pickedUp || o.status == OrderStatus.assigned).toList();
    final deliveredOrders = _orders.where((o) => o.status == OrderStatus.delivered).toList();
    final totalRevenue = deliveredOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final activeRiders = _riders.where((r) => r.status != RiderStatus.offline).toList();

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isNarrow = constraints.maxWidth < 950;
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : (isNarrow ? 20.0 : 32.0);

        final metricCard1 = _buildMetricCard(
          title: "Today's Revenue",
          value: Formatters.currency(totalRevenue),
          subtitle: '${deliveredOrders.length} orders delivered',
          trend: '+14.2% vs yesterday',
          icon: Icons.payments_rounded,
          color: AppColors.brandPrimary,
        );

        final metricCard2 = _buildMetricCard(
          title: 'Pending Orders',
          value: '${pendingOrders.length}',
          subtitle: 'Waiting for rider',
          trend: 'Action required',
          icon: Icons.pending_actions_rounded,
          color: AppColors.warning,
          onTap: () => widget.onNavigateTab?.call(1),
        );

        final metricCard3 = _buildMetricCard(
          title: 'On the Way',
          value: '${inTransitOrders.length}',
          subtitle: 'Deliveries in progress',
          trend: 'Active tracking',
          icon: Icons.two_wheeler_rounded,
          color: const Color(0xFF6366F1),
          onTap: () => widget.onNavigateTab?.call(4),
        );

        final metricCard4 = _buildMetricCard(
          title: 'Active Riders',
          value: '${activeRiders.length} / ${_riders.length}',
          subtitle: 'Available for delivery',
          trend: 'Online',
          icon: Icons.person_pin_circle_rounded,
          color: AppColors.brandAccent,
          onTap: () => widget.onNavigateTab?.call(3),
        );

        final leftColumnContent = _buildLiveDispatchCard(inTransitOrders, pendingOrders);
        final rightColumnContent = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCourierFleetCard(activeRiders),
            const SizedBox(height: 24),
            _buildPartnerStoresCard(),
          ],
        );

        return RefreshIndicator(
          onRefresh: _loadOverview,
          child: ListView(
            padding: EdgeInsets.all(padding),
            children: [
              // 1. Responsive Hero Overview Card
              Container(
                padding: EdgeInsets.all(isMobile ? 18 : 26),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF1F2), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFFE4E6), width: 1.5),
                  boxShadow: AppColors.premiumShadow,
                ),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPoblacionPill(),
                          const SizedBox(height: 12),
                          const Text(
                            'Overview & Operations',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Manage orders, riders, stores, and deliveries in Kabacan.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.sync_rounded, size: 16),
                            label: const Text('Refresh'),
                            onPressed: _loadOverview,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPoblacionPill(),
                                const SizedBox(height: 14),
                                const Text(
                                  'Overview & Operations',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.6),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Manage orders, riders, stores, and deliveries in Kabacan.',
                                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.sync_rounded, size: 17),
                            label: const Text('Refresh'),
                            onPressed: _loadOverview,
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // 2. Responsive KPI Metrics Grid
              if (isMobile) ...[
                // 1 per row or 2 per row on small phones
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(width: (constraints.maxWidth - (padding * 2) - 12) / 2, child: metricCard1),
                    SizedBox(width: (constraints.maxWidth - (padding * 2) - 12) / 2, child: metricCard2),
                    SizedBox(width: (constraints.maxWidth - (padding * 2) - 12) / 2, child: metricCard3),
                    SizedBox(width: (constraints.maxWidth - (padding * 2) - 12) / 2, child: metricCard4),
                  ],
                ),
              ] else if (isNarrow) ...[
                // 2 per row on tablets
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(width: (constraints.maxWidth - (padding * 2) - 16) / 2, child: metricCard1),
                    SizedBox(width: (constraints.maxWidth - (padding * 2) - 16) / 2, child: metricCard2),
                    SizedBox(width: (constraints.maxWidth - (padding * 2) - 16) / 2, child: metricCard3),
                    SizedBox(width: (constraints.maxWidth - (padding * 2) - 16) / 2, child: metricCard4),
                  ],
                ),
              ] else ...[
                // 4 in a single row on desktop
                Row(
                  children: [
                    Expanded(child: metricCard1),
                    const SizedBox(width: 18),
                    Expanded(child: metricCard2),
                    const SizedBox(width: 18),
                    Expanded(child: metricCard3),
                    const SizedBox(width: 18),
                    Expanded(child: metricCard4),
                  ],
                ),
              ],
              const SizedBox(height: 28),

              // 3. Responsive Main Content Area (Stacked on Mobile/Tablet, 2-Column on Desktop)
              if (isNarrow) ...[
                leftColumnContent,
                const SizedBox(height: 24),
                rightColumnContent,
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: leftColumnContent),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: rightColumnContent),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPoblacionPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.brandPrimaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 13, color: AppColors.brandPrimary),
          SizedBox(width: 6),
          Text(
            'POBLACION, KABACAN, COTABATO',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.brandPrimary, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required String trend,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveDispatchCard(List<Order> inTransit, List<Order> pending) {
    final recent = [...inTransit, ...pending].take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flash_on_rounded, color: AppColors.brandPrimary, size: 20),
                    SizedBox(width: 8),
                    Text('Recent Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  ],
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab?.call(1),
                  child: const Text('View All Orders →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Latest orders and deliveries in Kabacan.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const Divider(height: 24),
            if (recent.isEmpty)
              const EmptyStateView(
                icon: Icons.check_circle_outline_rounded,
                title: 'All Caught Up!',
                description: 'No pending orders or active deliveries in the queue right now.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) {
                  final order = recent[idx];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary)),
                            StatusBadge(status: order.status, isSmall: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.storefront_rounded, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${order.storeName ?? "Store"} → ${order.deliveryAddress}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total: ${Formatters.currency(order.totalAmount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.brandPrimary)),
                            Text(Formatters.date(order.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourierFleetCard(List<RiderProfile> activeRiders) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.two_wheeler_rounded, color: AppColors.brandPrimary, size: 20),
                    SizedBox(width: 8),
                    Text('Riders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  ],
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab?.call(3),
                  child: const Text('Manage Riders →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 20),
            if (_riders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Icon(Icons.two_wheeler_outlined, size: 36, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    const Text('No riders registered yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => widget.onNavigateTab?.call(3),
                      child: const Text('Add Rider'),
                    ),
                  ],
                ),
              )
            else
              ..._riders.take(3).map((r) {
                final isAvailable = r.status == RiderStatus.available;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.brandPrimaryLight,
                        child: Text(
                          r.fullName.isNotEmpty ? r.fullName[0].toUpperCase() : 'R',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brandPrimary, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${r.vehicleType} • ${r.plateNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAvailable ? AppColors.brandAccentLight : AppColors.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          r.status.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isAvailable ? AppColors.brandAccent : AppColors.brandPrimary,
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
    );
  }

  Widget _buildPartnerStoresCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.storefront_rounded, color: AppColors.brandPrimary, size: 20),
                    SizedBox(width: 8),
                    Text('Stores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  ],
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab?.call(2),
                  child: const Text('Manage Stores →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 20),
            if (_stores.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Icon(Icons.storefront_outlined, size: 36, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    const Text('No stores registered yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => widget.onNavigateTab?.call(2),
                      child: const Text('Add Store'),
                    ),
                  ],
                ),
              )
            else
              ..._stores.take(3).map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.restaurant_rounded, size: 18, color: AppColors.brandPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(s.address, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brandAccentLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Open', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brandAccent)),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
