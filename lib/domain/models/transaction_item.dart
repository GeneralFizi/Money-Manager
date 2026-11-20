/// Supported transaction kinds.
enum TransactionType {
  income('Income'),
  expense('Expense'),
  transfer('Transfer');

  const TransactionType(this.label);

  final String label;

  static TransactionType fromName(String? value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionType.expense,
    );
  }
}

/// Represents a financial record stored locally on the device.
class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    required this.date,
    this.note = '',
    this.recurringRuleId,
  });

  final String id;
  final TransactionType type;
  final double amount;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final DateTime date;
  final String note;
  final String? recurringRuleId;

  TransactionItem copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? accountId,
    String? toAccountId,
    bool clearToAccountId = false,
    String? categoryId,
    bool clearCategoryId = false,
    DateTime? date,
    String? note,
    String? recurringRuleId,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      toAccountId: clearToAccountId ? null : (toAccountId ?? this.toAccountId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      date: date ?? this.date,
      note: note ?? this.note,
      recurringRuleId: recurringRuleId ?? this.recurringRuleId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'amount': amount,
      'account_id': accountId,
      'to_account_id': toAccountId,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'note': note,
      'recurring_rule_id': recurringRuleId,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as String,
      type: TransactionType.fromName(map['type'] as String?),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      accountId: (map['account_id'] ?? map['accountId']) as String,
      toAccountId: (map['to_account_id'] ?? map['toAccountId']) as String?,
      categoryId: (map['category_id'] ?? map['categoryId']) as String?,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      note: (map['note'] as String?) ?? '',
      recurringRuleId: (map['recurring_rule_id'] ?? map['recurringRuleId']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'amount': amount,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'note': note,
      'recurringRuleId': recurringRuleId,
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      TransactionItem.fromMap(json);
}
