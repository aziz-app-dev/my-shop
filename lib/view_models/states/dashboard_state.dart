import '../../models/bills_model.dart';
import '../../models/coustomer_model.dart';
import '../../models/expense_model.dart';
import '../../models/items_model.dart';
import '../../models/shopping_list_model.dart';

/// Helper class for daily sales data
class DailySales {
  final DateTime date;
  final double amount;
  final int transactionCount;

  DailySales({
    required this.date,
    required this.amount,
    required this.transactionCount,
  });
}

/// Helper class for top customer data
class TopCustomer {
  final String id;
  final String name;
  final double totalRevenue;
  final int transactionCount;

  TopCustomer({
    required this.id,
    required this.name,
    required this.totalRevenue,
    required this.transactionCount,
  });
}

/// Helper class for monthly data in yearly view
class MonthlyData {
  final int month;
  final String monthName;
  final double sales;
  final double expenses;
  final double received;
  final double pending;

  MonthlyData({
    required this.month,
    required this.monthName,
    required this.sales,
    required this.expenses,
    required this.received,
    required this.pending,
  });
}

/// Helper class for top selling items
class TopSellingItem {
  final String id;
  final String name;
  final int quantitySold;
  final double totalRevenue;
  final double totalProfit;
  final double? purchasePrice;
  final double sellingPrice;

  TopSellingItem({
    required this.id,
    required this.name,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalProfit,
    this.purchasePrice,
    required this.sellingPrice,
  });

  /// Profit margin percentage
  double get profitMargin {
    if (totalRevenue == 0) return 0;
    return (totalProfit / totalRevenue) * 100;
  }
}

/// Helper class for low stock items
class LowStockItem {
  final String id;
  final String name;
  final int currentStock;
  final int salesVelocity; // items sold per month
  final int? daysUntilStockout;

  LowStockItem({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.salesVelocity,
    this.daysUntilStockout,
  });
}

/// Helper class for profit/loss by category
class CategoryProfit {
  final String category;
  final double revenue;
  final double cost;
  final double profit;

  CategoryProfit({
    required this.category,
    required this.revenue,
    required this.cost,
    required this.profit,
  });

  double get profitMargin => revenue > 0 ? (profit / revenue) * 100 : 0;
}

class DashboardState {
  final bool isLoading;
  final String? error;
  final DateTime selectedMonth;
  final bool isYearlyView;

  // Raw data
  final List<Bill> bills;
  final List<Customer> customers;
  final List<Expense> expenses;
  final List<ShoppingListItem> shoppingItems;
  final List<Product> products;

  const DashboardState({
    this.isLoading = false,
    this.error,
    DateTime? selectedMonth,
    this.isYearlyView = false,
    this.bills = const [],
    this.customers = const [],
    this.expenses = const [],
    this.shoppingItems = const [],
    this.products = const [],
  }) : selectedMonth = selectedMonth ?? const _DefaultDateTime();

  // ============ INVENTORY ANALYTICS ============

  /// Total number of products (non-service items)
  int get totalProducts => products.where((p) => !p.isService).length;

  /// Total number of services
  int get totalServices => products.where((p) => p.isService).length;

  /// Total stock count across all products
  int get totalStock => products.fold(0, (sum, p) => sum + (p.stock ?? 0));

  // ============ SALES ANALYTICS ============

  /// Get bills for selected month
  List<Bill> get selectedMonthBills {
    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final startOfNextMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      1,
    );

    return bills.where((bill) {
      return !bill.dateTime.isBefore(startOfMonth) &&
          bill.dateTime.isBefore(startOfNextMonth);
    }).toList();
  }

  /// Get bills for previous month
  List<Bill> get previousMonthBills {
    final prevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    final startOfMonth = DateTime(prevMonth.year, prevMonth.month, 1);
    final startOfNextMonth = DateTime(prevMonth.year, prevMonth.month + 1, 1);

    return bills.where((bill) {
      return !bill.dateTime.isBefore(startOfMonth) &&
          bill.dateTime.isBefore(startOfNextMonth);
    }).toList();
  }

  /// Total sales for selected month
  double get totalSalesThisMonth {
    return selectedMonthBills.fold(
      0.0,
      (sum, bill) => sum + bill.totalAfterDiscount,
    );
  }

  /// Total sales for previous month
  double get totalSalesLastMonth {
    return previousMonthBills.fold(
      0.0,
      (sum, bill) => sum + bill.totalAfterDiscount,
    );
  }

  /// Sales percentage change from last month
  double get salesPercentageChange {
    if (totalSalesLastMonth == 0) return 0;
    return ((totalSalesThisMonth - totalSalesLastMonth) / totalSalesLastMonth) *
        100;
  }

  /// Total transactions for selected month
  int get totalTransactions => selectedMonthBills.length;

  /// Sales grouped by payment method
  Map<String, double> get salesByPaymentMethod {
    final Map<String, double> result = {};
    for (final bill in selectedMonthBills) {
      final method = bill.paymentMethod ?? 'Cash';
      result[method] = (result[method] ?? 0) + bill.totalAfterDiscount;
    }
    return result;
  }

  /// Daily sales trend for selected month
  List<DailySales> get dailySalesTrend {
    final Map<int, DailySales> dailyMap = {};
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    // Initialize all days with zero
    for (int day = 1; day <= daysInMonth; day++) {
      dailyMap[day] = DailySales(
        date: DateTime(selectedMonth.year, selectedMonth.month, day),
        amount: 0,
        transactionCount: 0,
      );
    }

    // Fill in actual data
    for (final bill in selectedMonthBills) {
      final day = bill.dateTime.day;
      final existing = dailyMap[day];
      if (existing == null) continue;
      dailyMap[day] = DailySales(
        date: existing.date,
        amount: existing.amount + bill.totalAfterDiscount,
        transactionCount: existing.transactionCount + 1,
      );
    }

    return dailyMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  // ============ CUSTOMER ANALYTICS ============

  /// Total customers count
  int get totalCustomers => customers.length;

  /// Total pending receivables from all customers
  double get totalPendingReceivables {
    return customers.fold(
      0.0,
      (sum, customer) => sum + customer.totalPendingAmount,
    );
  }

  /// Total paid amount from all customers
  double get totalPaidAmount {
    return customers.fold(
      0.0,
      (sum, customer) => sum + customer.totalPaidAmount,
    );
  }

  /// Top customers by revenue
  List<TopCustomer> get topCustomersByRevenue {
    final Map<String, TopCustomer> customerMap = {};

    for (final bill in selectedMonthBills) {
      if (bill.customerId != null && bill.customerId!.isNotEmpty) {
        final existing = customerMap[bill.customerId!];
        if (existing != null) {
          customerMap[bill.customerId!] = TopCustomer(
            id: bill.customerId!,
            name: bill.customerName ?? 'Unknown',
            totalRevenue: existing.totalRevenue + bill.totalAfterDiscount,
            transactionCount: existing.transactionCount + 1,
          );
        } else {
          customerMap[bill.customerId!] = TopCustomer(
            id: bill.customerId!,
            name: bill.customerName ?? 'Unknown',
            totalRevenue: bill.totalAfterDiscount,
            transactionCount: 1,
          );
        }
      }
    }

    final sorted =
        customerMap.values.toList()
          ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    return sorted.take(10).toList();
  }

  // ============ PAYMENT ANALYTICS (RECEIVED VS PENDING) ============

  /// Total amount received (paid) for selected month bills
  double get totalReceivedThisMonth {
    return selectedMonthBills.fold(0.0, (sum, bill) => sum + bill.paidAmount);
  }

  /// Total amount pending for selected month bills
  double get totalPendingThisMonth {
    return selectedMonthBills.fold(
      0.0,
      (sum, bill) => sum + bill.pendingAmount,
    );
  }

  /// Total amount received for selected year
  double get totalReceivedThisYear {
    return selectedYearBills.fold(0.0, (sum, bill) => sum + bill.paidAmount);
  }

  /// Total amount pending for selected year
  double get totalPendingThisYear {
    return selectedYearBills.fold(0.0, (sum, bill) => sum + bill.pendingAmount);
  }

  // ============ YEARLY ANALYTICS ============

  /// Get bills for selected year
  List<Bill> get selectedYearBills {
    final startOfYear = DateTime(selectedMonth.year, 1, 1);
    final startOfNextYear = DateTime(selectedMonth.year + 1, 1, 1);

    return bills.where((bill) {
      return !bill.dateTime.isBefore(startOfYear) &&
          bill.dateTime.isBefore(startOfNextYear);
    }).toList();
  }

  /// Get expenses for selected year
  List<Expense> get selectedYearExpenses {
    final startOfYear = DateTime(selectedMonth.year, 1, 1);
    final startOfNextYear = DateTime(selectedMonth.year + 1, 1, 1);

    return expenses.where((expense) {
      return !expense.date.isBefore(startOfYear) &&
          expense.date.isBefore(startOfNextYear);
    }).toList();
  }

  /// Total sales for selected year
  double get totalSalesThisYear {
    return selectedYearBills.fold(
      0.0,
      (sum, bill) => sum + bill.totalAfterDiscount,
    );
  }

  /// Total expenses for selected year
  double get totalExpensesThisYear {
    return selectedYearExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  /// Net profit for selected year
  double get netProfitThisYear => totalSalesThisYear - totalExpensesThisYear;

  /// Monthly breakdown for yearly view
  List<MonthlyData> get monthlyBreakdown {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return List.generate(12, (index) {
      final month = index + 1;
      final startOfMonth = DateTime(selectedMonth.year, month, 1);
      final startOfNextMonth = DateTime(selectedMonth.year, month + 1, 1);

      final monthBills =
          bills.where((bill) {
            return !bill.dateTime.isBefore(startOfMonth) &&
                bill.dateTime.isBefore(startOfNextMonth);
          }).toList();

      final monthExpenses =
          expenses.where((expense) {
            return !expense.date.isBefore(startOfMonth) &&
                expense.date.isBefore(startOfNextMonth);
          }).toList();

      return MonthlyData(
        month: month,
        monthName: months[index],
        sales: monthBills.fold(
          0.0,
          (sum, bill) => sum + bill.totalAfterDiscount,
        ),
        expenses: monthExpenses.fold(
          0.0,
          (sum, expense) => sum + expense.amount,
        ),
        received: monthBills.fold(0.0, (sum, bill) => sum + bill.paidAmount),
        pending: monthBills.fold(0.0, (sum, bill) => sum + bill.pendingAmount),
      );
    });
  }

  // ============ EXPENSE ANALYTICS ============

  /// Get expenses for selected month
  List<Expense> get selectedMonthExpenses {
    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final startOfNextMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      1,
    );

    return expenses.where((expense) {
      return !expense.date.isBefore(startOfMonth) &&
          expense.date.isBefore(startOfNextMonth);
    }).toList();
  }

  /// Get expenses for previous month
  List<Expense> get previousMonthExpenses {
    final prevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    final startOfMonth = DateTime(prevMonth.year, prevMonth.month, 1);
    final startOfNextMonth = DateTime(prevMonth.year, prevMonth.month + 1, 1);

    return expenses.where((expense) {
      return !expense.date.isBefore(startOfMonth) &&
          expense.date.isBefore(startOfNextMonth);
    }).toList();
  }

  /// Total expenses for selected month
  double get totalExpensesThisMonth {
    return selectedMonthExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  /// Total expenses for previous month
  double get totalExpensesLastMonth {
    return previousMonthExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  /// Expense percentage change from last month
  double get expensePercentageChange {
    if (totalExpensesLastMonth == 0) return 0;
    return ((totalExpensesThisMonth - totalExpensesLastMonth) /
            totalExpensesLastMonth) *
        100;
  }

  /// Expenses grouped by category
  Map<String, double> get expensesByCategory {
    final Map<String, double> result = {};
    for (final expense in selectedMonthExpenses) {
      final categoryName = expense.categoryName ?? 'Other';
      result[categoryName] = (result[categoryName] ?? 0) + expense.amount;
    }
    return result;
  }

  /// Daily expenses for comparison chart
  List<DailySales> get dailyExpensesTrend {
    final Map<int, double> dailyMap = {};
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    // Initialize all days with zero
    for (int day = 1; day <= daysInMonth; day++) {
      dailyMap[day] = 0;
    }

    // Fill in actual data
    for (final expense in selectedMonthExpenses) {
      final day = expense.date.day;
      dailyMap[day] = (dailyMap[day] ?? 0) + expense.amount;
    }

    return dailyMap.entries
        .map(
          (entry) => DailySales(
            date: DateTime(selectedMonth.year, selectedMonth.month, entry.key),
            amount: entry.value,
            transactionCount: 0,
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ============ SHOPPING/PURCHASE ANALYTICS ============

  /// Get shopped items for selected month (purchases made)
  List<ShoppingListItem> get selectedMonthShoppedItems {
    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final startOfNextMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      1,
    );

    return shoppingItems.where((item) {
      return item.isShopped &&
          !item.updatedAt.isBefore(startOfMonth) &&
          item.updatedAt.isBefore(startOfNextMonth);
    }).toList();
  }

  /// Total shopping/purchase cost for selected month
  double get totalShoppingThisMonth {
    return selectedMonthShoppedItems.fold(0.0, (sum, item) {
      final price = item.price ?? 0;
      return sum + (price * item.quantityNeeded);
    });
  }

  /// Total outflow (expenses + shopping)
  double get totalOutflowThisMonth =>
      totalExpensesThisMonth + totalShoppingThisMonth;

  // ============ PROFIT ANALYTICS ============

  /// Net profit (Sales - Expenses - Shopping)
  double get netProfit => totalSalesThisMonth - totalOutflowThisMonth;

  /// Net profit for previous month
  double get netProfitLastMonth => totalSalesLastMonth - totalExpensesLastMonth;

  /// Profit percentage change
  double get profitPercentageChange {
    if (netProfitLastMonth == 0) return 0;
    return ((netProfit - netProfitLastMonth) / netProfitLastMonth.abs()) * 100;
  }

  /// Daily outflow (expenses + shopping) for comparison chart
  List<DailySales> get dailyOutflowTrend {
    final Map<int, double> dailyMap = {};
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    // Initialize all days with zero
    for (int day = 1; day <= daysInMonth; day++) {
      dailyMap[day] = 0;
    }

    // Add expenses
    for (final expense in selectedMonthExpenses) {
      final day = expense.date.day;
      dailyMap[day] = (dailyMap[day] ?? 0) + expense.amount;
    }

    // Add shopping purchases
    for (final item in selectedMonthShoppedItems) {
      final day = item.updatedAt.day;
      final cost = (item.price ?? 0) * item.quantityNeeded;
      dailyMap[day] = (dailyMap[day] ?? 0) + cost;
    }

    return dailyMap.entries
        .map(
          (entry) => DailySales(
            date: DateTime(selectedMonth.year, selectedMonth.month, entry.key),
            amount: entry.value,
            transactionCount: 0,
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ============ ITEM/PRODUCT ANALYTICS ============

  /// Top selling items for selected period (month or year)
  List<TopSellingItem> get topSellingItems {
    final billsToAnalyze =
        isYearlyView ? selectedYearBills : selectedMonthBills;
    final Map<String, TopSellingItem> itemMap = {};

    for (final bill in billsToAnalyze) {
      for (final item in bill.items) {
        final quantity = bill.quantities[item.id] ?? 1;
        final revenue = item.price * quantity;
        final cost = (item.purchasePrice ?? 0) * quantity;
        final profit = revenue - cost;

        if (itemMap.containsKey(item.id)) {
          final existing = itemMap[item.id]!;
          itemMap[item.id] = TopSellingItem(
            id: item.id,
            name: item.name,
            quantitySold: existing.quantitySold + quantity,
            totalRevenue: existing.totalRevenue + revenue,
            totalProfit: existing.totalProfit + profit,
            purchasePrice: item.purchasePrice,
            sellingPrice: item.price,
          );
        } else {
          itemMap[item.id] = TopSellingItem(
            id: item.id,
            name: item.name,
            quantitySold: quantity,
            totalRevenue: revenue,
            totalProfit: profit,
            purchasePrice: item.purchasePrice,
            sellingPrice: item.price,
          );
        }
      }
    }

    final sorted =
        itemMap.values.toList()
          ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

    return sorted.take(10).toList();
  }

  /// Items with highest profit
  List<TopSellingItem> get mostProfitableItems {
    final billsToAnalyze =
        isYearlyView ? selectedYearBills : selectedMonthBills;
    final Map<String, TopSellingItem> itemMap = {};

    for (final bill in billsToAnalyze) {
      for (final item in bill.items) {
        final quantity = bill.quantities[item.id] ?? 1;
        final revenue = item.price * quantity;
        final cost = (item.purchasePrice ?? 0) * quantity;
        final profit = revenue - cost;

        if (itemMap.containsKey(item.id)) {
          final existing = itemMap[item.id]!;
          itemMap[item.id] = TopSellingItem(
            id: item.id,
            name: item.name,
            quantitySold: existing.quantitySold + quantity,
            totalRevenue: existing.totalRevenue + revenue,
            totalProfit: existing.totalProfit + profit,
            purchasePrice: item.purchasePrice,
            sellingPrice: item.price,
          );
        } else {
          itemMap[item.id] = TopSellingItem(
            id: item.id,
            name: item.name,
            quantitySold: quantity,
            totalRevenue: revenue,
            totalProfit: profit,
            purchasePrice: item.purchasePrice,
            sellingPrice: item.price,
          );
        }
      }
    }

    final sorted =
        itemMap.values.toList()
          ..sort((a, b) => b.totalProfit.compareTo(a.totalProfit));

    return sorted.take(10).toList();
  }

  /// Items with loss (negative profit)
  List<TopSellingItem> get lossItems {
    return mostProfitableItems.where((item) => item.totalProfit < 0).toList();
  }

  /// Low stock items (stock <= 5)
  List<LowStockItem> get lowStockItems {
    final soldQuantities = <String, int>{};

    // Calculate sales velocity from last month
    for (final bill in selectedMonthBills) {
      for (final item in bill.items) {
        final quantity = bill.quantities[item.id] ?? 1;
        soldQuantities[item.id] = (soldQuantities[item.id] ?? 0) + quantity;
      }
    }

    return products.where((p) => !p.isService && (p.stock ?? 0) <= 5).map((p) {
        final velocity = soldQuantities[p.id] ?? 0;
        final currentStock = p.stock ?? 0;
        int? daysUntilStockout;
        if (velocity > 0) {
          daysUntilStockout = (currentStock / (velocity / 30)).round();
        }
        return LowStockItem(
          id: p.id,
          name: p.name,
          currentStock: currentStock,
          salesVelocity: velocity,
          daysUntilStockout: daysUntilStockout,
        );
      }).toList()
      ..sort((a, b) => a.currentStock.compareTo(b.currentStock));
  }

  /// Profit/loss by category
  List<CategoryProfit> get profitByCategory {
    final billsToAnalyze =
        isYearlyView ? selectedYearBills : selectedMonthBills;
    final Map<String, CategoryProfit> categoryMap = {};

    for (final bill in billsToAnalyze) {
      for (final item in bill.items) {
        final category = item.category ?? 'Uncategorized';
        final quantity = bill.quantities[item.id] ?? 1;
        final revenue = item.price * quantity;
        final cost = (item.purchasePrice ?? 0) * quantity;
        final profit = revenue - cost;

        if (categoryMap.containsKey(category)) {
          final existing = categoryMap[category]!;
          categoryMap[category] = CategoryProfit(
            category: category,
            revenue: existing.revenue + revenue,
            cost: existing.cost + cost,
            profit: existing.profit + profit,
          );
        } else {
          categoryMap[category] = CategoryProfit(
            category: category,
            revenue: revenue,
            cost: cost,
            profit: profit,
          );
        }
      }
    }

    final sorted =
        categoryMap.values.toList()
          ..sort((a, b) => b.profit.compareTo(a.profit));

    return sorted;
  }

  /// Total gross profit from item sales
  double get grossProfit {
    final billsToAnalyze =
        isYearlyView ? selectedYearBills : selectedMonthBills;
    double totalProfit = 0;

    for (final bill in billsToAnalyze) {
      for (final item in bill.items) {
        final quantity = bill.quantities[item.id] ?? 1;
        final revenue = item.price * quantity;
        final cost = (item.purchasePrice ?? 0) * quantity;
        totalProfit += revenue - cost;
      }
    }

    return totalProfit;
  }

  /// Gross profit margin percentage
  double get grossProfitMargin {
    final sales = isYearlyView ? totalSalesThisYear : totalSalesThisMonth;
    if (sales == 0) return 0;
    return (grossProfit / sales) * 100;
  }

  /// Gross profit for previous month (for percentage change calculation)
  double get grossProfitLastMonth {
    double totalProfit = 0;
    for (final bill in previousMonthBills) {
      for (final item in bill.items) {
        final quantity = bill.quantities[item.id] ?? 1;
        final revenue = item.price * quantity;
        final cost = (item.purchasePrice ?? 0) * quantity;
        totalProfit += revenue - cost;
      }
    }
    return totalProfit;
  }

  /// Gross profit percentage change from last month
  double get grossProfitPercentageChange {
    if (grossProfitLastMonth == 0) return 0;
    return ((grossProfit - grossProfitLastMonth) / grossProfitLastMonth.abs()) *
        100;
  }

  // ============ COPY WITH ============

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    DateTime? selectedMonth,
    bool? isYearlyView,
    List<Bill>? bills,
    List<Customer>? customers,
    List<Expense>? expenses,
    List<ShoppingListItem>? shoppingItems,
    List<Product>? products,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      isYearlyView: isYearlyView ?? this.isYearlyView,
      bills: bills ?? this.bills,
      customers: customers ?? this.customers,
      expenses: expenses ?? this.expenses,
      shoppingItems: shoppingItems ?? this.shoppingItems,
      products: products ?? this.products,
    );
  }
}

/// Helper class to provide default DateTime value in const constructor
class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  static DateTime get _now => DateTime.now();

  @override
  int get year => _now.year;
  @override
  int get month => _now.month;
  @override
  int get day => _now.day;
  @override
  int get hour => _now.hour;
  @override
  int get minute => _now.minute;
  @override
  int get second => _now.second;
  @override
  int get millisecond => _now.millisecond;
  @override
  int get microsecond => _now.microsecond;
  @override
  int get weekday => _now.weekday;

  @override
  bool get isUtc => _now.isUtc;

  @override
  DateTime add(Duration duration) => _now.add(duration);

  @override
  DateTime subtract(Duration duration) => _now.subtract(duration);

  @override
  int compareTo(DateTime other) => _now.compareTo(other);

  @override
  Duration difference(DateTime other) => _now.difference(other);

  @override
  bool isAfter(DateTime other) => _now.isAfter(other);

  @override
  bool isAtSameMomentAs(DateTime other) => _now.isAtSameMomentAs(other);

  @override
  bool isBefore(DateTime other) => _now.isBefore(other);

  @override
  int get millisecondsSinceEpoch => _now.millisecondsSinceEpoch;

  @override
  int get microsecondsSinceEpoch => _now.microsecondsSinceEpoch;

  @override
  String get timeZoneName => _now.timeZoneName;

  @override
  Duration get timeZoneOffset => _now.timeZoneOffset;

  @override
  String toIso8601String() => _now.toIso8601String();

  @override
  DateTime toLocal() => _now.toLocal();

  @override
  DateTime toUtc() => _now.toUtc();

  @override
  String toString() => _now.toString();
}
