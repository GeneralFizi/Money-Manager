import 'package:material_ui/material_ui.dart';

import '../../../../domain/models/transaction_item.dart';
import '../../../core/app_theme.dart';
import '../view_models/app_view_model.dart';
import 'transaction_form_sheet.dart';

/// Overview & Transactions tab featuring eye-friendly summary cards, filters, and daily groups.
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final symbol = viewModel.settings.currencySymbol;
    final filtered = viewModel.filteredMonthlyTransactions;

    // Group filtered transactions by calendar day.
    final grouped = <DateTime, List<TransactionItem>>{};
    for (final tx in filtered) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(day, () => <TransactionItem>[]).add(tx);
    }
    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: <Widget>[
        _NetBalanceHeroCard(viewModel: viewModel, symbol: symbol),
        const SizedBox(height: 12),
        _SearchBar(onChanged: viewModel.setSearchQuery),
        const SizedBox(height: 10),
        _FilterChipsRow(viewModel: viewModel),
        const SizedBox(height: 14),
        if (sortedDays.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 32,
                    color: colors.mutedText,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No transactions for ${AppFormatters.monthYear(viewModel.selectedMonth)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + Add below to log an income, expense, or transfer offline.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.mutedText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          for (final day in sortedDays) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6, bottom: 6),
              child: Text(
                AppFormatters.dayHeader(day),
                style: TextStyle(
                  fontSize: 12,
                  color: colors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < grouped[day]!.length; i++) ...<Widget>[
                    if (i > 0) const Divider(height: 1),
                    _TransactionTile(
                      tx: grouped[day]![i],
                      viewModel: viewModel,
                      symbol: symbol,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _NetBalanceHeroCard extends StatelessWidget {
  const _NetBalanceHeroCard({
    required this.viewModel,
    required this.symbol,
  });

  final AppViewModel viewModel;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Total Balance',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                MinimalMonthSwitcher(
                  month: viewModel.selectedMonth,
                  onChangeMonth: viewModel.changeMonth,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppFormatters.money(viewModel.totalNetBalance, symbol),
              style: AppTheme.tabular(
                theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const Divider(height: 22),
            Row(
              children: <Widget>[
                _InlineMetric(
                  label: 'In',
                  amount: AppFormatters.money(
                    viewModel.monthlyIncome,
                    symbol,
                    showPlusSign: true,
                  ),
                  color: colors.income,
                ),
                Container(
                  height: 14,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: colors.cardBorder,
                ),
                _InlineMetric(
                  label: 'Out',
                  amount: AppFormatters.money(viewModel.monthlyExpense, symbol),
                  color: colors.expense,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 12,
            color: colors.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: AppTheme.tabular(
            TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyColors;
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search notes, categories, or wallets...',
        hintStyle: TextStyle(fontSize: 13, color: colors.mutedText),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: colors.mutedText,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 36),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({required this.viewModel});

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final type in TransactionType.values) ...<Widget>[
            MinimalPill(
              label: type.label,
              selected: viewModel.selectedTypeFilter == type,
              onTap: () => viewModel.setTypeFilter(type),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            const SizedBox(width: 6),
          ],
          for (final acc in viewModel.accounts) ...<Widget>[
            MinimalPill(
              label: acc.name,
              selected: viewModel.selectedAccountFilterId == acc.id,
              onTap: () => viewModel.setAccountFilter(acc.id),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.tx,
    required this.viewModel,
    required this.symbol,
  });

  final TransactionItem tx;
  final AppViewModel viewModel;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final baseCode = viewModel.settings.currencyCode;
    final fromAccount = viewModel.accountById(tx.accountId);
    final toAccount = viewModel.accountById(tx.toAccountId);
    final category = viewModel.categoryById(tx.categoryId);
    final nativeSymbol =
        fromAccount?.effectiveCurrencySymbol(symbol) ?? symbol;
    final isForeign = fromAccount?.isForeignCurrency(baseCode) ?? false;

    final Color accentColor;
    final String title;
    final String subtitle;
    final String amountText;

    switch (tx.type) {
      case TransactionType.income:
        accentColor = colors.income;
        title = category?.name ?? 'Income';
        subtitle = [
          fromAccount?.name ?? 'Wallet',
          if (tx.note.isNotEmpty) tx.note,
        ].join(' · ');
        amountText =
            AppFormatters.money(tx.amount, nativeSymbol, showPlusSign: true);
      case TransactionType.expense:
        accentColor = colors.expense;
        title = category?.name ?? 'Expense';
        subtitle = [
          fromAccount?.name ?? 'Wallet',
          if (tx.note.isNotEmpty) tx.note,
        ].join(' · ');
        amountText =
            AppFormatters.money(tx.amount, nativeSymbol, showMinusSign: true);
      case TransactionType.transfer:
        accentColor = colors.transfer;
        title = 'Wallet Transfer';
        final route =
            '${fromAccount?.name ?? 'Wallet'} → ${toAccount?.name ?? 'Wallet'}';
        subtitle = tx.note.isNotEmpty ? '$route · ${tx.note}' : route;
        amountText = AppFormatters.money(tx.amount, nativeSymbol);
    }

    return Dismissible(
      key: ValueKey<String>(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colors.expense.withValues(alpha: 0.14),
        child: Icon(Icons.delete_outline_rounded, color: colors.expense),
      ),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        await viewModel.deleteTransaction(tx.id);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Deleted "$title"'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => viewModel.saveTransaction(tx),
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => TransactionFormSheet(
            viewModel: viewModel,
            existing: tx,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colors.mutedText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    amountText,
                    style: AppTheme.tabular(
                      TextStyle(
                        fontSize: 13.5,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isForeign)
                    Text(
                      '≈ ${AppFormatters.money(viewModel.amountInBase(tx), symbol)}',
                      style: AppTheme.tabular(
                        TextStyle(fontSize: 11, color: colors.mutedText),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
