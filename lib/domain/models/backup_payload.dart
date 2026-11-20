import 'dart:convert';

import 'account.dart';
import 'budget.dart';
import 'category.dart';
import 'recurring_transaction.dart';
import 'transaction_item.dart';

/// Versioned, human-readable JSON snapshot used for local export and on-demand Google Drive backup.
class BackupPayload {
  const BackupPayload({
    this.schemaVersion = 1,
    required this.exportedAt,
    required this.currencyCode,
    required this.currencySymbol,
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.budgets,
    required this.recurringTransactions,
  });

  final int schemaVersion;
  final DateTime exportedAt;
  final String currencyCode;
  final String currencySymbol;
  final List<Account> accounts;
  final List<CategoryItem> categories;
  final List<TransactionItem> transactions;
  final List<Budget> budgets;
  final List<RecurringTransaction> recurringTransactions;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'app': 'MoneyManagerOffline',
      'exportedAt': exportedAt.toIso8601String(),
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'accounts': accounts.map((a) => a.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'budgets': budgets.map((b) => b.toJson()).toList(),
      'recurringTransactions':
          recurringTransactions.map((r) => r.toJson()).toList(),
    };
  }

  String toPrettyJsonString() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }

  factory BackupPayload.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('accounts') || !json.containsKey('transactions')) {
      throw const FormatException(
        'Invalid backup file: missing accounts or transactions.',
      );
    }
    return BackupPayload(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      currencyCode: (json['currencyCode'] as String?) ?? 'USD',
      currencySymbol: (json['currencySymbol'] as String?) ?? '\$',
      accounts: (json['accounts'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => Account.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => CategoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      transactions:
          (json['transactions'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) =>
                  TransactionItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList(),
      budgets: (json['budgets'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => Budget.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      recurringTransactions:
          (json['recurringTransactions'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => RecurringTransaction.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList(),
    );
  }

  factory BackupPayload.fromJsonString(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup file must be a JSON object.');
    }
    return BackupPayload.fromJson(decoded);
  }
}
