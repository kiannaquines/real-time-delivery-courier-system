import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';
import 'package:auth_session/auth_session.dart';
import '../delivery/active_delivery_screen.dart';
import '../history/rider_history_screen.dart';
import '../profile/rider_profile_screen.dart';
import '../../state/location_engine.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  int _currentTab = 0;
  RiderStatus _status = RiderStatus.available;
  OrderDetail? _activeDelivery;
  List<Order> _pastDeliveries = [];
  bool _isLoading = true;
  String? _error;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    _refreshData(isInitial: true);
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshData(isInitial: false));
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshData({bool isInitial = false}) async {
    if (isInitial) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

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
          } else if (_status == RiderStatus.busy) {
            _status = RiderStatus.available;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && isInitial) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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
    final screens = [
      _buildShiftView(),
      const RiderHistoryScreen(),
      const RiderProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: screens[_currentTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (idx) => setState(() => _currentTab = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.two_wheeler_outlined),
            selectedIcon: Icon(Icons.two_wheeler_rounded, color: AppColors.brandPrimary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded, color: AppColors.brandPrimary),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.brandPrimary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildShiftView() {
    final locationEngine = context.watch<LocationEngine>();
    final auth = context.watch<AuthSessionManager>();
    final rider = auth.currentUser;

    final totalEarned = _pastDeliveries.fold(0.0, (sum, o) => sum + o.deliveryFee);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandPrimaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.two_wheeler_rounded, size: 20, color: AppColors.brandPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rider?.fullName ?? 'Carlos Swift', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Text('M&S Express Rider', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => _refreshData(isInitial: false),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary)))
          : RefreshIndicator(
              onRefresh: () => _refreshData(isInitial: false),
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // 1. Shift Duty Status & Metrics Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.premiumShadow,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _status == RiderStatus.available
                                        ? AppColors.brandAccentLight
                                        : (_status == RiderStatus.busy ? AppColors.brandPrimaryLight : const Color(0xFFF1F5F9)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _status == RiderStatus.available ? Icons.check_circle_rounded : (_status == RiderStatus.busy ? Icons.two_wheeler_rounded : Icons.pause_circle_rounded),
                                    color: _status == RiderStatus.available ? AppColors.brandAccent : (_status == RiderStatus.busy ? AppColors.brandPrimary : AppColors.textSecondary),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'DUTY STATUS',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 0.8),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _status.label.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: _status == RiderStatus.available ? AppColors.brandAccent : (_status == RiderStatus.busy ? AppColors.brandPrimary : AppColors.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (_status != RiderStatus.busy)
                              Switch(
                                value: _status == RiderStatus.available,
                                activeColor: AppColors.brandAccent,
                                onChanged: _toggleAvailability,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildShiftStat('Completed', '${_pastDeliveries.length}', AppColors.brandPrimary),
                              Container(height: 28, width: 1, color: AppColors.border),
                              _buildShiftStat('Earnings', Formatters.currency(totalEarned), AppColors.brandAccent),
                              Container(height: 28, width: 1, color: AppColors.border),
                              _buildShiftStat('Location Status', locationEngine.isSharingLocation ? 'LIVE' : 'STANDBY', AppColors.info),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. Active GPS HUD
                  if (locationEngine.isSharingLocation) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.premiumShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.brandAccentLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.gps_fixed_rounded, color: AppColors.brandAccent, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Live Location Sharing Active', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
                                SizedBox(height: 2),
                                Text('Sharing live location with customer and admin', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brandAccentLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.brandAccent)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 3. Current Delivery Card
                  const Text('Current Delivery', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  if (_activeDelivery == null)
                    const EmptyStateView(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'No Active Delivery',
                      description: 'Set your duty status to "Available" to receive new delivery orders.',
                    )
                  else
                    Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide.none,
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
                            const Divider(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: AppColors.brandPrimaryLight, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.storefront_rounded, size: 18, color: AppColors.brandPrimary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('PICKUP STORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                                      Text(_activeDelivery!.order.storeName ?? 'Store Pickup', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: AppColors.statusCancelledBg, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.pin_drop_rounded, size: 18, color: AppColors.error),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('DELIVERY ADDRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                                      Text(_activeDelivery!.order.deliveryAddress, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Collect (COD)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                                      Text(
                                        Formatters.currency(_activeDelivery!.order.totalAmount),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.brandPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.navigation_rounded, size: 16),
                                  label: const Text('View →'),
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
                ],
              ),
            ),
    );
  }

  Widget _buildShiftStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
