import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:domain_models/domain_models.dart';
import 'api_exception.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final TokenProvider? tokenProvider;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.tokenProvider,
  }) : _client = client ?? http.Client();

  String get _normalizedBaseUrl => baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  String? _authToken;
  void setAuthToken(String? token) => _authToken = token;

  Future<Map<String, String>> _headers({String? idempotencyKey}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = (tokenProvider != null ? await tokenProvider!() : null) ?? _authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String code = 'HTTP_ERROR';
    String message = 'Server error occurred.';
    Map<String, dynamic>? details;

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      code = body['code'] as String? ?? 'HTTP_${response.statusCode}';
      message = body['message'] as String? ?? (body['detail'] as String? ?? 'Error: ${response.statusCode}');
      if (body['details'] is Map<String, dynamic>) {
        details = body['details'] as Map<String, dynamic>;
      }
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : 'Status ${response.statusCode}';
    }

    throw ApiException(
      statusCode: response.statusCode,
      code: code,
      message: message,
      details: details,
    );
  }

  // --- Auth Endpoints ---
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final headers = await _headers();
    final resp = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/v1/auth/register'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone,
      }),
    );
    return _handleResponse(resp) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final headers = await _headers();
    final resp = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/v1/auth/login'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return _handleResponse(resp) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final headers = await _headers();
    final resp = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/v1/auth/refresh'),
      headers: headers,
      body: jsonEncode({'refresh_token': refreshToken}),
    );
    return _handleResponse(resp) as Map<String, dynamic>;
  }

  Future<User> getMe() async {
    final headers = await _headers();
    final resp = await _client.get(
      Uri.parse('$_normalizedBaseUrl/api/v1/auth/me'),
      headers: headers,
    );
    final json = _handleResponse(resp) as Map<String, dynamic>;
    return User.fromJson(json);
  }

  // --- Store & Menu Endpoints ---
  Future<List<Store>> getStores({bool? isActive}) async {
    final headers = await _headers();
    final uri = Uri.parse('$_normalizedBaseUrl/api/v1/stores').replace(
      queryParameters: isActive != null ? {'is_active': isActive.toString()} : null,
    );
    final resp = await _client.get(uri, headers: headers);
    final list = _handleResponse(resp) as List<dynamic>;
    return list.map((s) => Store.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<StoreDetail> getStoreDetail(String storeId) async {
    final headers = await _headers();
    final resp = await _client.get(
      Uri.parse('$_normalizedBaseUrl/api/v1/stores/$storeId'),
      headers: headers,
    );
    final json = _handleResponse(resp) as Map<String, dynamic>;
    return StoreDetail.fromJson(json);
  }

  Future<Store> createStore({
    required String name,
    String? description,
    required String address,
    required double latitude,
    required double longitude,
    String? imageUrl,
    bool isActive = true,
  }) async {
    final headers = await _headers();
    final resp = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/v1/stores'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'image_url': imageUrl,
        'is_active': isActive,
      }),
    );
    return Store.fromJson(_handleResponse(resp) as Map<String, dynamic>);
  }

  Future<MenuItem> createMenuItem({
    required String storeId,
    String? categoryId,
    required String name,
    String? description,
    required double price,
    String? imageUrl,
    bool isAvailable = true,
  }) async {
    final headers = await _headers();
    final resp = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/v1/menu-items'),
      headers: headers,
      body: jsonEncode({
        'store_id': storeId,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'image_url': imageUrl,
        'is_available': isAvailable,
      }),
    );
    return MenuItem.fromJson(_handleResponse(resp) as Map<String, dynamic>);
  }

  // --- Customer Address Endpoints ---
  Future<List<Address>> getAddresses() async {
    final headers = await _headers();
    final resp = await _client.get(
      Uri.parse('$_normalizedBaseUrl/api/v1/customers/addresses'),
      headers: headers,
    );
    final list = _handleResponse(resp) as List<dynamic>;
    return list.map((a) => Address.fromJson(a as Map<String, dynamic>)).toList();
  }

  Future<Address> createAddress({
    required String label,
    required String addressLine,
    required double latitude,
    required double longitude,
    String? deliveryNotes,
    bool isDefault = false,
  }) async {
    final headers = await _headers();
    final resp = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/v1/customers/addresses'),
      headers: headers,
      body: jsonEncode({
        'label': label,
        'address_line': addressLine,
        'latitude': latitude,
        'longitude': longitude,
        'delivery_notes': deliveryNotes,
        'is_default': isDefault,
      }),
    );
    return Address.fromJson(_handleResponse(resp) as Map<String, dynamic>);
  }

  Future<Address> setDefaultAddress(String addressId) async {
    final headers = await _headers();
    final resp = await _client.put(
      Uri.parse('$_normalizedBaseUrl/api/v1/customers/addresses/$addressId/default'),
      headers: headers,
    );
    return Address.fromJson(_handleResponse(resp) as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String addressId) async {
    final headers = await _headers();
    final resp = await _client.delete(
      Uri.parse('$_normalizedBaseUrl/api/v1/customers/addresses/$addressId'),
      headers: headers,
    );
    if (resp.statusCode != 204 && resp.statusCode != 200) {
      _handleResponse(resp);
    }
  }

  // --- Order Endpoints ---
  Future<Map<String, dynamic>> previewFee({
    required String storeId,
    required double deliveryLatitude,
    required double deliveryLongitude,
  }) async {
    final headers = await _headers();
    final resp = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/v1/orders/preview-fee'),
      headers: headers,
      body: jsonEncode({
        'store_id': storeId,
        'delivery_latitude': deliveryLatitude,
        'delivery_longitude': deliveryLongitude,
      }),
    );
    return _handleResponse(resp) as Map<String, dynamic>;
  }

  Future<Order> createOrder({
    required String storeId,
    required String addressId,
    required List<Map<String, dynamic>> items,
    String? notes,
    required String idempotencyKey,
  }) async {
    final headers = await _headers(idempotencyKey: idempotencyKey);
    final resp = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/v1/orders'),
      headers: headers,
      body: jsonEncode({
        'store_id': storeId,
        'address_id': addressId,
        'items': items,
        'notes': notes,
      }),
    );
    return Order.fromJson(_handleResponse(resp) as Map<String, dynamic>);
  }

  Future<List<Order>> getOrders({OrderStatus? status, String? storeId}) async {
    final headers = await _headers();
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status.toJson();
    if (storeId != null) queryParams['store_id'] = storeId;

    final uri = Uri.parse('$_normalizedBaseUrl/api/v1/orders').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final resp = await _client.get(uri, headers: headers);
    final list = _handleResponse(resp) as List<dynamic>;
    return list.map((o) => Order.fromJson(o as Map<String, dynamic>)).toList();
  }

  Future<OrderDetail> getOrderDetail(String orderId) async {
    final headers = await _headers();
    final resp = await _client.get(
      Uri.parse('$_normalizedBaseUrl/api/v1/orders/$orderId'),
      headers: headers,
    );
    return OrderDetail.fromJson(_handleResponse(resp) as Map<String, dynamic>);
  }

  Future<Order> cancelOrder(String orderId, String reason) async {
    final headers = await _headers();
    final resp = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/v1/orders/$orderId/cancel'),
      headers: headers,
      body: jsonEncode({'reason': reason}),
    );
    return Order.fromJson(_handleResponse(resp) as Map<String, dynamic>);
  }

  Future<OrderDetail> assignOrder(String orderId, String riderId) async {
    final headers = await _headers();
    final resp = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/v1/orders/$orderId/assign'),
      headers: headers,
      body: jsonEncode({'rider_id': riderId}),
    );
    return OrderDetail.fromJson(_handleResponse(resp) as Map<String, dynamic>);
  }

  // --- Delivery Endpoints ---
  Future<DeliverySummary> updateDeliveryStatus(
    String deliveryId,
    OrderStatus status, {
    bool codCollected = false,
    String? auditReason,
  }) async {
    final headers = await _headers();
    final resp = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/v1/deliveries/$deliveryId/status'),
      headers: headers,
      body: jsonEncode({
        'status': status.toJson(),
        'cod_collected': codCollected,
        'audit_reason': auditReason,
      }),
    );
    return DeliverySummary.fromJson(_handleResponse(resp) as Map<String, dynamic>);
  }

  Future<void> sendRiderLocations(String deliveryId, List<RiderLocationPoint> points) async {
    final headers = await _headers();
    final resp = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/v1/deliveries/$deliveryId/location'),
      headers: headers,
      body: jsonEncode({
        'locations': points.map((p) => p.toJson()).toList(),
      }),
    );
    _handleResponse(resp);
  }

  Future<DeliverySnapshot> getDeliverySnapshot(String deliveryId) async {
    final headers = await _headers();
    final resp = await _client.get(
      Uri.parse('$_normalizedBaseUrl/api/v1/deliveries/$deliveryId/snapshot'),
      headers: headers,
    );
    return DeliverySnapshot.fromJson(_handleResponse(resp) as Map<String, dynamic>);
  }

  // --- Rider Endpoints ---
  Future<List<RiderProfile>> getRiders() async {
    final headers = await _headers();
    final resp = await _client.get(
      Uri.parse('$_normalizedBaseUrl/api/v1/riders'),
      headers: headers,
    );
    final list = _handleResponse(resp) as List<dynamic>;
    return list.map((r) => RiderProfile.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<RiderProfile> createRider({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String vehicleType = 'Motorcycle',
    required String plateNumber,
  }) async {
    final headers = await _headers();
    final resp = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/v1/riders'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone,
        'vehicle_type': vehicleType,
        'plate_number': plateNumber,
      }),
    );
    return RiderProfile.fromJson(_handleResponse(resp) as Map<String, dynamic>);
  }

  Future<RiderProfile> updateRiderStatus(RiderStatus status) async {
    final headers = await _headers();
    final resp = await _client.put(
      Uri.parse('$_normalizedBaseUrl/api/v1/riders/status'),
      headers: headers,
      body: jsonEncode({'status': status.name}),
    );
    return RiderProfile.fromJson(_handleResponse(resp) as Map<String, dynamic>);
  }

  Future<OrderDetail?> getRiderActiveDelivery() async {
    final headers = await _headers();
    final resp = await _client.get(
      Uri.parse('$_normalizedBaseUrl/api/v1/riders/active-delivery'),
      headers: headers,
    );
    final data = _handleResponse(resp);
    if (data == null) return null;
    return OrderDetail.fromJson(data as Map<String, dynamic>);
  }

  // --- Reports & Uploads ---
  Future<Map<String, dynamic>> getSignedUploadUrl({
    required String filename,
    required String contentType,
    required int sizeBytes,
  }) async {
    final headers = await _headers();
    final resp = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/v1/uploads/signed-url'),
      headers: headers,
      body: jsonEncode({
        'filename': filename,
        'content_type': contentType,
        'size_bytes': sizeBytes,
      }),
    );
    return _handleResponse(resp) as Map<String, dynamic>;
  }

  // --- Supabase & Database Health Diagnostics ---
  Future<Map<String, dynamic>> getSupabaseHealth() async {
    final headers = await _headers();
    final resp = await _client.get(
      Uri.parse('$_normalizedBaseUrl/api/v1/health/supabase'),
      headers: headers,
    );
    return _handleResponse(resp) as Map<String, dynamic>;
  }
}

