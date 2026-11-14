class LocalPurchaseItem {
  final String id;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  LocalPurchaseItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  }) : totalPrice = unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory LocalPurchaseItem.fromMap(Map<String, dynamic> map) {
    return LocalPurchaseItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  LocalPurchaseItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? unitPrice,
  }) {
    return LocalPurchaseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

class LocalPurchaseAgreement {
  final String id;
  final DateTime dateTime;
  final String sellerName;
  final String? sellerPhone;
  final String? sellerIdCard;
  final String? sellerAddress;
  final String? sellerSignature;
  final String? ownerSignature;
  final String paymentType;
  final List<LocalPurchaseItem> items;
  final double totalAmount;
  final List<String> termsAndConditions;
  final String? notes;

  LocalPurchaseAgreement({
    required this.id,
    required this.dateTime,
    required this.sellerName,
    this.sellerPhone,
    this.sellerIdCard,
    this.sellerAddress,
    this.sellerSignature,
    this.ownerSignature,
    required this.paymentType,
    required this.items,
    required this.totalAmount,
    this.termsAndConditions = const [
      '1. The seller confirms ownership of all items listed above.',
      '2. Items are sold as-is; no returns after agreement is signed.',
      '3. The shop reserves the right to inspect items before final payment.',
      '4. Any dispute shall be resolved under local jurisdiction.',
    ],
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'sellerIdCard': sellerIdCard,
      'sellerAddress': sellerAddress,
      'sellerSignature': sellerSignature,
      'ownerSignature': ownerSignature,
      'paymentType': paymentType,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'termsAndConditions': termsAndConditions,
      'notes': notes,
    };
  }

  factory LocalPurchaseAgreement.fromMap(Map<String, dynamic> map) {
    List<LocalPurchaseItem> parsedItems = [];
    final itemsList = map['items'];
    if (itemsList is List) {
      for (var item in itemsList) {
        try {
          if (item is Map) {
            parsedItems.add(
              LocalPurchaseItem.fromMap(Map<String, dynamic>.from(item)),
            );
          }
        } catch (e) {
          // Skip invalid items
        }
      }
    }

    List<String> parsedTerms = [];
    final termsList = map['termsAndConditions'];
    if (termsList is List) {
      for (var term in termsList) {
        if (term is String) parsedTerms.add(term);
      }
    }

    return LocalPurchaseAgreement(
      id: map['id'] as String? ?? '',
      dateTime:
          DateTime.tryParse(map['dateTime'] as String? ?? '') ?? DateTime.now(),
      sellerName: map['sellerName'] as String? ?? '',
      sellerPhone: map['sellerPhone'] as String?,
      sellerIdCard: map['sellerIdCard'] as String?,
      sellerAddress: map['sellerAddress'] as String?,
      sellerSignature: map['sellerSignature'] as String?,
      ownerSignature: map['ownerSignature'] as String?,
      paymentType: map['paymentType'] as String? ?? 'Cash',
      items: parsedItems,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      termsAndConditions:
          parsedTerms.isNotEmpty
              ? parsedTerms
              : const [
                '1. The seller confirms ownership of all items listed above.',
                '2. Items are sold as-is; no returns after agreement is signed.',
                '3. The shop reserves the right to inspect items before final payment.',
                '4. Any dispute shall be resolved under local jurisdiction.',
              ],
      notes: map['notes'] as String?,
    );
  }

  LocalPurchaseAgreement copyWith({
    String? id,
    DateTime? dateTime,
    String? sellerName,
    String? sellerPhone,
    String? sellerIdCard,
    String? sellerAddress,
    String? sellerSignature,
    String? ownerSignature,
    String? paymentType,
    List<LocalPurchaseItem>? items,
    double? totalAmount,
    List<String>? termsAndConditions,
    String? notes,
    bool clearSellerPhone = false,
    bool clearSellerIdCard = false,
    bool clearSellerAddress = false,
    bool clearSellerSignature = false,
    bool clearOwnerSignature = false,
    bool clearNotes = false,
  }) {
    return LocalPurchaseAgreement(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: clearSellerPhone ? null : (sellerPhone ?? this.sellerPhone),
      sellerIdCard:
          clearSellerIdCard ? null : (sellerIdCard ?? this.sellerIdCard),
      sellerAddress:
          clearSellerAddress ? null : (sellerAddress ?? this.sellerAddress),
      sellerSignature:
          clearSellerSignature
              ? null
              : (sellerSignature ?? this.sellerSignature),
      ownerSignature:
          clearOwnerSignature ? null : (ownerSignature ?? this.ownerSignature),
      paymentType: paymentType ?? this.paymentType,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }
}
