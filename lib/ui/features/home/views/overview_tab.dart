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
        const SizedBox(height: 16),
        _MonthAndSearchBar(viewModel: viewModel),
        const SizedBox(height: 10),
        _FilterChipsRow(viewModel: viewModel),
        const SizedBox(height: 16),
        if (sortedDays.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 40,
                    color: colors.mutedText,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions for ${AppFormatters.monthYear(viewModel.selectedMonth)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap the + button below to log an income, expense, or wallet transfer offline.',
                    style: theme.textTheme.bodyMedium?.copyWith(
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
              padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
              child: Text(
                AppFormatters.dayHeader(day),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Card(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Total Balance',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  AppFormatters.monthYear(viewModel.selectedMonth),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.mutedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              AppFormatters.money(viewModel.totalNetBalance, symbol),
              style: AppTheme.tabular(
                theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const Divider(height: 24),
            Row(
              children: <Widget>[
                _InlineMetric(
                  label: 'In',
                  amount: AppFormatters.money(viewModel.monthlyIncome, symbol),
                  color: colors.income,
                ),
                Container(
                  height: 16,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
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
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$label ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: AppTheme.tabular(
            theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthAndSearchBar extends StatelessWidget {
  const _MonthAndSearchBar({required this.viewModel});

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton.outlined(
              onPressed: () => viewModel.changeMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Previous Month',
            ),
            Text(
              AppFormatters.monthYear(viewModel.selectedMonth),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton.outlined(
              onPressed: () => viewModel.changeMonth(1),
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Next Month',
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: viewModel.setSearchQuery,
          decoration: const InputDecoration(
            hintText: 'Search notes, categories, or wallets...',
            prefixIcon: Icon(Icons.search_rounded),
            isDense: true,
          ),
        ),
      ],
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
            FilterChip(
              label: Text(type.label),
              selected: viewModel.selectedTypeFilter == type,
              onSelected: (_) => viewModel.setTypeFilter(type),
            ),
            const SizedBox(width: 8),
          ],
          for (final acc in viewModel.accounts) ...<Widget>[
            FilterChip(
              avatar: Icon(acc.icon, size: 16),
              label: Text(acc.name),
              selected: viewModel.selectedAccountFilterId == acc.id,
              onSelected: (_) => viewModel.setAccountFilter(acc.id),
            ),
            const SizedBox(width: 8),
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
    final fromAccount = viewModel.accountById(tx.accountId);
    final toAccount = viewModel.accountById(tx.toAccountId);
    final category = viewModel.categoryById(tx.categoryId);

    final Color accentColor;
    final IconData badgeIcon;
    final String title;
    final String subtitle;
    final String amountText;

    switch (tx.type) {
      case TransactionType.income:
        accentColor = colors.income;
        badgeIcon = category?.icon ?? Icons.arrow_downward_rounded;
        title = category?.name ?? 'Income';
        subtitle = [
          fromAccount?.name ?? 'Wallet',
          if (tx.note.isNotEmpty) tx.note,
        ].join(' • ');
        amountText = AppFormatters.money(tx.amount, symbol, showPlusSign: true);
      case TransactionType.expense:
        accentColor = colors.expense;
        badgeIcon = category?.icon ?? Icons.arrow_upward_rounded;
        title = category?.name ?? 'Expense';
        subtitle = [
          fromAccount?.name ?? 'Wallet',
          if (tx.note.isNotEmpty) tx.note,
        ].join(' • ');
        amountText =
            AppFormatters.money(tx.amount, symbol, showMinusSign: true);
      case TransactionType.transfer:
        accentColor = colors.transfer;
        badgeIcon = Icons.swap_horiz_rounded;
        title = 'Wallet Transfer';
        final route =
            '${fromAccount?.name ?? 'Wallet'} → ${toAccount?.name ?? 'Wallet'}';
        subtitle = tx.note.isNotEmpty ? '$route • ${tx.note}' : route;
        amountText = AppFormatters.money(tx.amount, symbol);
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (category?.color ?? accentColor).withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            badgeIcon,
            color: category?.color ?? accentColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: colors.mutedText),
        ),
        trailing: Text(
          amountText,
          style: AppTheme.tabular(
            theme.textTheme.titleMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => TransactionFormSheet(
            viewModel: viewModel,
            existing: tx,
          ),
        ),
      ),
    );
  }
}
