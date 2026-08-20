import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../state/location_engine.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final OrderDetail orderDetail;

  const ActiveDeliveryScreen({super.key, required this.orderDetail});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  static const String _defaultToken = 'pk.eyJ1IjoiamVhcmFyZCIsImEiOiJjbWE2ZjNlM2YwM2wyMmlvYW9mdDQ5OHJ5In0.57WdNE6fCl-qVJAoMZe40Q';
  final String _mapboxToken = const String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: _defaultToken);

  final MapController _mapController = MapController();

  late OrderDetail _currentDetail;
  bool _isProcessing = false;
  String? _error;

  // Directions & Map
  List<LatLng> _routePoints = [];
  double _routeDistanceKm = 0.85;
  int _routeEtaMins = 5;
  LatLng _riderLocation = const LatLng(7.1265, 124.8295);

  @override
  void initState() {
    super.initState();
    _currentDetail = widget.orderDetail;
    _riderLocation = LatLng(
      _currentDetail.order.deliveryLatitude - 0.004,
      _currentDetail.order.deliveryLongitude - 0.004,
    );
    _fetchDirections();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchDirections() async {
    final token = _mapboxToken.isNotEmpty ? _mapboxToken : _defaultToken;
    final order = _currentDetail.order;
    final customerPos = LatLng(order.deliveryLatitude, order.deliveryLongitude);
    final url = 'https://api.mapbox.com/directions/v5/mapbox/driving/${_riderLocation.longitude},${_riderLocation.latitude};${customerPos.longitude},${customerPos.latitude}?geometries=geojson&overview=full&access_token=$token';

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
            _centerRoute();
          }
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _routePoints = [_riderLocation, customerPos];
        _routeDistanceKm = 0.85;
        _routeEtaMins = 5;
      });
      _centerRoute();
    }
  }

  void _centerRoute() {
    final order = _currentDetail.order;
    final midLat = (_riderLocation.latitude + order.deliveryLatitude) / 2;
    final midLng = (_riderLocation.longitude + order.deliveryLongitude) / 2;
    _mapController.move(LatLng(midLat, midLng), 15.2);
  }

  String _getTileUrl() {
    final token = _mapboxToken.isNotEmpty ? _mapboxToken : _defaultToken;
    return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$token';
  }

  Future<void> _updateStatus(OrderStatus newStatus, {bool codCollected = false}) async {
    final delivery = _currentDetail.delivery;
    if (delivery == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final locationEngine = context.read<LocationEngine>();

      await api.updateDeliveryStatus(
        delivery.id,
        newStatus,
        codCollected: codCollected,
      );

      if (newStatus == OrderStatus.onTheWay || newStatus == OrderStatus.pickedUp) {
        locationEngine.startTracking(delivery.id);
      } else if (newStatus == OrderStatus.delivered || newStatus == OrderStatus.cancelled) {
        locationEngine.stopTracking();
      }

      final updated = await api.getOrderDetail(_currentDetail.order.id);
      if (mounted) {
        setState(() => _currentDetail = updated);
        if (newStatus == OrderStatus.delivered) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Delivery completed! Cash collected.')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _currentDetail.order;
    final delivery = _currentDetail.delivery;
    final status = delivery?.status ?? order.status;
    final customerPos = LatLng(order.deliveryLatitude, order.deliveryLongitude);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order: ${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: AppColors.brandPrimary),
            tooltip: 'Center Map',
            onPressed: _centerRoute,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == OrderStatus.assigned)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.storefront_rounded),
                    label: const Text('Confirm Pickup (At Store)'),
                    onPressed: _isProcessing ? null : () => _updateStatus(OrderStatus.pickedUp),
                  ),
                )
              else if (status == OrderStatus.pickedUp)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary),
                    icon: const Icon(Icons.two_wheeler_rounded),
                    label: const Text('Start Delivery (On the Way)'),
                    onPressed: _isProcessing ? null : () => _updateStatus(OrderStatus.onTheWay),
                  ),
                )
              else if (status == OrderStatus.onTheWay)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandAccent),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text('Mark as Delivered (Collect ${Formatters.currency(order.totalAmount)})'),
                    onPressed: _isProcessing
                        ? null
                        : () => _updateStatus(OrderStatus.delivered, codCollected: true),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.brandAccentLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Delivery Completed',
                      style: TextStyle(color: AppColors.brandAccent, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
            const SizedBox(height: 16),
          ],

          // 1. Mission Stage Hero Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withOpacity(0.3),
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.label.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Cash to Collect: ${Formatters.currency(order.totalAmount)}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Interactive Live Mapbox Navigation Canvas
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: SizedBox(
              height: 240,
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
                        userAgentPackageName: 'com.mns.delivery.rider',
                        retinaMode: true,
                      ),

                      // Road routing polyline
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 5.5,
                              color: AppColors.brandPrimary,
                            ),
                          ],
                        ),

                      // Pins
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: customerPos,
                            width: 140,
                            height: 70,
                            child: _buildPin(
                              icon: Icons.home_rounded,
                              color: AppColors.error,
                              label: 'Customer Address',
                            ),
                          ),
                          Marker(
                            point: _riderLocation,
                            width: 140,
                            height: 70,
                            child: _buildPin(
                              icon: Icons.two_wheeler_rounded,
                              color: AppColors.brandPrimary,
                              label: 'My Location',
                              isPulsing: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Floating ETA & Distance HUD
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.brandPrimaryLight, width: 1.5),
                        boxShadow: AppColors.premiumShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_bike_rounded, size: 16, color: AppColors.brandPrimary),
                          const SizedBox(width: 8),
                          Text('ETA ~$_routeEtaMins mins', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.textPrimary)),
                          const SizedBox(width: 6),
                          Text('(${_routeDistanceKm.toStringAsFixed(2)} km)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Customer Contact & Location Action Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CUSTOMER DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.6)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.customerName ?? 'Customer', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(order.customerPhone ?? '+63 917 123 4567', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: AppColors.brandPrimaryLight),
                            icon: const Icon(Icons.phone_rounded, color: AppColors.brandPrimary, size: 20),
                            tooltip: 'Call Customer',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Calling ${order.customerName ?? "customer"} (+63 917 123 4567)...')),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: AppColors.brandPrimaryLight),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.brandPrimary, size: 20),
                            tooltip: 'Message Customer',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Opening chat...')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 18, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Order Item Checklist
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      Text('${_currentDetail.items.length} Items', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.brandPrimary)),
                    ],
                  ),
                  const Divider(height: 20),
                  ..._currentDetail.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_box_outlined, size: 18, color: AppColors.brandPrimary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.itemName}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            Formatters.currency(item.unitPrice * item.quantity),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total to Collect (COD)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                      Text(
                        Formatters.currency(order.totalAmount),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.brandPrimary),
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
            border: Border.all(color: AppColors.border),
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
}
