import 'enums.dart';

class User {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final UserRole role;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: (json['phone'] as String?) ?? '',
      role: UserRole.fromString((json['role'] as String?) ?? 'customer'),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'phone': phone,
    'role': role.toJson(),
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}

class Address {
  final String id;
  final String customerId;
  final String label;
  final String addressLine;
  final double latitude;
  final double longitude;
  final String? deliveryNotes;
  final bool isDefault;

  const Address({
    required this.id,
    required this.customerId,
    required this.label,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
    this.deliveryNotes,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      customerId: (json['customer_id'] as String?) ?? '',
      label: json['label'] as String,
      addressLine: json['address_line'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      deliveryNotes: json['delivery_notes'] as String?,
      isDefault: (json['is_default'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'label': label,
    'address_line': addressLine,
    'latitude': latitude,
    'longitude': longitude,
    'delivery_notes': deliveryNotes,
    'is_default': isDefault,
  };
}

class RiderProfile {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final RiderStatus status;
  final String vehicleType;
  final String plateNumber;
  final String? activeDeliveryId;

  const RiderProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.status,
    required this.vehicleType,
    required this.plateNumber,
    this.activeDeliveryId,
  });

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    return RiderProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: (json['phone'] as String?) ?? '',
      status: RiderStatus.fromString((json['status'] as String?) ?? 'offline'),
      vehicleType: (json['vehicle_type'] as String?) ?? 'Motorcycle',
      plateNumber: (json['plate_number'] as String?) ?? '',
      activeDeliveryId: json['active_delivery_id'] as String?,
    );
  }
}
