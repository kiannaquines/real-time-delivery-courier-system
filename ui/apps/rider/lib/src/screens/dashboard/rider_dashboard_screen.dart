import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';
import 'package:auth_session/auth_session.dart';
import '../delivery/active_delivery_screen.dart';
import '../../state/location_engine.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  RiderStatus _status = RiderStatus.available;
  OrderDetail? _activeDelivery;
  List<Order> _pastDeliveries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final active = await api.getRiderActiveDelivery();
      final allOrders = await api.getOrders();
      final completed = allOrders.where((o) => o.status == OrderStatus.delivered).toList();

      if (mounted) {
        setState(() {
          _activeDelivery = active;
          _pastDeliveries = completed;
          if (active != null) {
            _status = RiderStatus.busy;
            if (active.delivery != null) {
              context.read<LocationEngine>().startTracking(active.delivery!.id);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAvailability(bool isAvailable) async {
    final target = isAvailable ? RiderStatus.available : RiderStatus.offline;
    try {
      final api = context.read<ApiClient>();
      await api.updateRiderStatus(target);
      setState(() => _status = target);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationEngine = context.watch<LocationEngine>();
    final auth = context.watch<AuthSessionManager>();
    final rider = auth.currentUser;

    final totalEarned = _pastDeliveries.fold(0.0, (sum, o) => sum + o.deliveryFee);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.brandPrimary.withOpacity(0.15),
              child: const Icon(Icons.two_wheeler, size: 18, color: AppColors.brandPrimary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rider?.fullName ?? 'Rider Courier', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const Text('M&S Express Kabacan Fleet', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync Dispatch',
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'End Shift',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => const ConfirmationDialog(
                  title: 'End Shift',
                  content: 'Are you sure you want to go offline and sign out from your rider shift?',
                  confirmText: 'End Shift',
                  isDestructive: true,
                ),
              );
              if (confirmed == true) {
                locationEngine.stopTracking();
                auth.logout();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary)))
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // Shift Status Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: _status == RiderStatus.available
                          ? AppColors.riderStatusGradient
                          : (_status == RiderStatus.busy ? AppColors.primaryGradient : AppColors.darkCardGradient),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: (_status == RiderStatus.available ? AppColors.brandAccent : AppColors.brandPrimary).withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CURRENT DUTY STATUS',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _status.label.toUpperCase(),
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ],
                            ),
                            if (_status != RiderStatus.busy)
                              Switch(
                                value: _status == RiderStatus.available,
                                activeColor: Colors.white,
                                activeTrackColor: Colors.white38,
                                onChanged: _toggleAvailability,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildShiftStat('Deliveries', '${_pastDeliveries.length}'),
                              Container(height: 24, width: 1, color: Colors.white24),
                              _buildShiftStat('Est. Fees', Formatters.currency(totalEarned)),
                              Container(height: 24, width: 1, color: Colors.white24),
                              _buildShiftStat('GPS Engine', locationEngine.isSharingLocation ? 'ACTIVE' : 'STANDBY'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // GPS Telemetry HUD
                  if (locationEngine.isSharingLocation) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.brandSecondary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.gps_fixed, color: AppColors.brandPrimary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Live Location Telemetry Streaming', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                SizedBox(height: 2),
                                Text('10s pulse • Coordinates broadcast to customer & admin', style: TextStyle(color: Colors.white60, fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brandAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('STREAMING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brandAccent)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Active Task Section
                  const Text('Active Dispatch Mission', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  if (_activeDelivery == null)
                    const EmptyStateView(
                      icon: Icons.check_circle_outline,
                      title: 'No Active Orders',
                      description: 'Keep your status set to "Available" to receive new pickup and delivery tasks from dispatch.',
                    )
                  else
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.brandPrimary, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_activeDelivery!.order.orderNumber, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.brandPrimary)),
                                StatusBadge(status: _activeDelivery!.order.status),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.storefront, size: 18, color: AppColors.brandPrimary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('PICKUP RESTAURANT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                                      Text(_activeDelivery!.order.storeName ?? 'Store Pickup', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.pin_drop, size: 18, color: AppColors.error),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('CUSTOMER DESTINATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                                      Text(_activeDelivery!.order.deliveryAddress, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Cash to Collect (COD)', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                    Text(Formatters.currency(_activeDelivery!.order.totalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.brandPrimary)),
                                  ],
                                ),
                                AppButton(
                                  text: 'Open Mission →',
                                  onPressed: () async {
                                    await Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => ActiveDeliveryScreen(orderDetail: _activeDelivery!),
                                    ));
                                    _refreshData();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                  const Text('Completed Shifts Today', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  if (_pastDeliveries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No completed deliveries recorded in this shift yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    )
                  else
                    ..._pastDeliveries.map((o) => OrderCard(order: o)),
                ],
              ),
            ),
    );
  }

  Widget _buildShiftStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
