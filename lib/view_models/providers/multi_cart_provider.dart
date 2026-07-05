import 'package:flutter/material.dart';
import '../../models/items_model.dart';
import '../states/multi_cart_state.dart';
import 'package:riverpod/legacy.dart';

class MultiCartNotifier extends StateNotifier<MultiCartState> {
  MultiCartNotifier() : super(MultiCartState()) {
    // Create initial cart
    createNewCart();
  }

  // Create a new cart
  void createNewCart({String? customerName, String? customerId}) {
    final cartNumber = state.carts.length + 1;
    final newCart = CartSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: customerName ?? 'Cart $cartNumber',
      createdAt: DateTime.now(),
      customerName: customerName,
      customerId: customerId,
    );

    state = state.copyWith(
      carts: [...state.carts, newCart],
      activeCartId: newCart.id,
    );
  }

  // Switch to a different cart
  void switchCart(String cartId) {
    if (state.carts.any((cart) => cart.id == cartId)) {
      state = state.copyWith(activeCartId: cartId);
    }
  }

  // Add product to active cart
  void addToCart(Product product) {
    if (state.activeCart == null) {
      createNewCart();
    }

    final activeCart = state.activeCart!;
    final newCartItems = Map<Product, int>.from(activeCart.cartItems);

    if (newCartItems.containsKey(product)) {
      if (product.isService ||
          (product.stock != null && newCartItems[product]! < product.stock!)) {
        newCartItems[product] = newCartItems[product]! + 1;
      } else {
        debugPrint('Cannot add ${product.name}: stock limit reached');
        return;
      }
    } else {
      newCartItems[product] = 1;
    }

    final updatedCart = activeCart.copyWith(
      cartItems: newCartItems,
      totalAmount: activeCart.totalAmount + product.price,
    );

    _updateCart(updatedCart);
  }

  // Remove product from active cart
  void removeFromCart(Product product) {
    if (state.activeCart == null) return;

    final activeCart = state.activeCart!;
    final newCartItems = Map<Product, int>.from(activeCart.cartItems);

    if (newCartItems.containsKey(product)) {
      final currentQuantity = newCartItems[product]!;
      if (currentQuantity > 1) {
        newCartItems[product] = currentQuantity - 1;
      } else {
        newCartItems.remove(product);
      }

      final updatedCart = activeCart.copyWith(
        cartItems: newCartItems,
        totalAmount: activeCart.totalAmount - product.price,
      );

      _updateCart(updatedCart);
    }
  }

  // Set discount for active cart
  void setDiscount(double discount) {
    if (state.activeCart == null) return;
    final activeCart = state.activeCart!;
    final updatedCart = activeCart.copyWith(
      discount: discount.clamp(0, activeCart.totalAmount),
    );
    _updateCart(updatedCart);
  }

  // Set paid amount for active cart
  void setPaidAmount(double amount) {
    if (state.activeCart == null) return;
    final activeCart = state.activeCart!;
    final updatedCart = activeCart.copyWith(
      paidAmount: amount.clamp(0, activeCart.totalAmount - activeCart.discount),
    );
    _updateCart(updatedCart);
  }

  // Set payment status for active cart
  void setPaymentStatus(bool isPaid) {
    if (state.activeCart == null) return;
    final activeCart = state.activeCart!;
    final updatedCart = activeCart.copyWith(
      isPaid: isPaid,
      paymentMethod:
          isPaid && activeCart.paymentMethod == null
              ? 'Cash'
              : activeCart.paymentMethod,
    );
    _updateCart(updatedCart);
  }

  // Set payment method for active cart
  void setPaymentMethod(String? method) {
    if (state.activeCart == null) return;
    final activeCart = state.activeCart!;
    final updatedCart = activeCart.copyWith(paymentMethod: method);
    _updateCart(updatedCart);
  }

  // Update cart name (useful when assigning to a customer)
  void updateCartName(String cartId, String name, {String? customerId}) {
    final cartIndex = state.carts.indexWhere((cart) => cart.id == cartId);
    if (cartIndex == -1) return;

    final updatedCart = state.carts[cartIndex].copyWith(
      name: name,
      customerName: name,
      customerId: customerId,
    );

    final updatedCarts = List<CartSession>.from(state.carts);
    updatedCarts[cartIndex] = updatedCart;

    state = state.copyWith(carts: updatedCarts);
  }

  // Delete a cart
  void deleteCart(String cartId) {
    final updatedCarts =
        state.carts.where((cart) => cart.id != cartId).toList();

    // If deleting active cart, switch to another or create new one
    String? newActiveCartId = state.activeCartId;
    if (state.activeCartId == cartId) {
      if (updatedCarts.isNotEmpty) {
        newActiveCartId = updatedCarts.first.id;
      } else {
        newActiveCartId = null;
      }
    }

    state = state.copyWith(carts: updatedCarts, activeCartId: newActiveCartId);

    // Create new cart if no carts exist
    if (state.carts.isEmpty) {
      createNewCart();
    }
  }

  // Clear active cart (after successful checkout)
  void clearActiveCart() {
    if (state.activeCart == null) return;
    deleteCart(state.activeCart!.id);
  }

  // Helper method to update a cart in the list
  void _updateCart(CartSession updatedCart) {
    final cartIndex = state.carts.indexWhere(
      (cart) => cart.id == updatedCart.id,
    );
    if (cartIndex == -1) return;

    final updatedCarts = List<CartSession>.from(state.carts);
    updatedCarts[cartIndex] = updatedCart;

    state = state.copyWith(carts: updatedCarts);
  }

  // Get cart by ID
  CartSession? getCart(String cartId) {
    try {
      return state.carts.firstWhere((cart) => cart.id == cartId);
    } catch (e) {
      return null;
    }
  }

  // Hold/Park a cart (rename it with a meaningful identifier)
  void holdCart(String cartId, String identifier) {
    updateCartName(cartId, 'Held: $identifier');
  }

  // Get total number of carts
  int get cartCount => state.carts.length;

  // Get total number of items across all carts
  int get totalItemsAllCarts {
    return state.carts.fold(0, (sum, cart) => sum + cart.itemCount);
  }
}

final multiCartProvider =
    StateNotifierProvider<MultiCartNotifier, MultiCartState>(
      (ref) => MultiCartNotifier(),
    );
