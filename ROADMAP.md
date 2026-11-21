# Money Manager — Product Roadmap

## Shipped (`v1.0.0` · Commit `56db19c`)
- **100% Local-First Offline Storage:** SQLite database (`sqflite` / `sqflite_common_ffi` + web fallback) with zero background network calls.
- **On-Demand Google Drive Backup & Local Export:** Manual `Save to Drive` / `Restore` (`MoneyManagerBackups/`) plus offline JSON backup, transactions CSV, and OS share sheet.
- **Minimalist Themes & Dock:** Warm Alabaster light mode, 100% Pitch-Black OLED dark mode (`#000000`), and centered floating capsule pill dock (`Overview | Wallets | + | Budgets | Reports`) with top-bar Backup, Theme, and Biometric Lock controls.
- **Offline Foreign Currency Wallets:** Per-wallet currency codes, editable offline exchange rates, cross-currency transfers, and automatic base-currency aggregation across budgets and reports.
- **YTD & 6-Month Cashflow Analytics:** Category donut breakdown, switchable YTD / 6-Month bar charts, month-by-month YTD table, and **Export YTD CSV**.

---

## Active Mockup Batch (Features 1, 3, 6)
Queued for review in the interactive HTML mockups before Flutter implementation:
1. **Privacy Mode (Feature 1):** Header eye icon to mask all balances and monetary figures as `••••` when using the app in public.
2. **Savings Goals / Sinking Funds (Feature 3):** Target amounts, target dates, progress bars, `+ New Goal` creation, and quick `+ $100` contribution pills in **Budgets**.
3. **Net Worth Trend & Credit Card Due Dates (Feature 6):** Jan–Nov Net Worth line/area curve in **Reports** plus statement & payment due-date tracking on `Card` wallets.

---

## Future Development Backlog (Deferred)
Saved for future iterations after Features 1, 3, and 6:
- **Inline Math Calculator & Quick Entry Templates:** Evaluate expressions like `45 + 12.50` or `80 / 3` directly in the Amount field and trigger 1-tap frequent expense templates.
- **Tags & Trip Grouping:** Lightweight hashtags (e.g., `#lisbon-trip`, `#tax`, `#reimbursable`) for cross-category filtering and totals.
- **IOUs / Split-with-Friends Ledger:** Simple *Owed to Me / I Owe* tracker with a 1-tap **Settle** action that logs repayments into a wallet.
- **Local Receipt Photo Attachments:** On-device compressed receipt photos linked to transactions for warranties and reimbursements.
- **Encrypted Cloud Backups:** Optional client-side passphrase encryption before writing JSON backups to Google Drive.
- **CSV Bank Statement Importer:** Offline bank CSV import with column mapping and duplicate skipping.
