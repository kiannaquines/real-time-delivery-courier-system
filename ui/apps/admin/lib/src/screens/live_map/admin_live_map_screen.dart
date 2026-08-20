import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum MapStyle {
  streets('Streets', 'mapbox/streets-v12', Icons.map_outlined),
  light('Light', 'mapbox/light-v11', Icons.wb_sunny_outlined),
  satellite('Satellite', 'mapbox/satellite-streets-v12', Icons.satellite_alt_outlined),
  navigation('Navigation', 'mapbox/navigation-day-v1', Icons.navigation_outlined),
  osm('OpenStreetMap', 'osm', Icons.public_rounded);

  final String label;
  final String styleId;
  final IconData icon;
  const MapStyle(this.label, this.styleId, this.icon);
}

class AdminLiveMapScreen extends StatefulWidget {
  const AdminLiveMapScreen({super.key});

  @override
  State<AdminLiveMapScreen> createState() => _AdminLiveMapScreenState();
}

class _AdminLiveMapScreenState extends State<AdminLiveMapScreen> {
  static const String _defaultToken = 'pk.eyJ1IjoiamVhcmFyZCIsImEiOiJjbWE2ZjNlM2YwM2wyMmlvYW9mdDQ5OHJ5In0.57WdNE6fCl-qVJAoMZe40Q';
  final String _mapboxToken = const String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: _defaultToken);

  final MapController _mapController = MapController();

  List<Order> _activeOrders = [];
  List<RiderProfile> _riders = [];
  List<Store> _stores = [];
  bool _isLoading = true;
  String? _error;
  bool _isPanelExpanded = false;

  MapStyle _currentStyle = MapStyle.streets;
  LatLng _currentCenter = const LatLng(7.1280, 124.8310);
  double _currentZoom = 15.0;

  Order? _selectedOrder;
  RiderProfile? _selectedRider;

  // Directions API Route State
  List<LatLng> _routePoints = [];
  double _routeDistanceKm = 0.0;
  int _routeEtaMins = 0;

  // Live courier moving telemetry simulation
  double _courierLat = 7.1265;
  double _courierLng = 124.8295;
  Timer? _telemetryTimer;

  final List<Map<String, dynamic>> _quickLocations = const [
    {'name': 'Kabacan', 'lat': 7.1280, 'lng': 124.8310, 'icon': Icons.location_city_rounded},
    {'name': 'USM Gate', 'lat': 7.1245, 'lng': 124.8350, 'icon': Icons.school_rounded},
    {'name': 'Kidapawan', 'lat': 7.0086, 'lng': 125.0894, 'icon': Icons.apartment_rounded},
    {'name': 'Matalam', 'lat': 7.0701, 'lng': 124.8967, 'icon': Icons.storefront_rounded},
    {'name': 'Davao City', 'lat': 7.0731, 'lng': 125.6128, 'icon': Icons.public_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadLiveFleet();
    _startSimulatedTelemetry();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _startSimulatedTelemetry() {
    _telemetryTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _selectedOrder != null) {
        setState(() {
          _courierLat += (_courierLat < _selectedOrder!.deliveryLatitude) ? 0.00015 : -0.00015;
          _courierLng += (_courierLng < _selectedOrder!.deliveryLongitude) ? 0.00015 : -0.00015;
        });
      }
    });
  }

  Future<void> _loadLiveFleet() async {
    try {
      final api = context.read<ApiClient>();
      final orders = await api.getOrders();
      final riders = await api.getRiders();
      final stores = await api.getStores();
      final inTransit = orders.where((o) => o.status == OrderStatus.onTheWay || o.status == OrderStatus.pickedUp || o.status == OrderStatus.assigned).toList();

      if (mounted) {
        setState(() {
          _activeOrders = inTransit;
          _riders = riders;
          _stores = stores;
          _isLoading = false;
        });

        if (inTransit.isNotEmpty && _selectedOrder == null) {
          _selectOrderAndFetchDirections(inTransit.first);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _selectOrderAndFetchDirections(Order order) async {
    setState(() {
      _selectedOrder = order;
      _selectedRider = _riders.isNotEmpty ? _riders.first : null;
    });

    final riderPos = LatLng(_courierLat, _courierLng);
    final customerPos = LatLng(order.deliveryLatitude, order.deliveryLongitude);

    _flyTo(LatLng((riderPos.latitude + customerPos.latitude) / 2, (riderPos.longitude + customerPos.longitude) / 2), 15.5);
    await _fetchMapboxDirections(riderPos, customerPos);
  }

  Future<void> _fetchMapboxDirections(LatLng riderPos, LatLng customerPos) async {
    final token = _mapboxToken.isNotEmpty ? _mapboxToken : _defaultToken;
    final url = 'https://api.mapbox.com/directions/v5/mapbox/driving/${riderPos.longitude},${riderPos.latitude};${customerPos.longitude},${customerPos.latitude}?geometries=geojson&overview=full&access_token=$token';

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

          final distanceMeters = (firstRoute['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSecs = (firstRoute['duration'] as num?)?.toDouble() ?? 0.0;

          if (mounted) {
            setState(() {
              _routePoints = points;
              _routeDistanceKm = distanceMeters / 1000.0;
              _routeEtaMins = (durationSecs / 60.0).ceil();
            });
          }
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _routePoints = [riderPos, customerPos];
        _routeDistanceKm = 0.45;
        _routeEtaMins = 3;
      });
    }
  }

  String _getTileUrl() {
    if (_currentStyle == MapStyle.osm) {
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
    final token = _mapboxToken.isNotEmpty ? _mapboxToken : _defaultToken;
    return 'https://api.mapbox.com/styles/v1/${_currentStyle.styleId}/tiles/256/{z}/{x}/{y}@2x?access_token=$token';
  }

  void _flyTo(LatLng target, double zoom) {
    _currentCenter = target;
    _currentZoom = zoom;
    _mapController.move(target, zoom);
  }

  void _zoomIn() {
    final newZoom = (_mapController.camera.zoom + 1.0).clamp(3.0, 19.0);
    _mapController.move(_mapController.camera.center, newZoom);
  }

  void _zoomOut() {
    final newZoom = (_mapController.camera.zoom - 1.0).clamp(3.0, 19.0);
    _mapController.move(_mapController.camera.center, newZoom);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary)));
    }

    final riderPosition = LatLng(_courierLat, _courierLng);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isNarrow = constraints.maxWidth < 950;
        final panelWidth = isMobile ? min(340.0, constraints.maxWidth - 32) : 340.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. FlutterMap Slippy Canvas (Full Screen Edge-to-Edge)
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentCenter,
                  initialZoom: _currentZoom,
                  minZoom: 3.0,
                  maxZoom: 19.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _getTileUrl(),
                    userAgentPackageName: 'com.mns.delivery.kabacan',
                    retinaMode: _currentStyle != MapStyle.osm,
                  ),

                  // Mapbox Directions Road Route Polyline
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

                  // Interactive Pins
                  MarkerLayer(
                    markers: [
                      // Partner Stores
                      ..._stores.map((store) {
                        return Marker(
                          point: LatLng(store.latitude, store.longitude),
                          width: 140,
                          height: 75,
                          child: _buildMapPin(
                            icon: Icons.storefront_rounded,
                            color: AppColors.brandAccent,
                            label: store.name,
                            onTap: () => _showDetailsModal(store.name, store.address, 'Store • Open'),
                          ),
                        );
                      }),

                      // Customer Dropoffs
                      ..._activeOrders.map((order) {
                        final isSelected = _selectedOrder?.id == order.id;
                        return Marker(
                          point: LatLng(order.deliveryLatitude, order.deliveryLongitude),
                          width: 150,
                          height: 80,
                          child: _buildMapPin(
                            icon: Icons.home_rounded,
                            color: isSelected ? AppColors.brandPrimary : AppColors.error,
                            label: 'Delivery: ${order.customerName ?? order.orderNumber}',
                            isPulsing: isSelected,
                            onTap: () => _selectOrderAndFetchDirections(order),
                          ),
                        );
                      }),

                      // Live Moving Rider
                      Marker(
                        point: riderPosition,
                        width: 160,
                        height: 85,
                        child: _buildMapPin(
                          icon: Icons.two_wheeler_rounded,
                          color: AppColors.brandPrimary,
                          label: '${_selectedRider != null ? "Carlos Swift" : "Rider"} (Live)',
                          isPulsing: true,
                          onTap: () => _showDetailsModal('Rider: Carlos Swift', 'Yamaha NMAX 155 (Plate MNS-7788)', 'Live Location Active\nSpeed: 28 km/h • Route active'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Responsive Top Controls Bar
            Positioned(
              top: isMobile ? 12 : 18,
              left: isMobile ? 12 : 20,
              right: isMobile ? 12 : 20,
              child: isNarrow
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.96),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppColors.premiumShadow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.circle, size: 8, color: AppColors.brandPrimary),
                              const SizedBox(width: 6),
                              Text('${_activeOrders.length} In Transit', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.brandPrimary)),
                            ],
                          ),
                        ),

                        // Style Selector Menu
                        PopupMenuButton<MapStyle>(
                          initialValue: _currentStyle,
                          onSelected: (style) => setState(() => _currentStyle = style),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.96),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppColors.premiumShadow,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_currentStyle.icon, size: 14, color: AppColors.brandPrimary),
                                const SizedBox(width: 6),
                                Text(_currentStyle.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                const Icon(Icons.arrow_drop_down_rounded, size: 16),
                              ],
                            ),
                          ),
                          itemBuilder: (ctx) => MapStyle.values.map((s) => PopupMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 13)))).toList(),
                        ),

                        // Quick Location Jump
                        PopupMenuButton<Map<String, dynamic>>(
                          onSelected: (loc) => _flyTo(LatLng(loc['lat'] as double, loc['lng'] as double), 15.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.96),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppColors.premiumShadow,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.pin_drop_rounded, size: 14, color: AppColors.brandAccent),
                                SizedBox(width: 6),
                                Text('Quick Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                Icon(Icons.arrow_drop_down_rounded, size: 16),
                              ],
                            ),
                          ),
                          itemBuilder: (ctx) => _quickLocations.map((loc) => PopupMenuItem(value: loc, child: Text(loc['name'] as String, style: const TextStyle(fontSize: 13)))).toList(),
                        ),

                        // Live Sync Button
                        IconButton.filled(
                          iconSize: 16,
                          style: IconButton.styleFrom(backgroundColor: AppColors.brandPrimary),
                          icon: const Icon(Icons.sync_rounded, color: Colors.white),
                          tooltip: 'Refresh',
                          onPressed: _loadLiveFleet,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.96),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppColors.premiumShadow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.circle, size: 8, color: AppColors.brandPrimary),
                              const SizedBox(width: 8),
                              const Text('Live Rider Map', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textPrimary)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.brandPrimaryLight, borderRadius: BorderRadius.circular(10)),
                                child: Text('${_activeOrders.length} In Transit', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brandPrimary)),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.96),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: AppColors.border),
                                boxShadow: AppColors.premiumShadow,
                              ),
                              child: Row(
                                children: _quickLocations.map((loc) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: InkWell(
                                      onTap: () => _flyTo(LatLng(loc['lat'] as double, loc['lng'] as double), 15.0),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        child: Text(loc['name'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            PopupMenuButton<MapStyle>(
                              initialValue: _currentStyle,
                              onSelected: (style) => setState(() => _currentStyle = style),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.96),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: AppColors.premiumShadow,
                                ),
                                child: Row(
                                  children: [
                                    Icon(_currentStyle.icon, size: 15, color: AppColors.brandPrimary),
                                    const SizedBox(width: 6),
                                    Text(_currentStyle.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                    const Icon(Icons.arrow_drop_down_rounded, size: 16),
                                  ],
                                ),
                              ),
                              itemBuilder: (ctx) => MapStyle.values.map((s) => PopupMenuItem(value: s, child: Text(s.label))).toList(),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
                              icon: const Icon(Icons.sync_rounded, size: 16),
                              label: const Text('Refresh'),
                              onPressed: _loadLiveFleet,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            // 3. Floating Live Directions Route HUD
            if (_selectedOrder != null)
              Positioned(
                top: isNarrow ? 70 : 80,
                left: isMobile ? 12 : 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.brandPrimaryLight, width: 1.5),
                    boxShadow: AppColors.premiumShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_bike_rounded, color: AppColors.brandPrimary, size: 18),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_selectedOrder!.orderNumber} Route', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text('${_routeDistanceKm.toStringAsFixed(2)} km', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.brandPrimary)),
                              const SizedBox(width: 8),
                              Text('ETA: ~$_routeEtaMins mins', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // 4. Floating Zoom & Reset Controls (Bottom-Left)
            Positioned(
              bottom: isMobile ? 16 : 24,
              left: isMobile ? 12 : 20,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.premiumShadow,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary, size: 18),
                          tooltip: 'Zoom In',
                          onPressed: _zoomIn,
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_rounded, color: AppColors.textPrimary, size: 18),
                          tooltip: 'Zoom Out',
                          onPressed: _zoomOut,
                        ),
                        IconButton(
                          icon: const Icon(Icons.my_location_rounded, color: AppColors.brandPrimary, size: 18),
                          tooltip: 'Center Map',
                          onPressed: () => _flyTo(const LatLng(7.1280, 124.8310), 15.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 5. Floating Collapsible Drawer (Right Side)
            Positioned(
              top: isNarrow ? 125 : 80,
              bottom: isMobile ? 70 : 24,
              right: isMobile ? 12 : 20,
              width: _isPanelExpanded ? panelWidth : 52,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _isPanelExpanded
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.radar_rounded, size: 18, color: AppColors.brandPrimary),
                                    SizedBox(width: 8),
                                    Text('Active Deliveries', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 20),
                                  tooltip: 'Close Drawer',
                                  onPressed: () => setState(() => _isPanelExpanded = false),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Expanded(
                              child: _activeOrders.isEmpty
                                  ? const Center(child: Text('No Active Orders in Transit', style: TextStyle(fontSize: 12, color: AppColors.textMuted)))
                                  : ListView.separated(
                                      itemCount: _activeOrders.length,
                                      separatorBuilder: (_, __) => const Divider(height: 12),
                                      itemBuilder: (ctx, idx) {
                                        final order = _activeOrders[idx];
                                        final isSelected = _selectedOrder?.id == order.id;

                                        return InkWell(
                                          onTap: () => _selectOrderAndFetchDirections(order),
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isSelected ? AppColors.brandPrimaryLight : const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: isSelected ? AppColors.brandPrimary : AppColors.border),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                                    StatusBadge(status: order.status, isSmall: true),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text('${order.storeName ?? "Store"} → ${order.deliveryAddress}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: IconButton(
                          icon: const Icon(Icons.radar_rounded, size: 22, color: AppColors.brandPrimary),
                          tooltip: 'Open Delivery List',
                          onPressed: () => setState(() => _isPanelExpanded = true),
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapPin({
    required IconData icon,
    required Color color,
    required String label,
    bool isPulsing = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
    );
  }

  void _showDetailsModal(String title, String location, String details) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.brandPrimaryLight, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.pin_drop_rounded, color: AppColors.brandPrimary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(location, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(details, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
