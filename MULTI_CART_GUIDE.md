# Multi-Cart Sales System Guide

## Overview
The multi-cart system allows shop personnel to manage multiple customer transactions simultaneously. This is ideal for retail environments where multiple customers may be shopping at the same time.

## Features

### 1. Product Search
- Real-time search bar at the top of the products section
- Search by product name or description
- Clear button (X) to quickly reset search
- Shows "No products found" message when search yields no results
- Search is case-insensitive

### 2. Multiple Active Carts
- Create and manage multiple shopping carts simultaneously
- Each cart maintains its own:
  - Product items and quantities
  - Total amount
  - Discount
  - Payment information
  - Customer details (optional)

### 2. Cart Tabs Interface
- Visual tabs at the top of the sales screen
- Each tab shows:
  - Cart name (e.g., "Cart 1", "Cart 2", or customer name)
  - Item count badge
  - Cart options menu (three-dot icon)

### 3. Cart Operations

#### Creating a New Cart
- Click the **"+"** button in the tab bar
- A new cart is automatically created and activated
- Default name: "Cart 1", "Cart 2", etc.

#### Switching Between Carts
- Click on any cart tab to switch to that cart
- The product grid remains the same, but items are added to the active cart
- The cart panel shows items only for the active cart

#### Renaming a Cart
1. Click the three-dot menu icon on a cart tab
2. Select "Rename Cart"
3. Enter a meaningful name (e.g., customer name)
4. Click "Save"

#### Deleting a Cart
1. Click the three-dot menu icon on a cart tab
2. Select "Delete Cart"
3. The cart is removed
4. If it was the active cart, automatically switches to another cart

### 4. Completing a Sale

#### From Cart Tab Menu
1. Click the three-dot menu icon on the desired cart tab
2. Select "Complete Sale"
3. Follow the checkout process

#### From Cart Panel
1. Ensure the correct cart is active
2. Click the "Complete Sale" button in the cart panel
3. Enter customer and payment details
4. Complete the transaction

### 5. Workflow Example

**Scenario: Multiple customers in the shop**

1. **Customer A arrives**
   - Cart 1 is active by default
   - Add Customer A's items
   - Optionally rename cart to "Customer A"

2. **Customer B arrives while Customer A is still shopping**
   - Click "+" to create Cart 2
   - Cart 2 becomes active
   - Add Customer B's items
   - Optionally rename cart to "Customer B"

3. **Customer A is ready to checkout**
   - Click on "Customer A" tab to switch to that cart
   - Click "Complete Sale"
   - Process Customer A's payment
   - Cart is automatically removed after successful sale

4. **Customer C arrives**
   - Click "+" to create a new cart (Cart 3)
   - Add Customer C's items

5. **Customer B is ready to checkout**
   - Switch to "Customer B" tab
   - Complete the sale

## File Structure

### New Files Created

```
lib/
├── view_models/
│   ├── states/
│   │   └── multi_cart_state.dart          # Cart session and state models
│   └── providers/
│       └── multi_cart_provider.dart       # Multi-cart business logic
├── view/
│   └── sales/
│       ├── multi_cart_sale_view.dart      # Main multi-cart sales screen
│       └── widgets/
│           ├── multi_cart_section_widget.dart      # Cart display widget
│           ├── multi_cart_item_widget.dart         # Cart item card
│           └── multi_cart_product_section.dart     # Product grid for multi-cart
```

## How to Use in Your App

### Toggle Multi-Cart Mode in Settings

The multi-cart feature is now integrated with a settings toggle:

1. **Navigate to Settings** → **General Settings**
2. **Enable "Enable Multi-Cart Mode"** toggle
3. The sales screen will automatically switch between:
   - **Multi-Cart Mode**: Manage multiple customer carts simultaneously
   - **Single Cart Mode**: Traditional single cart experience

Both modes now include **product search functionality**!

### How It Works

The app uses a `SalesScreenSelector` widget in `screens.dart` that automatically switches between:
- `MultiCartSalesScreen` when multi-cart is enabled
- `SalesScreen` when multi-cart is disabled

```dart
// In screens.dart
class SalesScreenSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMultiCart = ref.watch(settingsProvider.select((s) => s.useMultiCart));

    return useMultiCart
        ? const MultiCartSalesScreen()
        : const SalesScreen();
  }
}
```

The setting is persisted in Hive storage, so your preference is saved across app restarts.

## Key Components

### CartSession Model
Represents a single shopping cart with:
- Unique ID
- Cart name
- Items and quantities
- Total, discount, paid amount
- Payment status and method
- Customer information

### MultiCartState
Manages:
- List of all active carts
- Currently active cart ID
- Helper methods to get active cart

### MultiCartNotifier
Provides operations:
- `createNewCart()` - Create a new cart
- `switchCart(cartId)` - Switch to a different cart
- `addToCart(product)` - Add product to active cart
- `removeFromCart(product)` - Remove product from active cart
- `updateCartName(cartId, name)` - Rename a cart
- `deleteCart(cartId)` - Delete a cart
- `clearActiveCart()` - Remove cart after sale completion
- `setDiscount(amount)` - Set discount for active cart
- `setPaidAmount(amount)` - Set paid amount
- `setPaymentStatus(isPaid)` - Set payment status
- `setPaymentMethod(method)` - Set payment method

## Benefits

1. **Improved Customer Experience**
   - Faster service during busy periods
   - No need to complete one sale before starting another
   - Customers can continue shopping while others checkout

2. **Increased Efficiency**
   - Handle multiple customers simultaneously
   - Reduce wait times
   - Better staff utilization

3. **Flexibility**
   - Hold/park carts for customers who need more time
   - Easy cart identification with custom names
   - Visual feedback with item count badges

4. **Data Integrity**
   - Each cart maintains separate state
   - No mixing of customer orders
   - Clear audit trail for each transaction

## Technical Notes

- The multi-cart system uses Riverpod for state management
- Cart data is kept in memory and is not persisted
- After successful checkout, the cart is automatically removed
- The system ensures at least one cart exists at all times
- Tab controller automatically updates when carts are added/removed

## Migration from Single Cart

The multi-cart system is designed to work alongside the existing checkout flow:
- Uses the same `CustomerPaymentScreen` for checkout
- Compatible with existing billing and customer models
- Maintains the same thermal printing and PDF generation features
- Works with existing database services

## Future Enhancements

Possible improvements:
- Persist carts to database for recovery after app restart
- Add timer badges showing how long each cart has been active
- Quick customer search when creating a cart
- Bulk cart operations (clear all, complete all paid)
- Cart history and analytics
