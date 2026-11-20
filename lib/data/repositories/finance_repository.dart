import 'package:uuid/uuid.dart';

import '../../domain/models/account.dart';
import '../../domain/models/backup_payload.dart';
import '../../domain/models/budget.dart';
import '../../domain/models/category.dart';
import '../../domain/models/recurring_transaction.dart';
import '../../domain/models/transaction_item.dart';
import '../services/database_service.dart';

/// Repository acting as the single source of truth for all local financial state.
class FinanceRepository {
  FinanceRepository({required DatabaseService databaseService})
      : _db = databaseService;

  final DatabaseService _db;
  static const Uuid _uuid = Uuid();

  Future<void> init() => _db.init();

  Future<List<Account>> getAccounts() => _db.getAccounts();

  Future<void> saveAccount(Account account) => _db.upsertAccount(account);

  Future<void> deleteAccount(String id) => _db.deleteAccount(id);

  Future<List<CategoryItem>> getCategories() => _db.getCategories();

  Future<void> saveCategory(CategoryItem category) =>
      _db.upsertCategory(category);

  Future<void> deleteCategory(String id) => _db.deleteCategory(id);

  Future<List<TransactionItem>> getTransactions() => _db.getTransactions();

  Future<void> saveTransaction(TransactionItem transaction) =>
      _db.upsertTransaction(transaction);

  Future<void> deleteTransaction(String id) => _db.deleteTransaction(id);

  Future<List<Budget>> getBudgets() => _db.getBudgets();

  Future<void> saveBudget(Budget budget) => _db.upsertBudget(budget);

  Future<void> deleteBudget(String id) => _db.deleteBudget(id);

  Future<List<RecurringTransaction>> getRecurringTransactions() =>
      _db.getRecurringTransactions();

  Future<void> saveRecurringTransaction(RecurringTransaction rule) =>
      _db.upsertRecurringTransaction(rule);

  Future<void> deleteRecurringTransaction(String id) =>
      _db.deleteRecurringTransaction(id);

  Future<BackupPayload> exportBackup({
    required String currencyCode,
    required String currencySymbol,
  }) =>
      _db.exportAllData(
        currencyCode: currencyCode,
        currencySymbol: currencySymbol,
      );

  Future<void> restoreBackup(BackupPayload payload) =>
      _db.restoreAllData(payload);

  /// Computes current balance and totals for each account locally.
  List<AccountSummary> computeAccountSummaries({
    required List<Account> accounts,
    required List<TransactionItem> transactions,
  }) {
    return accounts.map((account) {
      double balance = account.initialBalance;
      double totalIncome = 0;
      double totalExpense = 0;

      for (final tx in transactions) {
        switch (tx.type) {
          case TransactionType.income:
            if (tx.accountId == account.id) {
              balance += tx.amount;
              totalIncome += tx.amount;
            }
          case TransactionType.expense:
            if (tx.accountId == account.id) {
              balance -= tx.amount;
              totalExpense += tx.amount;
            }
          case TransactionType.transfer:
            if (tx.accountId == account.id) {
              balance -= tx.amount;
            }
            if (tx.toAccountId == account.id) {
              balance += tx.amount;
            }
        }
      }

      return AccountSummary(
        account: account,
        currentBalance: balance,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
      );
    }).toList();
  }

  /// Computes monthly budget progress entries for [yearMonth] (`YYYY-MM`).
  List<BudgetProgress> computeMonthlyBudgets({
    required String yearMonth,
    required List<Budget> budgets,
    required List<CategoryItem> categories,
    required List<TransactionItem> transactions,
  }) {
    final categoryMap = <String, CategoryItem>{
      for (final c in categories) c.id: c,
    };

    final spentByCategory = <String, double>{};
    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;
      if (Budget.formatYearMonth(tx.date) != yearMonth) continue;
      final catId = tx.categoryId;
      if (catId == null) continue;
      spentByCategory[catId] = (spentByCategory[catId] ?? 0) + tx.amount;
    }

    final items = <BudgetProgress>[];
    for (final budget in budgets.where((b) => b.yearMonth == yearMonth)) {
      final category = categoryMap[budget.categoryId];
      if (category == null) continue;
      items.add(
        BudgetProgress(
          budget: budget,
          category: category,
          spentAmount: spentByCategory[budget.categoryId] ?? 0.0,
        ),
      );
    }

    items.sort((a, b) => b.ratio.compareTo(a.ratio));
    return items;
  }

  /// Evaluates all active recurring rules whose `nextDueDate <= now` and
  /// automatically creates local transactions when `autoLog == true`.
  ///
  /// Returns the count of newly generated transactions.
  Future<int> processDueRecurringTransactions({DateTime? now}) async {
    final referenceNow = now ?? DateTime.now();
    final endOfToday = DateTime(
      referenceNow.year,
      referenceNow.month,
      referenceNow.day,
      23,
      59,
      59,
    );

    final rules = await _db.getRecurringTransactions();
    int generatedCount = 0;

    for (final rule in rules) {
      if (!rule.isActive || !rule.autoLog) continue;
      var due = rule.nextDueDate;
      var updatedRule = rule;
      int guard = 0;

      // Catch up missed occurrences up to today (capped for safety against corrupt dates).
      while (!due.isAfter(endOfToday) && guard < 36) {
        final tx = TransactionItem(
          id: _uuid.v4(),
          type: rule.type == TransactionType.transfer
              ? TransactionType.expense
              : rule.type,
          amount: rule.amount,
          accountId: rule.accountId,
          categoryId: rule.categoryId,
          date: due,
          note: rule.note.isNotEmpty
              ? '${rule.title} • ${rule.note}'
              : rule.title,
          recurringRuleId: rule.id,
        );
        await _db.upsertTransaction(tx);
        generatedCount++;
        due = updatedRule.advanceDueDate(due);
        updatedRule = updatedRule.copyWith(nextDueDate: due);
        guard++;
      }

      if (guard > 0) {
        await _db.upsertRecurringTransaction(updatedRule);
      }
    }

    return generatedCount;
  }

  /// Manually logs a single occurrence of a recurring bill right now and advances its next due date.
  Future<void> logRecurringRuleNow(RecurringTransaction rule) async {
    final now = DateTime.now();
    final tx = TransactionItem(
      id: _uuid.v4(),
      type: rule.type == TransactionType.transfer
          ? TransactionType.expense
          : rule.type,
      amount: rule.amount,
      accountId: rule.accountId,
      categoryId: rule.categoryId,
      date: now,
      note: rule.note.isNotEmpty ? '${rule.title} • ${rule.note}' : rule.title,
      recurringRuleId: rule.id,
    );
    await _db.upsertTransaction(tx);

    final baseDate = rule.nextDueDate.isAfter(now) ? rule.nextDueDate : now;
    await _db.upsertRecurringTransaction(
      rule.copyWith(nextDueDate: rule.advanceDueDate(baseDate)),
    );
  }
}
