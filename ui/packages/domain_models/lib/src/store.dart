class Store {
  final String id;
  final String name;
  final String? description;
  final String address;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final bool isActive;

  const Store({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.isActive = true,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'image_url': imageUrl,
    'is_active': isActive,
  };
}

class MenuCategory {
  final String id;
  final String storeId;
  final String name;
  final int displayOrder;

  const MenuCategory({
    required this.id,
    required this.storeId,
    required this.name,
    required this.displayOrder,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      name: json['name'] as String,
      displayOrder: (json['display_order'] as int?) ?? 0,
    );
  }
}

class MenuItem {
  final String id;
  final String storeId;
  final String? categoryId;
  final String? categoryName;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;

  const MenuItem({
    required this.id,
    required this.storeId,
    this.categoryId,
    this.categoryName,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      isAvailable: (json['is_available'] as bool?) ?? true,
    );
  }
}

class StoreDetail {
  final Store store;
  final List<MenuCategory> categories;
  final List<MenuItem> items;

  const StoreDetail({
    required this.store,
    required this.categories,
    required this.items,
  });

  factory StoreDetail.fromJson(Map<String, dynamic> json) {
    return StoreDetail(
      store: Store.fromJson(json['store'] as Map<String, dynamic>),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((c) => MenuCategory.fromJson(c as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => MenuItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}
