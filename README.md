# Money Manager (`v1.0.0`)

A minimalist, **100% local-first** personal finance manager built with Flutter for **Android**, **iOS**, and **Offline-First Web PWA**. All accounts, transactions, budgets, and recurring rules live locally on your device in SQLite (with browser `localStorage` fallback on Web) and connect to the internet strictly on demand when you manually back up or restore to your own visible `MoneyManagerBackups` Google Drive folder.

---

## Key Features (`v1.0.0`)

- **Local-First Privacy:** Zero background sync, zero telemetry, and `android:allowBackup="false"`.
- **On-Demand Backup & Exports:** Save/Restore a human-readable JSON snapshot to Google Drive (`drive.file` scope), share via the OS Share Sheet, export/import local `.json` backups, export transactions `.csv`, or export **YTD Cashflow CSV**.
- **Offline Foreign Currency Wallets:** Assign custom currencies to any wallet with editable offline exchange rates, automatic base-currency aggregation across Net Worth, Budgets, and Reports, and cross-currency transfers.
- **Monthly Budgets & Recurring Rules:** Category limits with 80% warning and 100% over-budget tracking, plus automatic catch-up logging for Daily, Weekly, Monthly, and Yearly recurring rules on startup.
- **Reports & Analytics:** Category spending donut chart, YTD Income/Expense/Net summary, switchable **YTD Cashflow** / **6-Month Cashflow** bar charts, and month-by-month YTD breakdown.
- **Eye-Friendly Minimalist Themes & Centered Dock:** Warm Alabaster light mode (`#FAF9F6`), 100% Pitch-Black OLED dark mode (`#000000`), tabular numerals, and a symmetric floating pill dock (`Overview | Wallets | + | Budgets | Reports`) with top-bar Backup, Theme, and optional Biometric Lock controls (`local_auth`).

---

## Quickstart

```powershell
# Install dependencies
flutter pub get

# Verify static analysis and automated test suite (7 tests)
flutter analyze
flutter test

# Run on a connected Android emulator / device
flutter run
```

To build release deliverables:

```powershell
flutter build apk --release
flutter build web --pwa-strategy=offline-first
```

---

## Technical Documentation

- **[Technical Specification](docs/TECHNICAL_SPEC.md)** — MVVM architecture, class/module map, domain algorithms (FX math, budgets, recurring rules, YTD analytics), biometric & Drive security flows, design tokens, dependencies, and test suite.
- **[Data & Backup Schema Reference](docs/DATA_AND_BACKUP_SCHEMA.md)** — SQLite v2 DDL & migrations, `SharedPreferences` keys, `BackupPayload` JSON contract, and CSV schemas.
- **[Build & Deployment Guide](docs/BUILD_AND_DEPLOYMENT.md)** — Android Studio setup, AVD tuning, release builds (APK/AAB/PWA/IPA), signing checklist, Google OAuth setup, and GitHub Actions CI/CD.
- **[Product Roadmap](ROADMAP.md)** — Shipped baseline, active mockup features (Privacy Mode, Savings Goals, Net Worth Trend & Credit Card Due Dates), and deferred backlog.
