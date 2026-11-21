# Money Manager — Data & Backup Schema Reference

This document specifies the local SQLite database schema (`_dbVersion = 2`), key-value `SharedPreferences` storage keys, the versioned JSON backup contract (`BackupPayload`), and CSV export formats implemented in `lib/data/services/` and `lib/domain/models/`.

---

## 1. SQLite Database Schema (`money_manager.db`)

Managed by `DatabaseService` (`lib/data/services/database_service.dart`). Current database version: **`2`**.

### Tables DDL

```sql
CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,              -- 'cash' | 'bank' | 'card' | 'savings' | 'other'
  initial_balance REAL NOT NULL,
  color_value INTEGER NOT NULL,    -- 32-bit ARGB integer
  icon_code_point INTEGER NOT NULL,
  created_at TEXT NOT NULL,        -- ISO 8601 timestamp
  currency_code TEXT,              -- NULL implies app base currency
  currency_symbol TEXT,            -- NULL implies app base symbol
  exchange_rate REAL NOT NULL DEFAULT 1.0 -- 1 unit of wallet currency in base currency
);

CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,              -- 'income' | 'expense'
  color_value INTEGER NOT NULL,
  icon_code_point INTEGER NOT NULL,
  is_default INTEGER NOT NULL      -- 1 = built-in default, 0 = user-created
);

CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,              -- 'income' | 'expense' | 'transfer'
  amount REAL NOT NULL,            -- stored in source wallet's native currency
  account_id TEXT NOT NULL,
  to_account_id TEXT,              -- populated only for 'transfer'
  category_id TEXT,                -- NULL for 'transfer'
  date TEXT NOT NULL,              -- ISO 8601 timestamp
  note TEXT NOT NULL,
  recurring_rule_id TEXT           -- NULL unless auto/manually logged from a rule
);

CREATE INDEX idx_tx_date ON transactions(date);
CREATE INDEX idx_tx_account ON transactions(account_id);
CREATE INDEX idx_tx_category ON transactions(category_id);

CREATE TABLE budgets (
  id TEXT PRIMARY KEY,
  category_id TEXT NOT NULL,
  year_month TEXT NOT NULL,        -- 'YYYY-MM', e.g. '2026-11'
  limit_amount REAL NOT NULL,      -- expressed in app base currency
  UNIQUE(category_id, year_month)
);

CREATE TABLE recurring_transactions (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  type TEXT NOT NULL,              -- 'income' | 'expense'
  amount REAL NOT NULL,            -- expressed in source wallet's native currency
  account_id TEXT NOT NULL,
  category_id TEXT NOT NULL,
  frequency TEXT NOT NULL,         -- 'daily' | 'weekly' | 'monthly' | 'yearly'
  next_due_date TEXT NOT NULL,     -- ISO 8601 timestamp
  auto_log INTEGER NOT NULL,       -- 1 = auto-log on startup, 0 = manual reminder
  is_active INTEGER NOT NULL,      -- 1 = active, 0 = paused
  note TEXT NOT NULL
);
```

### Schema Migrations (`onUpgrade`)

- **v1 → v2 (Foreign Currency Wallet Support):**
  ```sql
  ALTER TABLE accounts ADD COLUMN currency_code TEXT;
  ALTER TABLE accounts ADD COLUMN currency_symbol TEXT;
  ALTER TABLE accounts ADD COLUMN exchange_rate REAL NOT NULL DEFAULT 1.0;
  ```

---

## 2. `SharedPreferences` Keys

### App Settings (`PreferencesService`)

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `mm_currency_code` | `String` | `'USD'` | Active base currency ISO code |
| `mm_currency_symbol` | `String` | `'$'` | Active base currency symbol |
| `mm_theme_mode` | `int` | `1` (`light`) | `0` = `ThemeMode.system`, `1` = `light`, `2` = `dark` |
| `mm_dynamic_color` | `bool` | `false` | Enables Android 12+ `DynamicColorBuilder` |
| `mm_biometric` | `bool` | `false` | Enables biometric lock on launch & resume |
| `mm_last_drive_backup` | `String?` | `null` | ISO 8601 timestamp of last Google Drive upload |
| `mm_last_local_export` | `String?` | `null` | ISO 8601 timestamp of last JSON export/share |
| `mm_google_client_id` | `String?` | `null` | Optional custom OAuth Client ID for `GoogleSignIn` |

### Web PWA Key-Value Fallback (`DatabaseService`, when `kIsWeb == true`)

| Key | Type | Contents |
| :--- | :--- | :--- |
| `mm_kv_seeded` | `bool` | Whether default wallets & categories have been initialized |
| `mm_kv_accounts` | `String` (JSON array) | Serialized `Account.toJson()` list |
| `mm_kv_categories` | `String` (JSON array) | Serialized `CategoryItem.toJson()` list |
| `mm_kv_transactions` | `String` (JSON array) | Serialized `TransactionItem.toJson()` list |
| `mm_kv_budgets` | `String` (JSON array) | Serialized `Budget.toJson()` list |
| `mm_kv_recurring` | `String` (JSON array) | Serialized `RecurringTransaction.toJson()` list |

---

## 3. JSON Backup Contract (`BackupPayload`)

Defined in `lib/domain/models/backup_payload.dart`. Used identically for:
1. Local device export (`money_manager_backup_YYYY-MM-DD.json`).
2. OS Share Sheet export.
3. On-demand Google Drive uploads inside the `MoneyManagerBackups` folder:
   - `money_manager_backup_latest.json` (overwritten on each backup)
   - `money_manager_backup_YYYY-MM-DD.json` (dated daily snapshot)

### Structure & Validation Rules

- `BackupPayload.fromJsonString` parses the file with `jsonDecode` and requires a JSON object (`Map<String, dynamic>`) containing both `"accounts"` and `"transactions"` keys; otherwise it throws `FormatException`.
- Missing optional keys (`categories`, `budgets`, `recurringTransactions`, `schemaVersion`, `currencyCode`, `currencySymbol`, `exportedAt`) fall back to safe defaults (`[]`, `1`, `'USD'`, `'$'`, `DateTime.now()`).
- Each entity model's `fromMap` accepts both `camelCase` JSON keys (from `toJson()`) and `snake_case` column keys (from SQLite).
- On restore, `DatabaseService.restoreAllData` executes an atomic SQLite transaction deleting existing rows across all 5 tables before inserting the restored payload.

### Example Payload (`schemaVersion: 1`)

```json
{
  "schemaVersion": 1,
  "app": "MoneyManagerOffline",
  "exportedAt": "2026-11-20T18:00:00.000Z",
  "currencyCode": "USD",
  "currencySymbol": "$",
  "accounts": [
    {
      "id": "acc_bank",
      "name": "Main Bank",
      "type": "bank",
      "initialBalance": 1500.0,
      "colorValue": 4282018716,
      "iconCodePoint": 57408,
      "createdAt": "2026-11-01T08:00:00.000",
      "currencyCode": null,
      "currencySymbol": null,
      "exchangeRateToBase": 1.0
    },
    {
      "id": "acc_eur",
      "name": "Euro Travel",
      "type": "savings",
      "initialBalance": 400.0,
      "colorValue": 4281166427,
      "iconCodePoint": 62261,
      "createdAt": "2026-11-01T08:05:00.000",
      "currencyCode": "EUR",
      "currencySymbol": "€",
      "exchangeRateToBase": 1.08
    }
  ],
  "categories": [
    {
      "id": "cat_food",
      "name": "Food & Dining",
      "type": "expense",
      "colorValue": 4291128147,
      "iconCodePoint": 58674,
      "isDefault": true
    }
  ],
  "transactions": [
    {
      "id": "tx_1",
      "type": "expense",
      "amount": 45.0,
      "accountId": "acc_eur",
      "toAccountId": null,
      "categoryId": "cat_food",
      "date": "2026-11-20T12:30:00.000",
      "note": "Cafe in Lisbon",
      "recurringRuleId": null
    }
  ],
  "budgets": [
    {
      "id": "bud_food",
      "categoryId": "cat_food",
      "yearMonth": "2026-11",
      "limitAmount": 300.0
    }
  ],
  "recurringTransactions": [
    {
      "id": "rec_rent",
      "title": "Apartment Rent",
      "type": "expense",
      "amount": 950.0,
      "accountId": "acc_bank",
      "categoryId": "cat_housing",
      "frequency": "monthly",
      "nextDueDate": "2026-12-01T00:00:00.000",
      "autoLog": true,
      "isActive": true,
      "note": ""
    }
  ]
}
```

---

## 4. CSV Export Formats

Implemented in `LocalExportService` (`lib/data/services/local_export_service.dart`). Strings containing commas, quotes, or newlines are wrapped in double quotes with internal quotes escaped as `""`.

### 4.1 Transactions Export (`money_manager_transactions_YYYY-MM-DD.csv`)

Generated by `saveTransactionsCsvToDevice(...)`:
- **Columns:** `Date,Type,Amount,Currency,Account,ToAccount,Category,Note`
- `Date`: ISO 8601 timestamp (`tx.date.toIso8601String()`).
- `Type`: `Income`, `Expense`, or `Transfer`.
- `Amount`: Two-decimal fixed string in transaction wallet's amount (`tx.amount.toStringAsFixed(2)`).
- `Currency`: App base currency code passed from `AppSettings.currencyCode`.
- `Account` / `ToAccount` / `Category`: Human-readable names resolved by ID (falling back to ID if deleted).

### 4.2 YTD Cashflow Export (`money_manager_ytd_cashflow_<year>_YYYY-MM-DD.csv`)

Generated by `saveYtdCashflowCsvToDevice(...)` from **Reports → Export YTD CSV**:
- **Columns:** `Month,Income,Expense,Net,Currency`
- **Rows:** One row per month from `Jan <year>` through the currently selected month in `ReportsTab` (all amounts pre-converted to app base currency), followed by a summary row `YTD Total,<sumIncome>,<sumExpense>,<net>,<currencyCode>`.
