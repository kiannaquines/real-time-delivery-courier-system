import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'session_storage.dart';

enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
}

class AuthSessionManager extends ChangeNotifier {
  final ApiClient apiClient;
  final SessionStorage storage;

  AuthStatus _status = AuthStatus.unauthenticated;
  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;

  AuthSessionManager({
    required this.apiClient,
    SessionStorage? storage,
  }) : storage = storage ?? InMemorySessionStorage();

  Future<void> initialize() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final savedAccess = await storage.read('access_token');
      final savedRefresh = await storage.read('refresh_token');
      final savedUserJson = await storage.read('user_profile');

      if (savedAccess != null && savedUserJson != null) {
        _accessToken = savedAccess;
        _refreshToken = savedRefresh;
        _currentUser = User.fromJson(jsonDecode(savedUserJson) as Map<String, dynamic>);
        apiClient.setAuthToken(_accessToken);
        _status = AuthStatus.authenticated;
      } else if (savedRefresh != null) {
        await _refreshSession(savedRefresh);
      } else {
        apiClient.setAuthToken(null);
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      apiClient.setAuthToken(null);
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final response = await apiClient.login(email: email, password: password);
      await _saveSession(response);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> registerCustomer({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final response = await apiClient.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      await _saveSession(response);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> _refreshSession(String refreshToken) async {
    try {
      final response = await apiClient.refreshToken(refreshToken);
      await _saveSession(response);
      _status = AuthStatus.authenticated;
    } catch (_) {
      await logout();
    }
  }

  Future<void> _saveSession(Map<String, dynamic> response) async {
    _accessToken = response['access_token'] as String;
    _refreshToken = response['refresh_token'] as String;
    final userJson = response['user'] as Map<String, dynamic>;
    _currentUser = User.fromJson(userJson);

    apiClient.setAuthToken(_accessToken);

    await storage.write('access_token', _accessToken!);
    await storage.write('refresh_token', _refreshToken!);
    await storage.write('user_profile', jsonEncode(userJson));
  }

  Future<void> logout() async {
    _status = AuthStatus.unauthenticated;
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    apiClient.setAuthToken(null);
    await storage.clear();
    notifyListeners();
  }

  String? getToken() => _accessToken;
}
