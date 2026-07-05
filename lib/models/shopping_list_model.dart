// Model for Shopping List (the list itself)
class ShoppingList {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ShoppingList copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Model for Shopping List Items
class ShoppingListItem {
  final String id;
  final String listId; // Reference to the shopping list
  final String productId;
  final String productName;
  final String? productImageUrl;
  final int quantityNeeded;
  final bool isShopped;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? price;
  final String? brand;

  ShoppingListItem({
    required this.id,
    required this.listId,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.quantityNeeded,
    this.isShopped = false,
    required this.createdAt,
    required this.updatedAt,
    this.price,
    this.brand,
  });

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'],
      listId: map['listId'] ?? '', // Default to empty for backward compatibility
      productId: map['productId'],
      productName: map['productName'],
      productImageUrl: map['productImageUrl'],
      quantityNeeded: map['quantityNeeded'],
      isShopped: map['isShopped'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      price: map['price'],
      brand: map['brand'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listId': listId,
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'quantityNeeded': quantityNeeded,
      'isShopped': isShopped,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'price': price,
      'brand': brand,
    };
  }

  ShoppingListItem copyWith({
    String? id,
    String? listId,
    String? productId,
    String? productName,
    String? productImageUrl,
    int? quantityNeeded,
    bool? isShopped,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? price,
    String? brand,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      quantityNeeded: quantityNeeded ?? this.quantityNeeded,
      isShopped: isShopped ?? this.isShopped,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      price: price ?? this.price,
      brand: brand ?? this.brand,
    );
  }
}
