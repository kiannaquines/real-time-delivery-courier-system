import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';

class RealtimeDeliveryClient {
  final ApiClient apiClient;
  final Duration pollingInterval;

  final _locationController = StreamController<RiderLocationPoint>.broadcast();
  final _snapshotController = StreamController<DeliverySnapshot>.broadcast();

  Stream<RiderLocationPoint> get onLocationUpdated => _locationController.stream;
  Stream<DeliverySnapshot> get onSnapshotUpdated => _snapshotController.stream;

  Timer? _pollingTimer;
  String? _currentDeliveryId;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  RealtimeDeliveryClient({
    required this.apiClient,
    this.pollingInterval = const Duration(seconds: 8),
  });

  Future<void> startTracking(String deliveryId) async {
    stopTracking();
    _currentDeliveryId = deliveryId;
    _isTracking = true;

    // 1. Initial snapshot fetch
    await _fetchLatestSnapshot();

    // 2. Continuous reliable polling loop (serving as real-time heartbeat and fallback)
    _pollingTimer = Timer.periodic(pollingInterval, (_) async {
      if (_isTracking && _currentDeliveryId != null) {
        await _fetchLatestSnapshot();
      }
    });
  }

  Future<void> _fetchLatestSnapshot() async {
    if (_currentDeliveryId == null) return;
    try {
      final snapshot = await apiClient.getDeliverySnapshot(_currentDeliveryId!);
      if (!_snapshotController.isClosed) {
        _snapshotController.add(snapshot);
      }
      if (snapshot.lastRiderLocation != null && !_locationController.isClosed) {
        _locationController.add(snapshot.lastRiderLocation!);
      }

      // Stop tracking automatically if delivery reaches terminal state
      if (snapshot.status == OrderStatus.delivered || snapshot.status == OrderStatus.cancelled) {
        stopTracking();
      }
    } catch (e) {
      debugPrint('Realtime snapshot polling error: $e');
    }
  }

  void stopTracking() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _currentDeliveryId = null;
    _isTracking = false;
  }

  void dispose() {
    stopTracking();
    _locationController.close();
    _snapshotController.close();
  }
}
