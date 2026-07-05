/// A single line item on a repair — a part/product used or a service charge.
/// Can be picked from inventory (productId set) or typed freely (productId '').
class RepairItem {
  final String productId; // '' for a custom/free-typed line item
  final String name;
  final double price;
  final int quantity;

  const RepairItem({
    this.productId = '',
    required this.name,
    this.price = 0.0,
    this.quantity = 1,
  });

  double get total => price * quantity;

  factory RepairItem.fromMap(Map<String, dynamic> map) {
    return RepairItem(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };

  RepairItem copyWith({
    String? productId,
    String? name,
    double? price,
    int? quantity,
  }) {
    return RepairItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}

// Model for a Repair job — an item (e.g. a laptop) taken from a client for repair.
class Repair {
  final String id;

  // Client info. customerId links to an existing Customer (optional — the user
  // can also just type a name for a walk-in client).
  final String? customerId;
  final String clientName;
  final String clientPhone;

  // Device / item details
  final String deviceType; // e.g. Laptop, Phone, Tablet, Desktop, Other
  final String brand;
  final String model;
  final String serialNumber;
  final String? imageUrl; // photo of the item

  // Problem & accessories
  final String problem; // reported fault / what to repair
  final String accessories; // e.g. charger, bag, mouse

  // Parts/services used in the repair.
  final List<RepairItem> items;

  // Cost & dates
  final double estimatedCost;
  final double advancePaid;
  final DateTime receivedDate;
  final DateTime? expectedDate;

  // Status — simple completed toggle (open vs done)
  final bool isCompleted;

  final DateTime createdAt;
  final DateTime updatedAt;

  Repair({
    required this.id,
    this.customerId,
    required this.clientName,
    this.clientPhone = '',
    this.deviceType = '',
    this.brand = '',
    this.model = '',
    this.serialNumber = '',
    this.imageUrl,
    this.problem = '',
    this.accessories = '',
    this.items = const [],
    this.estimatedCost = 0.0,
    this.advancePaid = 0.0,
    required this.receivedDate,
    this.expectedDate,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Sum of all line items (parts/services).
  double get itemsTotal =>
      items.fold(0.0, (sum, item) => sum + item.total);

  // Remaining balance to collect when the item is handed back.
  double get balanceDue =>
      (estimatedCost - advancePaid) < 0 ? 0 : (estimatedCost - advancePaid);

  factory Repair.fromMap(Map<String, dynamic> map) {
    return Repair(
      id: map['id'] as String? ?? '',
      customerId: map['customerId'] as String?,
      clientName: map['clientName'] as String? ?? 'Unknown',
      clientPhone: map['clientPhone'] as String? ?? '',
      deviceType: map['deviceType'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      model: map['model'] as String? ?? '',
      serialNumber: map['serialNumber'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      problem: map['problem'] as String? ?? '',
      accessories: map['accessories'] as String? ?? '',
      items:
          (map['items'] as List?)
              ?.map((e) => RepairItem.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      estimatedCost: (map['estimatedCost'] as num?)?.toDouble() ?? 0.0,
      advancePaid: (map['advancePaid'] as num?)?.toDouble() ?? 0.0,
      receivedDate:
          DateTime.tryParse(map['receivedDate'] as String? ?? '') ??
          DateTime.now(),
      expectedDate:
          map['expectedDate'] != null
              ? DateTime.tryParse(map['expectedDate'] as String)
              : null,
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'deviceType': deviceType,
      'brand': brand,
      'model': model,
      'serialNumber': serialNumber,
      'imageUrl': imageUrl,
      'problem': problem,
      'accessories': accessories,
      'items': items.map((e) => e.toMap()).toList(),
      'estimatedCost': estimatedCost,
      'advancePaid': advancePaid,
      'receivedDate': receivedDate.toIso8601String(),
      'expectedDate': expectedDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Repair copyWith({
    String? id,
    String? customerId,
    String? clientName,
    String? clientPhone,
    String? deviceType,
    String? brand,
    String? model,
    String? serialNumber,
    String? imageUrl,
    String? problem,
    String? accessories,
    List<RepairItem>? items,
    double? estimatedCost,
    double? advancePaid,
    DateTime? receivedDate,
    DateTime? expectedDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Repair(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      deviceType: deviceType ?? this.deviceType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      problem: problem ?? this.problem,
      accessories: accessories ?? this.accessories,
      items: items ?? this.items,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      advancePaid: advancePaid ?? this.advancePaid,
      receivedDate: receivedDate ?? this.receivedDate,
      expectedDate: expectedDate ?? this.expectedDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
