import 'package:uuid/uuid.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final String? icon; // Icon name or path
  final bool isDefault; // Predefined categories can't be deleted

  ExpenseCategory({
    String? id,
    required this.name,
    this.icon,
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'isDefault': isDefault,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  ExpenseCategory copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isDefault,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  // Predefined default categories
  static List<ExpenseCategory> get defaultCategories => [
    ExpenseCategory(id: 'rent', name: 'Rent', icon: 'home', isDefault: true),
    ExpenseCategory(id: 'utilities', name: 'Utilities', icon: 'bolt', isDefault: true),
    ExpenseCategory(id: 'salaries', name: 'Salaries', icon: 'people', isDefault: true),
    ExpenseCategory(id: 'supplies', name: 'Supplies', icon: 'inventory', isDefault: true),
    ExpenseCategory(id: 'marketing', name: 'Marketing', icon: 'campaign', isDefault: true),
    ExpenseCategory(id: 'transport', name: 'Transport', icon: 'directions_car', isDefault: true),
    ExpenseCategory(id: 'maintenance', name: 'Maintenance', icon: 'build', isDefault: true),
    ExpenseCategory(id: 'taxes', name: 'Taxes', icon: 'receipt', isDefault: true),
    ExpenseCategory(id: 'other', name: 'Other', icon: 'more_horiz', isDefault: true),
  ];
}

class Expense {
  final String id;
  final double amount;
  final String categoryId;
  final String? categoryName; // For display purposes
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Expense({
    String? id,
    required this.amount,
    required this.categoryId,
    this.categoryName,
    required this.date,
    this.note,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'date': date.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as String,
      categoryName: map['categoryName'] as String?,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Expense copyWith({
    String? id,
    double? amount,
    String? categoryId,
    String? categoryName,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
