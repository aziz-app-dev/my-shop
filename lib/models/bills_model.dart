import 'items_model.dart';

class Bill {
  final String id;
  final DateTime dateTime;
  final List<Product> items;
  final Map<String, int> quantities;
  final double totalAmount;
  final String? customerName;
  final String? customerId;
  final String status;
  final String? paymentMethod;
  final double discount;
  final double paidAmount;

  Bill({
    required this.id,
    required this.dateTime,
    required this.items,
    required this.quantities,
    required this.totalAmount,
    this.customerName,
    this.customerId,
    required this.status,
    this.paymentMethod,
    this.discount = 0.0,
    this.paidAmount = 0.0,
  });

  // Computed properties for payment calculations

  /// Returns the total amount after applying discount
  double get totalAfterDiscount => totalAmount - discount;

  /// Returns the pending/remaining amount to be paid
  double get pendingAmount {
    final remaining = totalAfterDiscount - paidAmount;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Returns true if the bill is fully paid
  bool get isFullyPaid => pendingAmount <= 0.01; // Using small tolerance for floating point

  /// Returns true if this is a partial payment
  bool get isPartialPayment => paidAmount > 0 && pendingAmount > 0.01;

  /// Returns the payment completion percentage (0-100)
  double get paymentPercentage {
    if (totalAfterDiscount <= 0) return 100.0;
    return (paidAmount / totalAfterDiscount * 100).clamp(0.0, 100.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'quantities': quantities,
      'totalAmount': totalAmount,
      'customerName': customerName,
      'customerId': customerId,
      'status': status,
      'paymentMethod': paymentMethod,
      'discount': discount,
      'paidAmount': paidAmount,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    // Safely parse items list
    List<Product> parsedItems = [];
    final itemsList = map['items'];
    if (itemsList is List) {
      for (var item in itemsList) {
        try {
          if (item is Map) {
            parsedItems.add(Product.fromMap(Map<String, dynamic>.from(item)));
          }
          // Skip if item is not a Map (e.g., String or other invalid type)
        } catch (e) {
          // Skip invalid items
        }
      }
    }

    // Safely parse quantities
    Map<String, int> parsedQuantities = {};
    final quantities = map['quantities'];
    if (quantities is Map) {
      quantities.forEach((key, value) {
        if (value is int) {
          parsedQuantities[key.toString()] = value;
        } else if (value is num) {
          parsedQuantities[key.toString()] = value.toInt();
        }
      });
    }

    return Bill(
      id: map['id'] as String? ?? '',
      dateTime: DateTime.tryParse(
            map['dateTime'] as String? ?? '',
          ) ??
          DateTime.now(),
      items: parsedItems,
      quantities: parsedQuantities,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      customerName: map['customerName'] as String?,
      customerId: map['customerId'] as String?,
      status: map['status'] as String? ?? 'Pending',
      paymentMethod: map['paymentMethod'] as String?,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Bill copyWith({
    String? id,
    DateTime? dateTime,
    List<Product>? items,
    Map<String, int>? quantities,
    double? totalAmount,
    String? customerName,
    String? customerId,
    String? status,
    String? paymentMethod,
    double? discount,
    double? paidAmount,
  }) {
    return Bill(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      items: items ?? this.items,
      quantities: quantities ?? this.quantities,
      totalAmount: totalAmount ?? this.totalAmount,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      discount: discount ?? this.discount,
      paidAmount: paidAmount ?? this.paidAmount,
    );
  }
}
