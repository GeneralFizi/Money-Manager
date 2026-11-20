import 'category.dart';

/// Represents a monthly spending limit for a single expense category.
class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.yearMonth,
    required this.limitAmount,
  });

  final String id;
  final String categoryId;
  /// Format: `YYYY-MM`, e.g. `2026-11`.
  final String yearMonth;
  final double limitAmount;

  static String formatYearMonth(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  Budget copyWith({
    String? id,
    String? categoryId,
    String? yearMonth,
    double? limitAmount,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      yearMonth: yearMonth ?? this.yearMonth,
      limitAmount: limitAmount ?? this.limitAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'category_id': categoryId,
      'year_month': yearMonth,
      'limit_amount': limitAmount,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      categoryId: (map['category_id'] ?? map['categoryId']) as String,
      yearMonth: (map['year_month'] ?? map['yearMonth']) as String,
      limitAmount: ((map['limit_amount'] ?? map['limitAmount']) as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'categoryId': categoryId,
      'yearMonth': yearMonth,
      'limitAmount': limitAmount,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) => Budget.fromMap(json);
}

/// Computed progress view of a monthly category budget.
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.category,
    required this.spentAmount,
  });

  final Budget budget;
  final CategoryItem category;
  final double spentAmount;

  double get remainingAmount => budget.limitAmount - spentAmount;

  double get ratio => budget.limitAmount <= 0 ? 0.0 : spentAmount / budget.limitAmount;

  double get clampedRatio => ratio.clamp(0.0, 1.0);

  bool get isWarning => ratio >= 0.8 && ratio < 1.0;

  bool get isOverBudget => ratio >= 1.0;
}
