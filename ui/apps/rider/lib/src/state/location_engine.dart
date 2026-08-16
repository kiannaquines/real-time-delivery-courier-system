import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';

class LocationEngine extends ChangeNotifier {
  final ApiClient apiClient;

  bool _isSharingLocation = false;
  String? _activeDeliveryId;
  Timer? _locationTimer;
  RiderLocationPoint? _lastKnownPoint;
  final List<RiderLocationPoint> _offlineQueue = [];

  bool get isSharingLocation => _isSharingLocation;
  RiderLocationPoint? get lastKnownPoint => _lastKnownPoint;
  int get queuedPointsCount => _offlineQueue.length;

  LocationEngine({required this.apiClient});

  void startTracking(String deliveryId) {
    stopTracking();
    _activeDeliveryId = deliveryId;
    _isSharingLocation = true;
    notifyListeners();

    // In production, listens to Geolocator.getPositionStream
    // Simulated GPS pulse: 10s while moving
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) => _simulateAndSendLocation());
    _simulateAndSendLocation();
  }

  Future<void> _simulateAndSendLocation() async {
    if (!_isSharingLocation || _activeDeliveryId == null) return;

    final baseLat = 14.5515 + (Random().nextDouble() - 0.5) * 0.01;
    final baseLng = 121.0505 + (Random().nextDouble() - 0.5) * 0.01;

    final point = RiderLocationPoint(
      latitude: baseLat,
      longitude: baseLng,
      accuracy: 4.5,
      heading: (Random().nextDouble() * 360).roundToDouble(),
      speed: 6.0 + Random().nextDouble() * 2.0,
      timestamp: DateTime.now(),
    );

    _lastKnownPoint = point;
    _offlineQueue.add(point);
    notifyListeners();

    await flushQueue();
  }

  Future<void> flushQueue() async {
    if (_offlineQueue.isEmpty || _activeDeliveryId == null) return;

    final pointsToSend = List<RiderLocationPoint>.from(_offlineQueue);
    try {
      await apiClient.sendRiderLocations(_activeDeliveryId!, pointsToSend);
      // Remove successfully sent points
      _offlineQueue.removeWhere((p) => pointsToSend.contains(p));
      notifyListeners();
    } catch (e) {
      debugPrint('Offline location queue buffering: $e (${_offlineQueue.length} points pending)');
    }
  }

  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _activeDeliveryId = null;
    _isSharingLocation = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
