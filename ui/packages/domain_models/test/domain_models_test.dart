import 'package:flutter_test/flutter_test.dart';
import 'package:domain_models/domain_models.dart';

void main() {
  group('Domain Models Tests', () {
    test('OrderStatus serialization and label', () {
      expect(OrderStatus.fromString('picked_up'), OrderStatus.pickedUp);
      expect(OrderStatus.pickedUp.toJson(), 'picked_up');
      expect(OrderStatus.pickedUp.label, 'Picked Up');
    });

    test('Formatters test', () {
      expect(Formatters.currency(150.5), '₱150.50');
      expect(Formatters.distance(0.85), '850m');
      expect(Formatters.distance(2.45), '2.5 km');
      expect(Formatters.duration(75), '1h 15m');
    });
  });
}
