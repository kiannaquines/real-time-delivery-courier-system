import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:api_client/api_client.dart';

void main() {
  group('ApiClient Tests', () {
    test('getStores parses store list response correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/stores');
        return http.Response(
          jsonEncode([
            {
              'id': 'store-1',
              'name': 'M&S Central',
              'address': 'BGC Taguig',
              'latitude': 14.55,
              'longitude': 121.05,
              'is_active': true,
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:8000', client: mockClient);
      final stores = await apiClient.getStores();
      expect(stores.length, 1);
      expect(stores.first.name, 'M&S Central');
    });

    test('handles 400 ApiException properly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'code': 'INVALID_DATA', 'message': 'Invalid input data'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:8000', client: mockClient);
      expect(
        () => apiClient.getStores(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });
  });
}
