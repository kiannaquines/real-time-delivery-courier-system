import 'enums.dart';

class LocationCoord {
  final double latitude;
  final double longitude;

  const LocationCoord({
    required this.latitude,
    required this.longitude,
  });

  factory LocationCoord.fromJson(Map<String, dynamic> json) {
    return LocationCoord(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

class RiderLocationPoint {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final DateTime timestamp;

  const RiderLocationPoint({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.heading,
    this.speed,
    required this.timestamp,
  });

  factory RiderLocationPoint.fromJson(Map<String, dynamic> json) {
    return RiderLocationPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (accuracy != null) 'accuracy': accuracy,
    if (heading != null) 'heading': heading,
    if (speed != null) 'speed': speed,
    'timestamp': timestamp.toIso8601String(),
  };
}

class DeliverySnapshot {
  final String deliveryId;
  final String orderId;
  final OrderStatus status;
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final LocationCoord? storeLocation;
  final LocationCoord? destinationLocation;
  final RiderLocationPoint? lastRiderLocation;
  final int? etaSeconds;
  final double? remainingDistanceMeters;

  const DeliverySnapshot({
    required this.deliveryId,
    required this.orderId,
    required this.status,
    this.riderId,
    this.riderName,
    this.riderPhone,
    this.storeLocation,
    this.destinationLocation,
    this.lastRiderLocation,
    this.etaSeconds,
    this.remainingDistanceMeters,
  });

  factory DeliverySnapshot.fromJson(Map<String, dynamic> json) {
    return DeliverySnapshot(
      deliveryId: json['delivery_id'] as String,
      orderId: json['order_id'] as String,
      status: OrderStatus.fromString((json['status'] as String?) ?? 'pending'),
      riderId: json['rider_id'] as String?,
      riderName: json['rider_name'] as String?,
      riderPhone: json['rider_phone'] as String?,
      storeLocation: json['store_location'] != null
          ? LocationCoord.fromJson(json['store_location'] as Map<String, dynamic>)
          : null,
      destinationLocation: json['destination_location'] != null
          ? LocationCoord.fromJson(json['destination_location'] as Map<String, dynamic>)
          : null,
      lastRiderLocation: json['last_rider_location'] != null
          ? RiderLocationPoint.fromJson(json['last_rider_location'] as Map<String, dynamic>)
          : null,
      etaSeconds: json['eta_seconds'] as int?,
      remainingDistanceMeters: json['remaining_distance_meters'] != null
          ? (json['remaining_distance_meters'] as num).toDouble()
          : null,
    );
  }
}
