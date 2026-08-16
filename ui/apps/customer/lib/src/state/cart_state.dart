import 'package:flutter/foundation.dart';
import 'package:domain_models/domain_models.dart';

class CartItem {
  final MenuItem item;
  int quantity;
  String? specialInstructions;

  CartItem({
    required this.item,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get subtotal => item.price * quantity;
}

class CartState extends ChangeNotifier {
  Store? _activeStore;
  final List<CartItem> _items = [];

  Store? get activeStore => _activeStore;
  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  int get totalItems => _items.fold(0, (sum, i) => sum + i.quantity);
  int get itemCount => totalItems;
  int get totalItemCount => totalItems;
  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.subtotal);

  void addItem(Store store, MenuItem item, {int quantity = 1, String? specialInstructions}) {
    // Enforce single-store cart invariant
    if (_activeStore != null && _activeStore!.id != store.id) {
      _items.clear();
    }
    _activeStore = store;

    final existingIndex = _items.indexWhere((i) => i.item.id == item.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
      if (specialInstructions != null) {
        _items[existingIndex].specialInstructions = specialInstructions;
      }
    } else {
      _items.add(CartItem(item: item, quantity: quantity, specialInstructions: specialInstructions));
    }
    notifyListeners();
  }

  void updateQuantity(String menuItemId, int newQuantity) {
    if (newQuantity <= 0) {
      _items.removeWhere((i) => i.item.id == menuItemId);
      if (_items.isEmpty) _activeStore = null;
    } else {
      final index = _items.indexWhere((i) => i.item.id == menuItemId);
      if (index >= 0) {
        _items[index].quantity = newQuantity;
      }
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _activeStore = null;
    notifyListeners();
  }
}
