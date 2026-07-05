import '../../models/items_model.dart';

class CartSession {
  final String id;
  final String name; // "Cart 1", "Cart 2", or customer name if assigned
  final Map<Product, int> cartItems;
  final double totalAmount;
  final double discount;
  final double paidAmount;
  final DateTime createdAt;
  final String? customerName;
  final String? customerId;
  final bool isPaid;
  final String? paymentMethod;

  CartSession({
    required this.id,
    required this.name,
    this.cartItems = const {},
    this.totalAmount = 0.0,
    this.discount = 0.0,
    this.paidAmount = 0.0,
    required this.createdAt,
    this.customerName,
    this.customerId,
    this.isPaid = false,
    this.paymentMethod,
  });

  CartSession copyWith({
    String? id,
    String? name,
    Map<Product, int>? cartItems,
    double? totalAmount,
    double? discount,
    double? paidAmount,
    DateTime? createdAt,
    String? customerName,
    String? customerId,
    bool? isPaid,
    String? paymentMethod,
  }) {
    return CartSession(
      id: id ?? this.id,
      name: name ?? this.name,
      cartItems: cartItems ?? this.cartItems,
      totalAmount: totalAmount ?? this.totalAmount,
      discount: discount ?? this.discount,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  bool get isEmpty => cartItems.isEmpty;
  int get itemCount => cartItems.values.fold(0, (sum, qty) => sum + qty);
}

class MultiCartState {
  final List<CartSession> carts;
  final String? activeCartId;

  MultiCartState({
    this.carts = const [],
    this.activeCartId,
  });

  CartSession? get activeCart {
    if (activeCartId == null) return null;
    try {
      return carts.firstWhere((cart) => cart.id == activeCartId);
    } catch (e) {
      return null;
    }
  }

  MultiCartState copyWith({
    List<CartSession>? carts,
    String? activeCartId,
  }) {
    return MultiCartState(
      carts: carts ?? this.carts,
      activeCartId: activeCartId ?? this.activeCartId,
    );
  }
}
