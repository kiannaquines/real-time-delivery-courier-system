import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  static const String _defaultToken = 'pk.eyJ1IjoiamVhcmFyZCIsImEiOiJjbWE2ZjNlM2YwM2wyMmlvYW9mdDQ5OHJ5In0.57WdNE6fCl-qVJAoMZe40Q';
  final String _mapboxToken = const String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: _defaultToken);

  final MapController _mapController = MapController();

  OrderDetail? _orderDetail;
  bool _isLoading = true;
  String? _error;

  // Directions & Map State
  List<LatLng> _routePoints = [];
  double _routeDistanceKm = 0.85;
  int _routeEtaMins = 5;
  LatLng _courierPos = const LatLng(7.1265, 124.8295);

  Timer? _refreshTimer;
  Timer? _courierMovementTimer;

  @override
  void initState() {
    super.initState();
    _loadOrder(isInitial: true);
    _startLiveHeartbeat();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _courierMovementTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _startLiveHeartbeat() {
    // Poll order status every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadOrder(isInitial: false));

    // Smoothly interpolate courier location towards dropoff
    _courierMovementTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && _orderDetail != null) {
        final order = _orderDetail!.order;
        if (order.status == OrderStatus.onTheWay || order.status == OrderStatus.pickedUp || order.status == OrderStatus.assigned) {
          setState(() {
            _courierPos = LatLng(
              _courierPos.latitude + (_courierPos.latitude < order.deliveryLatitude ? 0.00012 : -0.00012),
              _courierPos.longitude + (_courierPos.longitude < order.deliveryLongitude ? 0.00012 : -0.00012),
            );
          });
        }
      }
    });
  }

  Future<void> _loadOrder({bool isInitial = false}) async {
    if (isInitial) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final api = context.read<ApiClient>();
      final detail = await api.getOrderDetail(widget.orderId);
      if (mounted) {
        final isFirstLoad = _orderDetail == null;
        setState(() {
          _orderDetail = detail;
          _isLoading = false;
        });

        if (isFirstLoad) {
          _courierPos = LatLng(
            detail.order.deliveryLatitude - 0.005,
            detail.order.deliveryLongitude - 0.005,
          );
          _fetchDirections(detail.order);
        }
      }
    } catch (e) {
      if (mounted && isInitial) {
        setState(() {
          _error = e.toString().replaceAll('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchDirections(Order order) async {
    final token = _mapboxToken.isNotEmpty ? _mapboxToken : _defaultToken;
    final customerPos = LatLng(order.deliveryLatitude, order.deliveryLongitude);
    final url = 'https://api.mapbox.com/directions/v5/mapbox/driving/${_courierPos.longitude},${_courierPos.latitude};${customerPos.longitude},${customerPos.latitude}?geometries=geojson&overview=full&access_token=$token';

    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0] as Map<String, dynamic>;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List<dynamic>?;

          final points = <LatLng>[];
          if (coords != null) {
            for (final c in coords) {
              final pair = c as List<dynamic>;
              points.add(LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble()));
            }
          }

          final distanceMeters = (firstRoute['distance'] as num?)?.toDouble() ?? 850.0;
          final durationSecs = (firstRoute['duration'] as num?)?.toDouble() ?? 300.0;

          if (mounted) {
            setState(() {
              _routePoints = points;
              _routeDistanceKm = distanceMeters / 1000.0;
              _routeEtaMins = (durationSecs / 60.0).ceil();
            });
            _centerMapOnRoute();
          }
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _routePoints = [_courierPos, customerPos];
        _routeDistanceKm = 0.85;
        _routeEtaMins = 5;
      });
      _centerMapOnRoute();
    }
  }

  void _centerMapOnRoute() {
    if (_orderDetail == null) return;
    final order = _orderDetail!.order;
    final midLat = (_courierPos.latitude + order.deliveryLatitude) / 2;
    final midLng = (_courierPos.longitude + order.deliveryLongitude) / 2;
    _mapController.move(LatLng(midLat, midLng), 15.2);
  }

  String _getTileUrl() {
    final token = _mapboxToken.isNotEmpty ? _mapboxToken : _defaultToken;
    return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$token';
  }

  int _getStatusStepIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return 2;
      case OrderStatus.delivered:
        return 3;
      case OrderStatus.cancelled:
        return -1;
    }
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
        appBar: AppBar(title: const Text('Order Tracking')),
        body: EmptyStateView(
          icon: Icons.error_outline,
          title: 'Order Not Found',
          description: _error ?? 'Unable to retrieve tracking details.',
          actionText: 'Retry',
          onAction: () => _loadOrder(isInitial: true),
        ),
      );
    }

    final order = _orderDetail!.order;
    final delivery = _orderDetail!.delivery;
    final customerPos = LatLng(order.deliveryLatitude, order.deliveryLongitude);
    final stepIndex = _getStatusStepIndex(order.status);
    final isDelivered = order.status == OrderStatus.delivered;
    final isCancelled = order.status == OrderStatus.cancelled;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Status',
            onPressed: () => _loadOrder(isInitial: false),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // 1. Premium Live Status Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: (isCancelled ? AppColors.error : AppColors.brandPrimary).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                const BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Live Telemetry Beacon Pill & ETA Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? const Color(0xFFFEE2E2)
                            : (isDelivered ? const Color(0xFFD1FAE5) : AppColors.brandPrimaryLight),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: isCancelled
                                ? AppColors.error
                                : (isDelivered ? AppColors.brandAccent : AppColors.brandPrimary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isDelivered
                                ? 'Completed'
                                : (isCancelled ? 'Cancelled' : (stepIndex == 2 ? 'On the Way' : 'Preparing')),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isCancelled
                                  ? AppColors.error
                                  : (isDelivered ? AppColors.brandAccent : AppColors.brandPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isDelivered && !isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandPrimary.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              'ETA ~$_routeEtaMins mins',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Status Icon & Headline
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: isCancelled
                            ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                            : (isDelivered
                                ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                                : AppColors.primaryGradient),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isCancelled ? Colors.red : AppColors.brandPrimary).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isDelivered
                            ? Icons.check_circle_rounded
                            : (isCancelled
                                ? Icons.cancel_rounded
                                : (stepIndex == 2 ? Icons.two_wheeler_rounded : Icons.restaurant_rounded)),
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDelivered
                                ? 'Delivered!'
                                : (isCancelled
                                    ? 'Order Cancelled'
                                    : (order.status == OrderStatus.pending
                                        ? 'Order Placed'
                                        : (order.status == OrderStatus.confirmed
                                            ? 'Preparing Your Order'
                                            : 'Rider is on the way!'))),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isDelivered
                                ? 'Delivered to ${order.deliveryAddress}. Enjoy your meal!'
                                : (isCancelled
                                    ? 'This order was cancelled.'
                                    : (stepIndex == 2
                                        ? 'Rider is heading to ${order.deliveryAddress}.'
                                        : 'Preparing order from ${order.storeName ?? "Store"}.')),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Micro Progress Timeline Bar
                if (!isCancelled) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: isDelivered ? 1.0 : (stepIndex == 2 ? 0.75 : (stepIndex == 1 ? 0.45 : 0.2)),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation(
                        isDelivered ? AppColors.brandAccent : AppColors.brandPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Footer Metadata Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 5),
                        Text(
                          order.orderNumber,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    Text(
                      'COD: ${Formatters.currency(order.totalAmount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Interactive Slippy Map View
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: SizedBox(
              height: 260,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: customerPos,
                      initialZoom: 15.2,
                      minZoom: 4.0,
                      maxZoom: 19.0,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _getTileUrl(),
                        userAgentPackageName: 'com.mns.delivery.kabacan',
                        retinaMode: true,
                      ),

                      // Road routing polyline
                      if (_routePoints.isNotEmpty && !isDelivered && !isCancelled)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 5.5,
                              color: AppColors.brandPrimary,
                            ),
                          ],
                        ),

                      // Markers
                      MarkerLayer(
                        markers: [
                          // Dropoff Location
                          Marker(
                            point: customerPos,
                            width: 140,
                            height: 70,
                            child: _buildPin(
                              icon: Icons.home_rounded,
                              color: AppColors.error,
                              label: 'Delivery Address',
                            ),
                          ),

                          // Moving Courier Marker
                          if (!isDelivered && !isCancelled)
                            Marker(
                              point: _courierPos,
                              width: 140,
                              height: 70,
                              child: _buildPin(
                                icon: Icons.two_wheeler_rounded,
                                color: AppColors.brandPrimary,
                                label: 'Rider (Live)',
                                isPulsing: true,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Floating Live ETA Badge
                  if (!isDelivered && !isCancelled)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.premiumShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_rounded, size: 16, color: AppColors.brandPrimary),
                            const SizedBox(width: 8),
                            Text('ETA ~$_routeEtaMins mins', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.textPrimary)),
                            const SizedBox(width: 6),
                            Text('(${_routeDistanceKm.toStringAsFixed(2)} km)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),

                  // Center Route Button
                  Positioned(
                    bottom: 14,
                    right: 14,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.premiumShadow,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.my_location_rounded, color: AppColors.brandPrimary, size: 20),
                        tooltip: 'Center Map',
                        onPressed: _centerMapOnRoute,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 3. Step-by-Step Delivery Progress Stepper
          if (!isCancelled) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStepItem('Placed', 0, stepIndex, Icons.receipt_long_rounded),
                        _buildStepDivider(0, stepIndex),
                        _buildStepItem('Preparing', 1, stepIndex, Icons.storefront_rounded),
                        _buildStepDivider(1, stepIndex),
                        _buildStepItem('On the Way', 2, stepIndex, Icons.two_wheeler_rounded),
                        _buildStepDivider(2, stepIndex),
                        _buildStepItem('Delivered', 3, stepIndex, Icons.check_circle_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // 4. Assigned Rider Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.brandPrimaryLight,
                    child: const Icon(Icons.two_wheeler_rounded, color: AppColors.brandPrimary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('YOUR RIDER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.6)),
                        const SizedBox(height: 2),
                        Text(
                          delivery?.riderName ?? 'Carlos Swift',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        const Text('Yamaha NMAX 155 • Plate MNS-7788', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.brandPrimaryLight),
                    icon: const Icon(Icons.phone_rounded, color: AppColors.brandPrimary, size: 20),
                    tooltip: 'Call Rider',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling rider (+63 917 123 4567)...')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 5. Order Details Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      Text(Formatters.dateTime(order.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  const Divider(height: 24),

                  // Store & Delivery details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.storefront_rounded, size: 18, color: AppColors.brandPrimary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.storeName ?? 'Store', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            const Text('Poblacion, Kabacan, Cotabato', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 18, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.deliveryAddress, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            const Text('Delivery Address', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Itemized dishes
                  ..._orderDetail!.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.itemName}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            Formatters.currency(item.unitPrice * item.quantity),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 24),

                  // Fee Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Fee', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text(Formatters.currency(order.deliveryFee), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total (COD)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      Text(
                        Formatters.currency(order.totalAmount),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.brandPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPin({
    required IconData icon,
    required Color color,
    required String label,
    bool isPulsing = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isPulsing ? 0.6 : 0.4),
                blurRadius: isPulsing ? 12 : 6,
                spreadRadius: isPulsing ? 2 : 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(6),
            boxShadow: AppColors.premiumShadow,
          ),
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 9, fontWeight: FontWeight.w900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(String title, int step, int currentStep, IconData icon) {
    final isPassed = step <= currentStep;
    final isCurrent = step == currentStep;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPassed ? AppColors.brandPrimary : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.brandPrimary.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, size: 16, color: isPassed ? Colors.white : AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
            color: isPassed ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int step, int currentStep) {
    final isPassed = step < currentStep;
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 20),
        color: isPassed ? AppColors.brandPrimary : const Color(0xFFE2E8F0),
      ),
    );
  }
}
