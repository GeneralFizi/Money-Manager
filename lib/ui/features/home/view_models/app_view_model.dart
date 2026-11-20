import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../data/services/biometric_service.dart';
import '../../../../data/services/google_drive_service.dart';
import '../../../../data/services/local_export_service.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../../domain/models/account.dart';
import '../../../../domain/models/budget.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/recurring_transaction.dart';
import '../../../../domain/models/transaction_item.dart';

/// Category spending slice for Analytics Donut Chart.
class CategorySpendSlice {
  const CategorySpendSlice({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  final CategoryItem category;
  final double amount;
  final double percentage;
}

/// Monthly Income vs. Expense totals for Cashflow Bar Charts.
class MonthlyCashflowPoint {
  const MonthlyCashflowPoint({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;

  double get net => income - expense;
}

/// Primary MVVM ViewModel powering all local state and explicit on-demand sync actions.
class AppViewModel extends ChangeNotifier {
  AppViewModel({
    required FinanceRepository repository,
    required PreferencesService preferencesService,
    required BiometricService biometricService,
    required LocalExportService localExportService,
    required GoogleDriveService googleDriveService,
  })  : _repo = repository,
        _prefs = preferencesService,
        _biometrics = biometricService,
        _localExport = localExportService,
        _drive = googleDriveService;

  final FinanceRepository _repo;
  final PreferencesService _prefs;
  final BiometricService _biometrics;
  final LocalExportService _localExport;
  final GoogleDriveService _drive;
  static const Uuid _uuid = Uuid();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSyncBusy = false;
  bool get isSyncBusy => _isSyncBusy;

  bool _isLocked = false;
  bool get isLocked => _isLocked;

  bool _biometricAvailable = false;
  bool get biometricAvailable => _biometricAvailable;

  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  List<Account> _accounts = <Account>[];
  List<Account> get accounts => _accounts;

  List<CategoryItem> _categories = <CategoryItem>[];
  List<CategoryItem> get categories => _categories;

  List<TransactionItem> _transactions = <TransactionItem>[];
  List<TransactionItem> get transactions => _transactions;

  List<Budget> _budgets = <Budget>[];
  List<Budget> get budgets => _budgets;

  List<RecurringTransaction> _recurringTransactions = <RecurringTransaction>[];
  List<RecurringTransaction> get recurringTransactions =>
      _recurringTransactions;

  // Filters
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime get selectedMonth => _selectedMonth;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _selectedAccountFilterId;
  String? get selectedAccountFilterId => _selectedAccountFilterId;

  TransactionType? _selectedTypeFilter;
  TransactionType? get selectedTypeFilter => _selectedTypeFilter;

  String get selectedYearMonth => Budget.formatYearMonth(_selectedMonth);

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _repo.init();
    _settings = await _prefs.loadSettings();
    _biometricAvailable = await _biometrics.isBiometricAvailable();
    _isLocked = _settings.biometricEnabled && _biometricAvailable;

    // Evaluate due recurring bills strictly locally on startup.
    final autoLoggedCount = await _repo.processDueRecurringTransactions();
    await _reloadData();

    if (autoLoggedCount > 0) {
      _statusMessage =
          'Auto-logged $autoLoggedCount scheduled recurring transaction(s).';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _reloadData() async {
    _accounts = await _repo.getAccounts();
    _categories = await _repo.getCategories();
    _transactions = await _repo.getTransactions();
    _budgets = await _repo.getBudgets();
    _recurringTransactions = await _repo.getRecurringTransactions();
  }

  void clearStatusMessage() {
    _statusMessage = null;
  }

  // --- Derived Read Models ---

  double amountInBase(TransactionItem tx) {
    final acc = accountById(tx.accountId);
    if (acc == null) return tx.amount;
    return acc.toBaseAmount(tx.amount, _settings.currencyCode);
  }

  List<AccountSummary> get accountSummaries => _repo.computeAccountSummaries(
        accounts: _accounts,
        transactions: _transactions,
        baseCurrencyCode: _settings.currencyCode,
      );

  double get totalNetBalance => accountSummaries.fold<double>(
        0.0,
        (sum, summary) => sum + summary.currentBalanceInBase,
      );

  List<TransactionItem> get monthlyTransactions {
    return _transactions.where((tx) {
      return tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;
    }).toList();
  }

  List<TransactionItem> get filteredMonthlyTransactions {
    final query = _searchQuery.trim().toLowerCase();
    final catMap = <String, CategoryItem>{
      for (final c in _categories) c.id: c,
    };
    final accMap = <String, Account>{
      for (final a in _accounts) a.id: a,
    };

    return monthlyTransactions.where((tx) {
      if (_selectedTypeFilter != null && tx.type != _selectedTypeFilter) {
        return false;
      }
      if (_selectedAccountFilterId != null &&
          tx.accountId != _selectedAccountFilterId &&
          tx.toAccountId != _selectedAccountFilterId) {
        return false;
      }
      if (query.isNotEmpty) {
        final catName =
            catMap[tx.categoryId]?.name.toLowerCase() ?? 'transfer';
        final accName = accMap[tx.accountId]?.name.toLowerCase() ?? '';
        final note = tx.note.toLowerCase();
        if (!catName.contains(query) &&
            !accName.contains(query) &&
            !note.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  double get monthlyIncome => monthlyTransactions
      .where((tx) => tx.type == TransactionType.income)
      .fold<double>(0.0, (sum, tx) => sum + amountInBase(tx));

  double get monthlyExpense => monthlyTransactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold<double>(0.0, (sum, tx) => sum + amountInBase(tx));

  double get monthlyNet => monthlyIncome - monthlyExpense;

  List<BudgetProgress> get monthlyBudgets => _repo.computeMonthlyBudgets(
        yearMonth: selectedYearMonth,
        budgets: _budgets,
        categories: _categories,
        transactions: _transactions,
        accounts: _accounts,
        baseCurrencyCode: _settings.currencyCode,
      );

  List<CategoryItem> get incomeCategories => _categories
      .where((c) => c.type == CategoryType.income)
      .toList();

  List<CategoryItem> get expenseCategories => _categories
      .where((c) => c.type == CategoryType.expense)
      .toList();

  Account? accountById(String? id) {
    if (id == null) return null;
    for (final acc in _accounts) {
      if (acc.id == id) return acc;
    }
    return null;
  }

  CategoryItem? categoryById(String? id) {
    if (id == null) return null;
    for (final cat in _categories) {
      if (cat.id == id) return cat;
    }
    return null;
  }

  List<CategorySpendSlice> get expenseBreakdownByCategory {
    final total = monthlyExpense;
    if (total <= 0) return const <CategorySpendSlice>[];

    final sums = <String, double>{};
    for (final tx in monthlyTransactions) {
      if (tx.type != TransactionType.expense || tx.categoryId == null) continue;
      sums[tx.categoryId!] = (sums[tx.categoryId!] ?? 0) + amountInBase(tx);
    }

    final slices = <CategorySpendSlice>[];
    for (final entry in sums.entries) {
      final category = categoryById(entry.key);
      if (category == null) continue;
      slices.add(
        CategorySpendSlice(
          category: category,
          amount: entry.value,
          percentage: (entry.value / total) * 100,
        ),
      );
    }
    slices.sort((a, b) => b.amount.compareTo(a.amount));
    return slices;
  }

  MonthlyCashflowPoint _cashflowForMonth(DateTime target) {
    double inc = 0;
    double exp = 0;
    for (final tx in _transactions) {
      if (tx.date.year == target.year && tx.date.month == target.month) {
        if (tx.type == TransactionType.income) inc += amountInBase(tx);
        if (tx.type == TransactionType.expense) exp += amountInBase(tx);
      }
    }
    return MonthlyCashflowPoint(month: target, income: inc, expense: exp);
  }

  List<MonthlyCashflowPoint> get sixMonthCashflow {
    return List<MonthlyCashflowPoint>.generate(
      6,
      (index) => _cashflowForMonth(
        DateTime(_selectedMonth.year, _selectedMonth.month - (5 - index), 1),
      ),
    );
  }

  /// Monthly cashflow totals from January of [_selectedMonth.year] through [_selectedMonth].
  List<MonthlyCashflowPoint> get ytdCashflow {
    return List<MonthlyCashflowPoint>.generate(
      _selectedMonth.month,
      (index) => _cashflowForMonth(
        DateTime(_selectedMonth.year, index + 1, 1),
      ),
    );
  }

  double get ytdIncome =>
      ytdCashflow.fold<double>(0.0, (sum, pt) => sum + pt.income);

  double get ytdExpense =>
      ytdCashflow.fold<double>(0.0, (sum, pt) => sum + pt.expense);

  double get ytdNet => ytdIncome - ytdExpense;

  // --- Filter Controls ---

  void changeMonth(int delta) {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setAccountFilter(String? accountId) {
    _selectedAccountFilterId =
        _selectedAccountFilterId == accountId ? null : accountId;
    notifyListeners();
  }

  void setTypeFilter(TransactionType? type) {
    _selectedTypeFilter = _selectedTypeFilter == type ? null : type;
    notifyListeners();
  }

  // --- Security / Biometric Lock ---

  void lockIfEnabled() {
    if (_settings.biometricEnabled && _biometricAvailable && !_isLocked) {
      _isLocked = true;
      notifyListeners();
    }
  }

  Future<bool> unlockWithBiometrics() async {
    if (!_settings.biometricEnabled) return false;
    final ok = await _biometrics.authenticate();
    if (ok) {
      _isLocked = false;
      notifyListeners();
    }
    return ok;
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _prefs.saveBiometricEnabled(value);
    _settings = _settings.copyWith(biometricEnabled: value);
    if (!value) {
      _isLocked = false;
    }
    notifyListeners();
  }

  // --- Financial CRUD ---

  Future<void> saveTransaction(TransactionItem item) async {
    await _repo.saveTransaction(item);
    await _reloadData();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _repo.deleteTransaction(id);
    await _reloadData();
    notifyListeners();
  }

  Future<void> saveAccount(Account account) async {
    await _repo.saveAccount(account);
    await _reloadData();
    notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    if (_accounts.length <= 1) {
      throw StateError('At least one wallet/account must remain.');
    }
    await _repo.deleteAccount(id);
    if (_selectedAccountFilterId == id) {
      _selectedAccountFilterId = null;
    }
    await _reloadData();
    notifyListeners();
  }

  Future<void> saveCategory(CategoryItem category) async {
    await _repo.saveCategory(category);
    await _reloadData();
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    await _repo.deleteCategory(id);
    await _reloadData();
    notifyListeners();
  }

  Future<void> saveMonthlyBudget({
    required String categoryId,
    required double limitAmount,
  }) async {
    final existing = _budgets.where(
      (b) => b.categoryId == categoryId && b.yearMonth == selectedYearMonth,
    );
    final budget = Budget(
      id: existing.isNotEmpty ? existing.first.id : _uuid.v4(),
      categoryId: categoryId,
      yearMonth: selectedYearMonth,
      limitAmount: limitAmount,
    );
    await _repo.saveBudget(budget);
    await _reloadData();
    notifyListeners();
  }

  Future<void> deleteBudget(String id) async {
    await _repo.deleteBudget(id);
    await _reloadData();
    notifyListeners();
  }

  Future<void> saveRecurringTransaction(RecurringTransaction rule) async {
    await _repo.saveRecurringTransaction(rule);
    await _repo.processDueRecurringTransactions();
    await _reloadData();
    notifyListeners();
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _repo.deleteRecurringTransaction(id);
    await _reloadData();
    notifyListeners();
  }

  Future<void> logRecurringNow(RecurringTransaction rule) async {
    await _repo.logRecurringRuleNow(rule);
    await _reloadData();
    notifyListeners();
  }

  // --- Preferences ---

  Future<void> updateCurrency(String code, String symbol) async {
    await _prefs.saveCurrency(code, symbol);
    _settings = _settings.copyWith(currencyCode: code, currencySymbol: symbol);
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    await _prefs.saveThemeMode(mode);
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
  }

  Future<void> updateUseDynamicColor(bool value) async {
    await _prefs.saveUseDynamicColor(value);
    _settings = _settings.copyWith(useDynamicColor: value);
    notifyListeners();
  }

  Future<void> updateGoogleClientId(String? clientId) async {
    await _prefs.saveGoogleClientId(clientId);
    _settings = _settings.copyWith(
      googleClientId: clientId?.trim(),
      clearGoogleClientId: clientId == null || clientId.trim().isEmpty,
    );
    notifyListeners();
  }

  // --- Backup & Restore (Local + Strictly On-Demand Google Drive) ---

  Future<String> backupToGoogleDrive() async {
    _isSyncBusy = true;
    notifyListeners();
    try {
      final payload = await _repo.exportBackup(
        currencyCode: _settings.currencyCode,
        currencySymbol: _settings.currencySymbol,
      );
      final meta = await _drive.backupToGoogleDrive(
        payload,
        customClientId: _settings.googleClientId,
      );
      await _prefs.saveLastDriveBackup(meta.syncedAt);
      _settings = _settings.copyWith(lastDriveBackupAt: meta.syncedAt);
      return 'Backed up to Google Drive (${meta.folderName}/${meta.fileName}) as ${meta.accountEmail}.';
    } finally {
      _isSyncBusy = false;
      notifyListeners();
    }
  }

  Future<String> restoreFromGoogleDrive() async {
    _isSyncBusy = true;
    notifyListeners();
    try {
      final result = await _drive.restoreFromGoogleDrive(
        customClientId: _settings.googleClientId,
      );
      final payload = result.payload;
      await _repo.restoreBackup(payload);
      await _prefs.saveCurrency(payload.currencyCode, payload.currencySymbol);
      _settings = _settings.copyWith(
        currencyCode: payload.currencyCode,
        currencySymbol: payload.currencySymbol,
      );
      await _reloadData();
      return 'Restored ${payload.transactions.length} transactions from ${result.accountEmail}\'s Google Drive.';
    } finally {
      _isSyncBusy = false;
      notifyListeners();
    }
  }

  Future<void> signOutGoogleDrive() async {
    await _drive.signOut();
  }

  Future<bool> exportLocalJson() async {
    final payload = await _repo.exportBackup(
      currencyCode: _settings.currencyCode,
      currencySymbol: _settings.currencySymbol,
    );
    final saved = await _localExport.saveJsonBackupToDevice(payload);
    if (saved) {
      final now = DateTime.now();
      await _prefs.saveLastLocalExport(now);
      _settings = _settings.copyWith(lastLocalExportAt: now);
      notifyListeners();
    }
    return saved;
  }

  Future<void> shareBackupToApps() async {
    final payload = await _repo.exportBackup(
      currencyCode: _settings.currencyCode,
      currencySymbol: _settings.currencySymbol,
    );
    await _localExport.shareJsonBackup(payload);
    final now = DateTime.now();
    await _prefs.saveLastLocalExport(now);
    _settings = _settings.copyWith(lastLocalExportAt: now);
    notifyListeners();
  }

  Future<int?> importLocalJson() async {
    final payload = await _localExport.pickJsonBackupFromDevice();
    if (payload == null) return null;
    await _repo.restoreBackup(payload);
    await _prefs.saveCurrency(payload.currencyCode, payload.currencySymbol);
    _settings = _settings.copyWith(
      currencyCode: payload.currencyCode,
      currencySymbol: payload.currencySymbol,
    );
    await _reloadData();
    notifyListeners();
    return payload.transactions.length;
  }

  Future<bool> exportLocalCsv() async {
    return _localExport.saveTransactionsCsvToDevice(
      transactions: _transactions,
      accounts: _accounts,
      categories: _categories,
      currencyCode: _settings.currencyCode,
    );
  }

  Future<bool> exportYtdCashflowCsv() async {
    final fmt = DateFormat('MMM yyyy');
    final rows = ytdCashflow
        .map(
          (pt) => (
            month: fmt.format(pt.month),
            income: pt.income,
            expense: pt.expense,
            net: pt.net,
          ),
        )
        .toList();
    return _localExport.saveYtdCashflowCsvToDevice(
      year: _selectedMonth.year,
      currencyCode: _settings.currencyCode,
      rows: rows,
    );
  }
}
