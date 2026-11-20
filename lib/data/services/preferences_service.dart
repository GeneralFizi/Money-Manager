import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported currency preset entry.
class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.label,
  });

  final String code;
  final String symbol;
  final String label;

  static const List<CurrencyOption> presets = <CurrencyOption>[
    CurrencyOption(code: 'USD', symbol: '\$', label: 'US Dollar'),
    CurrencyOption(code: 'EUR', symbol: '€', label: 'Euro'),
    CurrencyOption(code: 'GBP', symbol: '£', label: 'British Pound'),
    CurrencyOption(code: 'INR', symbol: '₹', label: 'Indian Rupee'),
    CurrencyOption(code: 'JPY', symbol: '¥', label: 'Japanese Yen'),
    CurrencyOption(code: 'CAD', symbol: 'CA\$', label: 'Canadian Dollar'),
    CurrencyOption(code: 'AUD', symbol: 'A\$', label: 'Australian Dollar'),
    CurrencyOption(code: 'SGD', symbol: 'S\$', label: 'Singapore Dollar'),
    CurrencyOption(code: 'IDR', symbol: 'Rp', label: 'Indonesian Rupiah'),
    CurrencyOption(code: 'MYR', symbol: 'RM', label: 'Malaysian Ringgit'),
  ];

  static CurrencyOption? findByCode(String code) {
    for (final opt in presets) {
      if (opt.code == code) return opt;
    }
    return null;
  }

  /// Approximate offline reference value in USD for 1 unit of [code].
  static double _usdPerUnit(String code) {
    return switch (code) {
      'USD' => 1.0,
      'EUR' => 1.08,
      'GBP' => 1.27,
      'INR' => 0.012,
      'JPY' => 0.0066,
      'CAD' => 0.73,
      'AUD' => 0.66,
      'SGD' => 0.74,
      'IDR' => 0.000063,
      'MYR' => 0.22,
      _ => 1.0,
    };
  }

  /// Computes default offline rate: `1 [walletCode] = X [baseCode]`.
  static double defaultRateToBase({
    required String walletCode,
    required String baseCode,
  }) {
    if (walletCode == baseCode) return 1.0;
    final walletInUsd = _usdPerUnit(walletCode);
    final baseInUsd = _usdPerUnit(baseCode);
    if (baseInUsd <= 0) return 1.0;
    final rate = walletInUsd / baseInUsd;
    return double.parse(rate.toStringAsPrecision(4));
  }
}

/// Snapshot of locally stored app preferences.
class AppSettings {
  const AppSettings({
    this.currencyCode = 'USD',
    this.currencySymbol = '\$',
    this.themeMode = ThemeMode.light,
    this.useDynamicColor = false,
    this.biometricEnabled = false,
    this.lastDriveBackupAt,
    this.lastLocalExportAt,
    this.googleClientId,
  });

  final String currencyCode;
  final String currencySymbol;
  final ThemeMode themeMode;
  final bool useDynamicColor;
  final bool biometricEnabled;
  final DateTime? lastDriveBackupAt;
  final DateTime? lastLocalExportAt;
  final String? googleClientId;

  AppSettings copyWith({
    String? currencyCode,
    String? currencySymbol,
    ThemeMode? themeMode,
    bool? useDynamicColor,
    bool? biometricEnabled,
    DateTime? lastDriveBackupAt,
    DateTime? lastLocalExportAt,
    String? googleClientId,
    bool clearGoogleClientId = false,
  }) {
    return AppSettings(
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      themeMode: themeMode ?? this.themeMode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      lastDriveBackupAt: lastDriveBackupAt ?? this.lastDriveBackupAt,
      lastLocalExportAt: lastLocalExportAt ?? this.lastLocalExportAt,
      googleClientId:
          clearGoogleClientId ? null : (googleClientId ?? this.googleClientId),
    );
  }
}

/// Persists currency, theme, biometric lock preference, and sync timestamps strictly locally.
class PreferencesService {
  static const String _keyCurrencyCode = 'mm_currency_code';
  static const String _keyCurrencySymbol = 'mm_currency_symbol';
  static const String _keyThemeMode = 'mm_theme_mode';
  static const String _keyDynamicColor = 'mm_dynamic_color';
  static const String _keyBiometric = 'mm_biometric';
  static const String _keyLastDriveBackup = 'mm_last_drive_backup';
  static const String _keyLastLocalExport = 'mm_last_local_export';
  static const String _keyGoogleClientId = 'mm_google_client_id';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyThemeMode);
    final themeMode = switch (themeIndex) {
      0 => ThemeMode.system,
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.light,
    };

    return AppSettings(
      currencyCode: prefs.getString(_keyCurrencyCode) ?? 'USD',
      currencySymbol: prefs.getString(_keyCurrencySymbol) ?? '\$',
      themeMode: themeMode,
      useDynamicColor: prefs.getBool(_keyDynamicColor) ?? false,
      biometricEnabled: prefs.getBool(_keyBiometric) ?? false,
      lastDriveBackupAt: DateTime.tryParse(
        prefs.getString(_keyLastDriveBackup) ?? '',
      ),
      lastLocalExportAt: DateTime.tryParse(
        prefs.getString(_keyLastLocalExport) ?? '',
      ),
      googleClientId: prefs.getString(_keyGoogleClientId),
    );
  }

  Future<void> saveCurrency(String code, String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrencyCode, code);
    await prefs.setString(_keyCurrencySymbol, symbol);
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final index = switch (mode) {
      ThemeMode.system => 0,
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
    };
    await prefs.setInt(_keyThemeMode, index);
  }

  Future<void> saveUseDynamicColor(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDynamicColor, value);
  }

  Future<void> saveBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometric, value);
  }

  Future<void> saveLastDriveBackup(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastDriveBackup, timestamp.toIso8601String());
  }

  Future<void> saveLastLocalExport(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastLocalExport, timestamp.toIso8601String());
  }

  Future<void> saveGoogleClientId(String? clientId) async {
    final prefs = await SharedPreferences.getInstance();
    if (clientId == null || clientId.trim().isEmpty) {
      await prefs.remove(_keyGoogleClientId);
    } else {
      await prefs.setString(_keyGoogleClientId, clientId.trim());
    }
  }
}
