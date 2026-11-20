import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/models/account.dart';
import '../../domain/models/backup_payload.dart';
import '../../domain/models/budget.dart';
import '../../domain/models/category.dart';
import '../../domain/models/recurring_transaction.dart';
import '../../domain/models/transaction_item.dart';
import 'sqlite_factory_stub.dart'
    if (dart.library.io) 'sqlite_factory_io.dart';

/// Local-only persistence service.
///
/// Uses SQLite (`money_manager.db`) on Android, iOS, and Desktop/Tests, and
/// falls back cleanly to browser `localStorage` via `SharedPreferences` on Web
/// so the offline-first iOS/Android PWA works identically offline.
class DatabaseService {
  DatabaseService({
    this.databaseFactoryOverride,
    this.dbPathOverride,
    bool? forceKeyValueStore,
  }) : _forceKeyValueStore = forceKeyValueStore ?? kIsWeb;

  static const int _dbVersion = 2;
  static const String _dbFileName = 'money_manager.db';

  // Web / key-value fallback keys
  static const String _kvSeeded = 'mm_kv_seeded';
  static const String _kvAccounts = 'mm_kv_accounts';
  static const String _kvCategories = 'mm_kv_categories';
  static const String _kvTransactions = 'mm_kv_transactions';
  static const String _kvBudgets = 'mm_kv_budgets';
  static const String _kvRecurring = 'mm_kv_recurring';

  final DatabaseFactory? databaseFactoryOverride;
  final String? dbPathOverride;
  final bool _forceKeyValueStore;

  Database? _db;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    if (_forceKeyValueStore) {
      await _initKeyValueStore();
      _initialized = true;
      return;
    }

    final factory = databaseFactoryOverride ??
        resolveDesktopDatabaseFactory() ??
        databaseFactory;

    final path = dbPathOverride ??
        p.join(await factory.getDatabasesPath(), _dbFileName);

    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: (db, version) async {
          await _createTables(db);
          await _seedDefaultsInDb(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE accounts ADD COLUMN currency_code TEXT');
            await db.execute('ALTER TABLE accounts ADD COLUMN currency_symbol TEXT');
            await db.execute(
              'ALTER TABLE accounts ADD COLUMN exchange_rate REAL NOT NULL DEFAULT 1.0',
            );
          }
        },
      ),
    );
    _initialized = true;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    _initialized = false;
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        initial_balance REAL NOT NULL,
        color_value INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        currency_code TEXT,
        currency_symbol TEXT,
        exchange_rate REAL NOT NULL DEFAULT 1.0
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL,
        is_default INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        account_id TEXT NOT NULL,
        to_account_id TEXT,
        category_id TEXT,
        date TEXT NOT NULL,
        note TEXT NOT NULL,
        recurring_rule_id TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_tx_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_tx_account ON transactions(account_id)');
    await db.execute('CREATE INDEX idx_tx_category ON transactions(category_id)');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        year_month TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        UNIQUE(category_id, year_month)
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        account_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        frequency TEXT NOT NULL,
        next_due_date TEXT NOT NULL,
        auto_log INTEGER NOT NULL,
        is_active INTEGER NOT NULL,
        note TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedDefaultsInDb(DatabaseExecutor db) async {
    final now = DateTime.now();
    final defaultAccounts = _buildDefaultAccounts(now);
    for (final account in defaultAccounts) {
      await db.insert('accounts', account.toMap());
    }
    for (final category in DefaultCategories.all) {
      await db.insert('categories', category.toMap());
    }
  }

  Future<void> _initKeyValueStore() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kvSeeded) == true) return;

    final now = DateTime.now();
    await _writeKvList(
      prefs,
      _kvAccounts,
      _buildDefaultAccounts(now).map((e) => e.toJson()).toList(),
    );
    await _writeKvList(
      prefs,
      _kvCategories,
      DefaultCategories.all.map((e) => e.toJson()).toList(),
    );
    await _writeKvList(prefs, _kvTransactions, const <Map<String, dynamic>>[]);
    await _writeKvList(prefs, _kvBudgets, const <Map<String, dynamic>>[]);
    await _writeKvList(prefs, _kvRecurring, const <Map<String, dynamic>>[]);
    await prefs.setBool(_kvSeeded, true);
  }

  List<Account> _buildDefaultAccounts(DateTime now) {
    return <Account>[
      Account(
        id: 'acc_cash',
        name: 'Cash Wallet',
        type: AccountType.cash,
        initialBalance: 0.0,
        colorValue: 0xFF2D6A5B,
        iconCodePoint: Icons.payments_outlined.codePoint,
        createdAt: now,
      ),
      Account(
        id: 'acc_bank',
        name: 'Main Bank',
        type: AccountType.bank,
        initialBalance: 0.0,
        colorValue: 0xFF3A6B9C,
        iconCodePoint: Icons.account_balance_outlined.codePoint,
        createdAt: now.add(const Duration(milliseconds: 1)),
      ),
    ];
  }

  // --- Accounts ---

  Future<List<Account>> getAccounts() async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      final list = _readKvList(prefs, _kvAccounts);
      final accounts = list.map(Account.fromJson).toList();
      accounts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return accounts;
    }
    final rows = await _db!.query('accounts', orderBy: 'created_at ASC');
    return rows.map(Account.fromMap).toList();
  }

  Future<void> upsertAccount(Account account) async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      final items = _readKvList(prefs, _kvAccounts)
          .map(Account.fromJson)
          .where((e) => e.id != account.id)
          .toList()
        ..add(account);
      await _writeKvList(prefs, _kvAccounts, items.map((e) => e.toJson()).toList());
      return;
    }
    await _db!.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAccount(String accountId) async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      final accounts = _readKvList(prefs, _kvAccounts)
          .map(Account.fromJson)
          .where((e) => e.id != accountId)
          .toList();
      final txs = _readKvList(prefs, _kvTransactions)
          .map(TransactionItem.fromJson)
          .where((t) => t.accountId != accountId && t.toAccountId != accountId)
          .toList();
      final recurring = _readKvList(prefs, _kvRecurring)
          .map(RecurringTransaction.fromJson)
          .where((r) => r.accountId != accountId)
          .toList();
      await _writeKvList(prefs, _kvAccounts, accounts.map((e) => e.toJson()).toList());
      await _writeKvList(prefs, _kvTransactions, txs.map((e) => e.toJson()).toList());
      await _writeKvList(prefs, _kvRecurring, recurring.map((e) => e.toJson()).toList());
      return;
    }
    await _db!.transaction((txn) async {
      await txn.delete('accounts', where: 'id = ?', whereArgs: <Object?>[accountId]);
      await txn.delete(
        'transactions',
        where: 'account_id = ? OR to_account_id = ?',
        whereArgs: <Object?>[accountId, accountId],
      );
      await txn.delete(
        'recurring_transactions',
        where: 'account_id = ?',
        whereArgs: <Object?>[accountId],
      );
    });
  }

  // --- Categories ---

  Future<List<CategoryItem>> getCategories() async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      return _readKvList(prefs, _kvCategories).map(CategoryItem.fromJson).toList();
    }
    final rows = await _db!.query('categories', orderBy: 'is_default DESC, name ASC');
    return rows.map(CategoryItem.fromMap).toList();
  }

  Future<void> upsertCategory(CategoryItem category) async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      final items = _readKvList(prefs, _kvCategories)
          .map(CategoryItem.fromJson)
          .where((e) => e.id != category.id)
          .toList()
        ..add(category);
      await _writeKvList(prefs, _kvCategories, items.map((e) => e.toJson()).toList());
      return;
    }
    await _db!.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      final categories = _readKvList(prefs, _kvCategories)
          .map(CategoryItem.fromJson)
          .where((e) => e.id != categoryId)
          .toList();
      final budgets = _readKvList(prefs, _kvBudgets)
          .map(Budget.fromJson)
          .where((b) => b.categoryId != categoryId)
          .toList();
      await _writeKvList(
          prefs, _kvCategories, categories.map((e) => e.toJson()).toList());
      await _writeKvList(prefs, _kvBudgets, budgets.map((e) => e.toJson()).toList());
      return;
    }
    await _db!.transaction((txn) async {
      await txn.delete('categories', where: 'id = ?', whereArgs: <Object?>[categoryId]);
      await txn.delete('budgets', where: 'category_id = ?', whereArgs: <Object?>[categoryId]);
    });
  }

  // --- Transactions ---

  Future<List<TransactionItem>> getTransactions() async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      final items =
          _readKvList(prefs, _kvTransactions).map(TransactionItem.fromJson).toList();
      items.sort((a, b) => b.date.compareTo(a.date));
      return items;
    }
    final rows = await _db!.query('transactions', orderBy: 'date DESC');
    return rows.map(TransactionItem.fromMap).toList();
  }

  Future<void> upsertTransaction(TransactionItem transaction) async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      final items = _readKvList(prefs, _kvTransactions)
          .map(TransactionItem.fromJson)
          .where((e) => e.id != transaction.id)
          .toList()
        ..add(transaction);
      await _writeKvList(
          prefs, _kvTransactions, items.map((e) => e.toJson()).toList());
      return;
    }
    await _db!.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTransaction(String id) async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      final items = _readKvList(prefs, _kvTransactions)
          .map(TransactionItem.fromJson)
          .where((e) => e.id != id)
          .toList();
      await _writeKvList(
          prefs, _kvTransactions, items.map((e) => e.toJson()).toList());
      return;
    }
    await _db!.delete('transactions', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  // --- Budgets ---

  Future<List<Budget>> getBudgets() async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      return _readKvList(prefs, _kvBudgets).map(Budget.fromJson).toList();
    }
    final rows = await _db!.query('budgets');
    return rows.map(Budget.fromMap).toList();
  }

  Future<void> upsertBudget(Budget budget) async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      final items = _readKvList(prefs, _kvBudgets)
          .map(Budget.fromJson)
          .where((e) =>
              e.id != budget.id &&
              !(e.categoryId == budget.categoryId &&
                  e.yearMonth == budget.yearMonth))
          .toList()
        ..add(budget);
      await _writeKvList(prefs, _kvBudgets, items.map((e) => e.toJson()).toList());
      return;
    }
    await _db!.transaction((txn) async {
      await txn.delete(
        'budgets',
        where: 'category_id = ? AND year_month = ?',
        whereArgs: <Object?>[budget.categoryId, budget.yearMonth],
      );
      await txn.insert(
        'budgets',
        budget.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> deleteBudget(String id) async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      final items = _readKvList(prefs, _kvBudgets)
          .map(Budget.fromJson)
          .where((e) => e.id != id)
          .toList();
      await _writeKvList(prefs, _kvBudgets, items.map((e) => e.toJson()).toList());
      return;
    }
    await _db!.delete('budgets', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  // --- Recurring Transactions ---

  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      final items = _readKvList(prefs, _kvRecurring)
          .map(RecurringTransaction.fromJson)
          .toList();
      items.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
      return items;
    }
    final rows =
        await _db!.query('recurring_transactions', orderBy: 'next_due_date ASC');
    return rows.map(RecurringTransaction.fromMap).toList();
  }

  Future<void> upsertRecurringTransaction(RecurringTransaction item) async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      final items = _readKvList(prefs, _kvRecurring)
          .map(RecurringTransaction.fromJson)
          .where((e) => e.id != item.id)
          .toList()
        ..add(item);
      await _writeKvList(prefs, _kvRecurring, items.map((e) => e.toJson()).toList());
      return;
    }
    await _db!.insert(
      'recurring_transactions',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      final items = _readKvList(prefs, _kvRecurring)
          .map(RecurringTransaction.fromJson)
          .where((e) => e.id != id)
          .toList();
      await _writeKvList(prefs, _kvRecurring, items.map((e) => e.toJson()).toList());
      return;
    }
    await _db!
        .delete('recurring_transactions', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  // --- Backup & Atomic Restore ---

  Future<BackupPayload> exportAllData({
    required String currencyCode,
    required String currencySymbol,
  }) async {
    await init();
    final accounts = await getAccounts();
    final categories = await getCategories();
    final transactions = await getTransactions();
    final budgets = await getBudgets();
    final recurring = await getRecurringTransactions();

    return BackupPayload(
      exportedAt: DateTime.now().toUtc(),
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      accounts: accounts,
      categories: categories,
      transactions: transactions,
      budgets: budgets,
      recurringTransactions: recurring,
    );
  }

  Future<void> restoreAllData(BackupPayload payload) async {
    await init();
    if (_forceKeyValueStore) {
      final prefs = await SharedPreferences.getInstance();
      await _writeKvList(
          prefs, _kvAccounts, payload.accounts.map((e) => e.toJson()).toList());
      await _writeKvList(prefs, _kvCategories,
          payload.categories.map((e) => e.toJson()).toList());
      await _writeKvList(prefs, _kvTransactions,
          payload.transactions.map((e) => e.toJson()).toList());
      await _writeKvList(
          prefs, _kvBudgets, payload.budgets.map((e) => e.toJson()).toList());
      await _writeKvList(prefs, _kvRecurring,
          payload.recurringTransactions.map((e) => e.toJson()).toList());
      await prefs.setBool(_kvSeeded, true);
      return;
    }

    await _db!.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('budgets');
      await txn.delete('recurring_transactions');
      await txn.delete('categories');
      await txn.delete('accounts');

      for (final account in payload.accounts) {
        await txn.insert('accounts', account.toMap());
      }
      for (final category in payload.categories) {
        await txn.insert('categories', category.toMap());
      }
      for (final item in payload.transactions) {
        await txn.insert('transactions', item.toMap());
      }
      for (final budget in payload.budgets) {
        await txn.insert('budgets', budget.toMap());
      }
      for (final rule in payload.recurringTransactions) {
        await txn.insert('recurring_transactions', rule.toMap());
      }
    });
  }

  List<Map<String, dynamic>> _readKvList(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _writeKvList(
    SharedPreferences prefs,
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    await prefs.setString(key, jsonEncode(items));
  }
}
