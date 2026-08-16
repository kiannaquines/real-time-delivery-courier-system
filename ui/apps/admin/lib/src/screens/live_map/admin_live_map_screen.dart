import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';

class AdminLiveMapScreen extends StatefulWidget {
  const AdminLiveMapScreen({super.key});

  @override
  State<AdminLiveMapScreen> createState() => _AdminLiveMapScreenState();
}

class _AdminLiveMapScreenState extends State<AdminLiveMapScreen> {
  List<Order> _activeOrders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
  }

  Future<void> _loadActiveOrders() async {
    try {
      final api = context.read<ApiClient>();
      final orders = await api.getOrders();
      final inTransit = orders.where((o) => o.status == OrderStatus.onTheWay || o.status == OrderStatus.pickedUp || o.status == OrderStatus.assigned).toList();
      if (mounted) {
        setState(() {
          _activeOrders = inTransit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Active Deliveries (${_activeOrders.length} in transit)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Poll Realtime Snapshot'),
                onPressed: _loadActiveOrders,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Map Canvas Container
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.map, size: 64, color: Colors.white24),
                                const SizedBox(height: 12),
                                const Text('Mapbox Live Dispatch Overlay', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text('${_activeOrders.length} active couriers streaming telemetry', style: const TextStyle(color: Colors.white38, fontSize: 13)),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.radio_button_checked, size: 14, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Realtime Ingestion Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // In-Transit Deliveries List
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fleet Telemetry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _activeOrders.isEmpty
                                ? const Center(child: Text('No active deliveries in transit.', style: TextStyle(color: AppColors.textMuted)))
                                : ListView.separated(
                                    itemCount: _activeOrders.length,
                                    separatorBuilder: (_, __) => const Divider(height: 16, color: AppColors.border),
                                    itemBuilder: (ctx, idx) {
                                      final order = _activeOrders[idx];
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
                                              StatusBadge(status: order.status),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('${order.storeName ?? "Store"} → ${order.deliveryAddress}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.gps_fixed, size: 12, color: AppColors.primary),
                                              const SizedBox(width: 4),
                                              Text('GPS: ${order.deliveryLatitude.toStringAsFixed(4)}, ${order.deliveryLongitude.toStringAsFixed(4)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
