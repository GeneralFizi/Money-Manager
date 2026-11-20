import 'package:material_ui/material_ui.dart';

/// Supported wallet/account types.
enum AccountType {
  cash('Cash'),
  bank('Bank'),
  card('Card'),
  savings('Savings'),
  other('Other');

  const AccountType(this.label);

  final String label;

  static AccountType fromName(String? value) {
    return AccountType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AccountType.other,
    );
  }
}

/// Constant icon registry for accounts so Flutter icon tree-shaking works in release builds.
class AccountIcons {
  static const IconData cash = Icons.payments_outlined;
  static const IconData bank = Icons.account_balance_outlined;
  static const IconData card = Icons.credit_card_outlined;
  static const IconData savings = Icons.savings_outlined;
  static const IconData other = Icons.account_balance_wallet_outlined;

  static const Map<int, IconData> byCodePoint = <int, IconData>{
    0xe481: cash,
    0xe040: bank,
    0xe19f: card,
    0xf335: savings,
    0xe041: other,
  };

  static IconData forType(AccountType type) {
    return switch (type) {
      AccountType.cash => cash,
      AccountType.bank => bank,
      AccountType.card => card,
      AccountType.savings => savings,
      AccountType.other => other,
    };
  }

  static IconData resolve(int codePoint, AccountType fallbackType) {
    final typeIcon = forType(fallbackType);
    if (codePoint == cash.codePoint) return cash;
    if (codePoint == bank.codePoint) return bank;
    if (codePoint == card.codePoint) return card;
    if (codePoint == savings.codePoint) return savings;
    if (codePoint == other.codePoint) return other;
    return typeIcon;
  }
}

/// Represents a local wallet, cash pouch, bank account, or card.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.colorValue,
    required this.iconCodePoint,
    required this.createdAt,
    this.currencyCode,
    this.currencySymbol,
    this.exchangeRateToBase = 1.0,
  });

  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final int colorValue;
  final int iconCodePoint;
  final DateTime createdAt;
  final String? currencyCode;
  final String? currencySymbol;
  /// Rate to convert 1 unit of this wallet's currency into the app's base currency.
  final double exchangeRateToBase;

  Color get color => Color(colorValue);
  IconData get icon => AccountIcons.resolve(iconCodePoint, type);

  String effectiveCurrencyCode(String baseCode) =>
      (currencyCode != null && currencyCode!.isNotEmpty)
          ? currencyCode!
          : baseCode;

  String effectiveCurrencySymbol(String baseSymbol) =>
      (currencySymbol != null && currencySymbol!.isNotEmpty)
          ? currencySymbol!
          : baseSymbol;

  bool isForeignCurrency(String baseCode) =>
      currencyCode != null &&
      currencyCode!.isNotEmpty &&
      currencyCode != baseCode;

  double toBaseAmount(double nativeAmount, String baseCode) =>
      isForeignCurrency(baseCode) ? nativeAmount * exchangeRateToBase : nativeAmount;

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? initialBalance,
    int? colorValue,
    int? iconCodePoint,
    DateTime? createdAt,
    String? currencyCode,
    bool clearCurrencyCode = false,
    String? currencySymbol,
    bool clearCurrencySymbol = false,
    double? exchangeRateToBase,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt ?? this.createdAt,
      currencyCode:
          clearCurrencyCode ? null : (currencyCode ?? this.currencyCode),
      currencySymbol:
          clearCurrencySymbol ? null : (currencySymbol ?? this.currencySymbol),
      exchangeRateToBase: exchangeRateToBase ?? this.exchangeRateToBase,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type.name,
      'initial_balance': initialBalance,
      'color_value': colorValue,
      'icon_code_point': iconCodePoint,
      'created_at': createdAt.toIso8601String(),
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'exchange_rate': exchangeRateToBase,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    final parsedType = AccountType.fromName(map['type'] as String?);
    final rawRate =
        (map['exchange_rate'] ?? map['exchangeRateToBase'] ?? 1.0) as num?;
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      type: parsedType,
      initialBalance: ((map['initial_balance'] ?? map['initialBalance']) as num?)?.toDouble() ?? 0.0,
      colorValue: ((map['color_value'] ?? map['colorValue']) as num?)?.toInt() ?? 0xFF2D6A5B,
      iconCodePoint: ((map['icon_code_point'] ?? map['iconCodePoint']) as num?)?.toInt() ??
          AccountIcons.forType(parsedType).codePoint,
      createdAt: DateTime.tryParse(
            (map['created_at'] ?? map['createdAt']) as String? ?? '',
          ) ??
          DateTime.now(),
      currencyCode: (map['currency_code'] ?? map['currencyCode']) as String?,
      currencySymbol:
          (map['currency_symbol'] ?? map['currencySymbol']) as String?,
      exchangeRateToBase: rawRate != null && rawRate > 0 ? rawRate.toDouble() : 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type.name,
      'initialBalance': initialBalance,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'createdAt': createdAt.toIso8601String(),
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'exchangeRateToBase': exchangeRateToBase,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) => Account.fromMap(json);
}

/// Computed summary for an account including current balance and totals.
class AccountSummary {
  const AccountSummary({
    required this.account,
    required this.currentBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.currentBalanceInBase,
    required this.totalIncomeInBase,
    required this.totalExpenseInBase,
  });

  final Account account;
  final double currentBalance;
  final double totalIncome;
  final double totalExpense;
  final double currentBalanceInBase;
  final double totalIncomeInBase;
  final double totalExpenseInBase;
}
