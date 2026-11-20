import 'transaction_item.dart';

/// Supported recurrence frequencies for scheduled bills and recurring entries.
enum RecurrenceFrequency {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  const RecurrenceFrequency(this.label);

  final String label;

  static RecurrenceFrequency fromName(String? value) {
    return RecurrenceFrequency.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RecurrenceFrequency.monthly,
    );
  }
}

/// Represents a recurring transaction or scheduled bill evaluated locally.
class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.accountId,
    required this.categoryId,
    required this.frequency,
    required this.nextDueDate,
    this.autoLog = true,
    this.isActive = true,
    this.note = '',
  });

  final String id;
  final String title;
  final TransactionType type;
  final double amount;
  final String accountId;
  final String categoryId;
  final RecurrenceFrequency frequency;
  final DateTime nextDueDate;
  final bool autoLog;
  final bool isActive;
  final String note;

  /// Returns the next scheduled date after [from] while clamping end-of-month days safely.
  DateTime advanceDueDate(DateTime from) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return DateTime(from.year, from.month, from.day + 1, from.hour, from.minute);
      case RecurrenceFrequency.weekly:
        return DateTime(from.year, from.month, from.day + 7, from.hour, from.minute);
      case RecurrenceFrequency.monthly:
        final nextMonth = from.month == 12 ? 1 : from.month + 1;
        final nextYear = from.month == 12 ? from.year + 1 : from.year;
        final maxDay = DateTime(nextYear, nextMonth + 1, 0).day;
        final safeDay = from.day > maxDay ? maxDay : from.day;
        return DateTime(nextYear, nextMonth, safeDay, from.hour, from.minute);
      case RecurrenceFrequency.yearly:
        final nextYear = from.year + 1;
        final maxDay = DateTime(nextYear, from.month + 1, 0).day;
        final safeDay = from.day > maxDay ? maxDay : from.day;
        return DateTime(nextYear, from.month, safeDay, from.hour, from.minute);
    }
  }

  RecurringTransaction copyWith({
    String? id,
    String? title,
    TransactionType? type,
    double? amount,
    String? accountId,
    String? categoryId,
    RecurrenceFrequency? frequency,
    DateTime? nextDueDate,
    bool? autoLog,
    bool? isActive,
    String? note,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      autoLog: autoLog ?? this.autoLog,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'type': type.name,
      'amount': amount,
      'account_id': accountId,
      'category_id': categoryId,
      'frequency': frequency.name,
      'next_due_date': nextDueDate.toIso8601String(),
      'auto_log': autoLog ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'note': note,
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    final rawAutoLog = map['auto_log'] ?? map['autoLog'];
    final rawIsActive = map['is_active'] ?? map['isActive'];
    return RecurringTransaction(
      id: map['id'] as String,
      title: map['title'] as String,
      type: TransactionType.fromName(map['type'] as String?),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      accountId: (map['account_id'] ?? map['accountId']) as String,
      categoryId: (map['category_id'] ?? map['categoryId']) as String,
      frequency: RecurrenceFrequency.fromName(map['frequency'] as String?),
      nextDueDate: DateTime.tryParse(
            (map['next_due_date'] ?? map['nextDueDate']) as String? ?? '',
          ) ??
          DateTime.now(),
      autoLog: rawAutoLog is bool ? rawAutoLog : (rawAutoLog as num? ?? 1) == 1,
      isActive: rawIsActive is bool ? rawIsActive : (rawIsActive as num? ?? 1) == 1,
      note: (map['note'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'type': type.name,
      'amount': amount,
      'accountId': accountId,
      'categoryId': categoryId,
      'frequency': frequency.name,
      'nextDueDate': nextDueDate.toIso8601String(),
      'autoLog': autoLog,
      'isActive': isActive,
      'note': note,
    };
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) =>
      RecurringTransaction.fromMap(json);
}
