import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/data/repositories/finance_repository.dart';
import 'package:money_manager/data/services/database_service.dart';
import 'package:money_manager/domain/models/account.dart';
import 'package:money_manager/domain/models/backup_payload.dart';
import 'package:money_manager/domain/models/budget.dart';
import 'package:money_manager/domain/models/recurring_transaction.dart';
import 'package:money_manager/domain/models/transaction_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  Future<({DatabaseService db, FinanceRepository repo})> createTestRepo() async {
    final db = DatabaseService(
      databaseFactoryOverride: databaseFactoryFfi,
      dbPathOverride: inMemoryDatabasePath,
    );
    final repo = FinanceRepository(databaseService: db);
    await repo.init();
    return (db: db, repo: repo);
  }

  test('seeds default accounts and categories locally on first launch',
      () async {
    final env = await createTestRepo();
    addTearDown(env.db.close);

    final accounts = await env.repo.getAccounts();
    final categories = await env.repo.getCategories();

    expect(accounts.length, 2);
    expect(accounts.map((a) => a.id), containsAll(<String>['acc_cash', 'acc_bank']));
    expect(categories.length, greaterThanOrEqualTo(10));
  });

  test('computes account balances across income, expense, and wallet transfers',
      () async {
    final env = await createTestRepo();
    addTearDown(env.db.close);

    final now = DateTime(2026, 11, 20);
    await env.repo.saveTransaction(
      TransactionItem(
        id: 'tx_1',
        type: TransactionType.income,
        amount: 2000.0,
        accountId: 'acc_bank',
        categoryId: 'cat_salary',
        date: now,
        note: 'Paycheck',
      ),
    );
    await env.repo.saveTransaction(
      TransactionItem(
        id: 'tx_2',
        type: TransactionType.transfer,
        amount: 350.0,
        accountId: 'acc_bank',
        toAccountId: 'acc_cash',
        date: now,
        note: 'ATM Withdrawal',
      ),
    );
    await env.repo.saveTransaction(
      TransactionItem(
        id: 'tx_3',
        type: TransactionType.expense,
        amount: 45.50,
        accountId: 'acc_cash',
        categoryId: 'cat_food',
        date: now,
        note: 'Groceries & Lunch',
      ),
    );

    final accounts = await env.repo.getAccounts();
    final txs = await env.repo.getTransactions();
    final summaries = env.repo.computeAccountSummaries(
      accounts: accounts,
      transactions: txs,
    );

    final cash = summaries.firstWhere((s) => s.account.id == 'acc_cash');
    final bank = summaries.firstWhere((s) => s.account.id == 'acc_bank');

    expect(cash.currentBalance, closeTo(304.50, 0.001));
    expect(bank.currentBalance, closeTo(1650.0, 0.001));
  });

  test('evaluates monthly category budgets and warning/over-budget flags',
      () async {
    final env = await createTestRepo();
    addTearDown(env.db.close);

    final now = DateTime(2026, 11, 15);
    await env.repo.saveBudget(
      const Budget(
        id: 'bud_food',
        categoryId: 'cat_food',
        yearMonth: '2026-11',
        limitAmount: 200.0,
      ),
    );
    await env.repo.saveBudget(
      const Budget(
        id: 'bud_transport',
        categoryId: 'cat_transport',
        yearMonth: '2026-11',
        limitAmount: 100.0,
      ),
    );

    await env.repo.saveTransaction(
      TransactionItem(
        id: 'tx_f1',
        type: TransactionType.expense,
        amount: 170.0,
        accountId: 'acc_cash',
        categoryId: 'cat_food',
        date: now,
      ),
    );
    await env.repo.saveTransaction(
      TransactionItem(
        id: 'tx_t1',
        type: TransactionType.expense,
        amount: 120.0,
        accountId: 'acc_cash',
        categoryId: 'cat_transport',
        date: now,
      ),
    );

    final budgets = await env.repo.getBudgets();
    final categories = await env.repo.getCategories();
    final txs = await env.repo.getTransactions();

    final progress = env.repo.computeMonthlyBudgets(
      yearMonth: '2026-11',
      budgets: budgets,
      categories: categories,
      transactions: txs,
    );

    final transport =
        progress.firstWhere((p) => p.category.id == 'cat_transport');
    final food = progress.firstWhere((p) => p.category.id == 'cat_food');

    expect(transport.isOverBudget, isTrue);
    expect(transport.remainingAmount, closeTo(-20.0, 0.001));
    expect(food.isWarning, isTrue);
    expect(food.isOverBudget, isFalse);
  });

  test('auto-logs due recurring bills locally and advances nextDueDate',
      () async {
    final env = await createTestRepo();
    addTearDown(env.db.close);

    final rule = RecurringTransaction(
      id: 'rec_rent',
      title: 'Apartment Rent',
      type: TransactionType.expense,
      amount: 950.0,
      accountId: 'acc_bank',
      categoryId: 'cat_housing',
      frequency: RecurrenceFrequency.monthly,
      nextDueDate: DateTime(2026, 10, 1),
      autoLog: true,
      isActive: true,
    );
    await env.repo.saveRecurringTransaction(rule);

    final logged = await env.repo.processDueRecurringTransactions(
      now: DateTime(2026, 11, 20),
    );
    expect(logged, 2); // Oct 1 and Nov 1

    final txs = await env.repo.getTransactions();
    expect(txs.length, 2);
    expect(txs.every((t) => t.recurringRuleId == 'rec_rent'), isTrue);

    final updatedRules = await env.repo.getRecurringTransactions();
    expect(updatedRules.single.nextDueDate, DateTime(2026, 12, 1));
  });

  test('exports readable JSON backup and atomically restores all entities',
      () async {
    final env = await createTestRepo();
    addTearDown(env.db.close);

    await env.repo.saveAccount(
      Account(
        id: 'acc_savings',
        name: 'Emergency Fund',
        type: AccountType.savings,
        initialBalance: 5000,
        colorValue: 0xFF2D6A5B,
        iconCodePoint: AccountIcons.savings.codePoint,
        createdAt: DateTime(2026, 11, 1),
      ),
    );
    await env.repo.saveTransaction(
      TransactionItem(
        id: 'tx_backup_1',
        type: TransactionType.income,
        amount: 750.0,
        accountId: 'acc_savings',
        categoryId: 'cat_freelance',
        date: DateTime(2026, 11, 10),
        note: 'Design sprint',
      ),
    );

    final exported = await env.repo.exportBackup(
      currencyCode: 'EUR',
      currencySymbol: '€',
    );
    final prettyJson = exported.toPrettyJsonString();
    expect(prettyJson, contains('Emergency Fund'));
    expect(prettyJson, contains('Design sprint'));

    // Restore into a fresh database instance
    final targetEnv = await createTestRepo();
    addTearDown(targetEnv.db.close);

    final parsed = BackupPayload.fromJsonString(prettyJson);
    await targetEnv.repo.restoreBackup(parsed);

    final restoredAccounts = await targetEnv.repo.getAccounts();
    final restoredTxs = await targetEnv.repo.getTransactions();

    expect(restoredAccounts.any((a) => a.id == 'acc_savings'), isTrue);
    expect(restoredTxs.single.note, 'Design sprint');
    expect(restoredTxs.single.amount, 750.0);
  });

  test('converts foreign currency wallets, cross-currency transfers, and budgets into base currency offline',
      () async {
    final env = await createTestRepo();
    addTearDown(env.db.close);

    final eurAccount = Account(
      id: 'acc_eur',
      name: 'Euro Travel',
      type: AccountType.savings,
      initialBalance: 500.0,
      colorValue: 0xFF3A6B9C,
      iconCodePoint: AccountIcons.savings.codePoint,
      createdAt: DateTime(2026, 11, 1),
      currencyCode: 'EUR',
      currencySymbol: '€',
      exchangeRateToBase: 1.08,
    );
    await env.repo.saveAccount(eurAccount);

    await env.repo.saveBudget(
      const Budget(
        id: 'bud_eur_food',
        categoryId: 'cat_food',
        yearMonth: '2026-11',
        limitAmount: 200.0,
      ),
    );

    final now = DateTime(2026, 11, 20);
    // Spend €100 from EUR wallet (= $108 USD)
    await env.repo.saveTransaction(
      TransactionItem(
        id: 'tx_eur_exp',
        type: TransactionType.expense,
        amount: 100.0,
        accountId: 'acc_eur',
        categoryId: 'cat_food',
        date: now,
      ),
    );
    // Transfer $108 from USD Main Bank -> EUR wallet (= +€100)
    await env.repo.saveTransaction(
      TransactionItem(
        id: 'tx_fx_xfer',
        type: TransactionType.transfer,
        amount: 108.0,
        accountId: 'acc_bank',
        toAccountId: 'acc_eur',
        date: now,
      ),
    );

    final accounts = await env.repo.getAccounts();
    final txs = await env.repo.getTransactions();
    final categories = await env.repo.getCategories();
    final budgets = await env.repo.getBudgets();

    final summaries = env.repo.computeAccountSummaries(
      accounts: accounts,
      transactions: txs,
      baseCurrencyCode: 'USD',
    );
    final eurSummary = summaries.firstWhere((s) => s.account.id == 'acc_eur');
    final bankSummary = summaries.firstWhere((s) => s.account.id == 'acc_bank');

    // €500 - €100 + €100 = €500 native, ≈ $540 USD
    expect(eurSummary.currentBalance, closeTo(500.0, 0.001));
    expect(eurSummary.currentBalanceInBase, closeTo(540.0, 0.001));
    expect(bankSummary.currentBalance, closeTo(-108.0, 0.001));

    final budgetProgress = env.repo.computeMonthlyBudgets(
      yearMonth: '2026-11',
      budgets: budgets,
      categories: categories,
      transactions: txs,
      accounts: accounts,
      baseCurrencyCode: 'USD',
    );
    expect(budgetProgress.single.spentAmount, closeTo(108.0, 0.001));
  });
}
