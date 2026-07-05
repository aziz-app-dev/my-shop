class Customer {
  final String id;
  final String name;
  final String address;
  final String phoneNumber;
  final int visitCount; // Number of times the customer has made a purchase
  final List<String> billIds; // List of bill IDs associated with this customer
  final double totalPendingAmount; // Total amount pending from all bills
  final double totalPaidAmount; // Total amount paid across all bills

  Customer({
    required this.id,
    required this.name,
    this.address = '',
    this.phoneNumber = '',
    this.visitCount = 0,
    this.billIds = const [],
    this.totalPendingAmount = 0.0,
    this.totalPaidAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'visitCount': visitCount,
      'billIds': billIds,
      'totalPendingAmount': totalPendingAmount,
      'totalPaidAmount': totalPaidAmount,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      address: map['address'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      visitCount: map['visitCount'] as int? ?? 0,
      billIds: List<String>.from(map['billIds'] ?? []),
      totalPendingAmount: (map['totalPendingAmount'] as num?)?.toDouble() ?? 0.0,
      totalPaidAmount: (map['totalPaidAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Customer copyWith({
    String? id,
    String? name,
    String? address,
    String? phoneNumber,
    int? visitCount,
    List<String>? billIds,
    double? totalPendingAmount,
    double? totalPaidAmount,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      visitCount: visitCount ?? this.visitCount,
      billIds: billIds ?? this.billIds,
      totalPendingAmount: totalPendingAmount ?? this.totalPendingAmount,
      totalPaidAmount: totalPaidAmount ?? this.totalPaidAmount,
    );
  }
}
