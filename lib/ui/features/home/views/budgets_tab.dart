import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain/models/budget.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/recurring_transaction.dart';
import '../../../../domain/models/transaction_item.dart';
import '../../../core/app_theme.dart';
import '../view_models/app_view_model.dart';

/// Monthly Category Budgets & Recurring Bills tab.
class BudgetsTab extends StatelessWidget {
  const BudgetsTab({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final symbol = viewModel.settings.currencySymbol;
    final budgets = viewModel.monthlyBudgets;
    final recurring = viewModel.recurringTransactions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: <Widget>[
        // Month Switcher Header
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
        const SizedBox(height: 16),

        // Monthly Category Budgets Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Monthly Budgets',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showSetBudgetDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Set Budget'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (budgets.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No monthly category limits set for ${AppFormatters.monthYear(viewModel.selectedMonth)}. Tap "Set Budget" to track spending targets.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.mutedText,
                ),
              ),
            ),
          )
        else
          for (final item in budgets) ...<Widget>[
            _BudgetCard(
              progress: item,
              symbol: symbol,
              onTap: () => _showSetBudgetDialog(context, existing: item.budget),
              onDelete: () => viewModel.deleteBudget(item.budget.id),
            ),
            const SizedBox(height: 10),
          ],

        const SizedBox(height: 20),

        // Recurring Bills & Scheduled Transactions Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Recurring Bills & Income',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showRecurringDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Rule'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recurring.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No recurring bills or scheduled entries yet. Add rent, subscriptions, or salary to auto-log locally on launch.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.mutedText,
                ),
              ),
            ),
          )
        else
          for (final rule in recurring) ...<Widget>[
            _RecurringRuleCard(
              rule: rule,
              viewModel: viewModel,
              symbol: symbol,
              onEdit: () => _showRecurringDialog(context, existing: rule),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Future<void> _showSetBudgetDialog(
    BuildContext context, {
    Budget? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _BudgetEditorDialog(
        viewModel: viewModel,
        existing: existing,
      ),
    );
  }

  Future<void> _showRecurringDialog(
    BuildContext context, {
    RecurringTransaction? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _RecurringEditorDialog(
        viewModel: viewModel,
        existing: existing,
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.progress,
    required this.symbol,
    required this.onTap,
    required this.onDelete,
  });

  final BudgetProgress progress;
  final String symbol;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;

    final Color barColor;
    final String statusText;
    if (progress.isOverBudget) {
      barColor = colors.expense;
      statusText =
          'Over by ${AppFormatters.money(progress.spentAmount - progress.budget.limitAmount, symbol)}';
    } else if (progress.isWarning) {
      barColor = colors.warning;
      statusText =
          '${AppFormatters.money(progress.remainingAmount, symbol)} left';
    } else {
      barColor = colors.income;
      statusText =
          '${AppFormatters.money(progress.remainingAmount, symbol)} left';
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: progress.category.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      progress.category.icon,
                      color: progress.category.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          progress.category.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          statusText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: progress.isOverBudget
                                ? colors.expense
                                : colors.mutedText,
                            fontWeight: progress.isOverBudget
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${AppFormatters.money(progress.spentAmount, symbol)} / ${AppFormatters.money(progress.budget.limitAmount, symbol)}',
                    style: AppTheme.tabular(
                      theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: 'Remove Budget',
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clampedRatio,
                  minHeight: 6,
                  backgroundColor: barColor.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurringRuleCard extends StatelessWidget {
  const _RecurringRuleCard({
    required this.rule,
    required this.viewModel,
    required this.symbol,
    required this.onEdit,
  });

  final RecurringTransaction rule;
  final AppViewModel viewModel;
  final String symbol;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final category = viewModel.categoryById(rule.categoryId);
    final account = viewModel.accountById(rule.accountId);
    final isIncome = rule.type == TransactionType.income;
    final amountColor = isIncome ? colors.income : colors.expense;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (category?.color ?? amountColor)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category?.icon ?? Icons.repeat_rounded,
                      color: category?.color ?? amountColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          rule.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${rule.frequency.label} • ${account?.name ?? 'Wallet'} • Next: ${AppFormatters.dateShort(rule.nextDueDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    AppFormatters.money(
                      rule.amount,
                      symbol,
                      showPlusSign: isIncome,
                      showMinusSign: !isIncome,
                    ),
                    style: AppTheme.tabular(
                      theme.textTheme.titleMedium?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        rule.autoLog
                            ? Icons.check_circle_outline_rounded
                            : Icons.notifications_none_rounded,
                        size: 16,
                        color: colors.mutedText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        rule.autoLog ? 'Auto-logs on due date' : 'Manual reminder',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.mutedText,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () async {
                      await viewModel.logRecurringNow(rule);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Logged "${rule.title}" today.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Log Now'),
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

class _BudgetEditorDialog extends StatefulWidget {
  const _BudgetEditorDialog({
    required this.viewModel,
    this.existing,
  });

  final AppViewModel viewModel;
  final Budget? existing;

  @override
  State<_BudgetEditorDialog> createState() => _BudgetEditorDialogState();
}

class _BudgetEditorDialogState extends State<_BudgetEditorDialog> {
  late String _categoryId;
  late TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    final expenseCats = widget.viewModel.expenseCategories;
    _categoryId = widget.existing?.categoryId ??
        (expenseCats.isNotEmpty ? expenseCats.first.id : '');
    _limitController = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.limitAmount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseCats = widget.viewModel.expenseCategories;
    return AlertDialog(
      title: Text(
        'Budget (${AppFormatters.monthYear(widget.viewModel.selectedMonth)})',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (expenseCats.isEmpty)
            const Text('Create an expense category first.')
          else
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Expense Category'),
              items: expenseCats
                  .map(
                    (CategoryItem c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  )
                  .toList(),
              onChanged: widget.existing == null
                  ? (val) {
                      if (val != null) setState(() => _categoryId = val);
                    }
                  : null,
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _limitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Monthly Limit',
              prefixText: '${widget.viewModel.settings.currencySymbol} ',
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final limit = double.tryParse(_limitController.text.trim());
            if (limit == null || limit <= 0 || _categoryId.isEmpty) return;
            await widget.viewModel.saveMonthlyBudget(
              categoryId: _categoryId,
              limitAmount: limit,
            );
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _RecurringEditorDialog extends StatefulWidget {
  const _RecurringEditorDialog({
    required this.viewModel,
    this.existing,
  });

  final AppViewModel viewModel;
  final RecurringTransaction? existing;

  @override
  State<_RecurringEditorDialog> createState() => _RecurringEditorDialogState();
}

class _RecurringEditorDialogState extends State<_RecurringEditorDialog> {
  static const Uuid _uuid = Uuid();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TransactionType _type;
  late String _accountId;
  late String _categoryId;
  late RecurrenceFrequency _frequency;
  late DateTime _nextDueDate;
  late bool _autoLog;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(2) : '',
    );
    _type = e?.type ?? TransactionType.expense;
    _accountId = e?.accountId ??
        (widget.viewModel.accounts.isNotEmpty
            ? widget.viewModel.accounts.first.id
            : '');
    _categoryId = e?.categoryId ?? _defaultCategoryId(_type);
    _frequency = e?.frequency ?? RecurrenceFrequency.monthly;
    _nextDueDate = e?.nextDueDate ?? DateTime.now();
    _autoLog = e?.autoLog ?? true;
  }

  String _defaultCategoryId(TransactionType type) {
    final list = type == TransactionType.income
        ? widget.viewModel.incomeCategories
        : widget.viewModel.expenseCategories;
    return list.isNotEmpty ? list.first.id : '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = _type == TransactionType.income
        ? widget.viewModel.incomeCategories
        : widget.viewModel.expenseCategories;
    if (cats.isNotEmpty && !cats.any((c) => c.id == _categoryId)) {
      _categoryId = cats.first.id;
    }

    return AlertDialog(
      title: Text(
        widget.existing == null ? 'New Recurring Rule' : 'Edit Recurring Rule',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SegmentedButton<TransactionType>(
              segments: const <ButtonSegment<TransactionType>>[
                ButtonSegment<TransactionType>(
                  value: TransactionType.expense,
                  label: Text('Bill / Expense'),
                ),
                ButtonSegment<TransactionType>(
                  value: TransactionType.income,
                  label: Text('Income'),
                ),
              ],
              selected: <TransactionType>{_type},
              onSelectionChanged: (set) {
                setState(() {
                  _type = set.first;
                  _categoryId = _defaultCategoryId(_type);
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Apartment Rent, Salary',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${widget.viewModel.settings.currencySymbol} ',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: 'Wallet'),
              items: widget.viewModel.accounts
                  .map((a) => DropdownMenuItem<String>(
                        value: a.id,
                        child: Text(a.name),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _accountId = val);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: cats
                  .map((c) => DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _categoryId = val);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RecurrenceFrequency>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: RecurrenceFrequency.values
                  .map((f) => DropdownMenuItem<RecurrenceFrequency>(
                        value: f,
                        child: Text(f.label),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _frequency = val);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _nextDueDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _nextDueDate = picked);
                }
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text('Next Due: ${AppFormatters.dateShort(_nextDueDate)}'),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-log when due'),
              subtitle: const Text('Creates local entry on launch'),
              value: _autoLog,
              onChanged: (val) => setState(() => _autoLog = val),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        if (widget.existing != null)
          TextButton(
            onPressed: () async {
              await widget.viewModel
                  .deleteRecurringTransaction(widget.existing!.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: context.moneyColors.expense),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final title = _titleController.text.trim();
            final amount = double.tryParse(_amountController.text.trim());
            if (title.isEmpty ||
                amount == null ||
                amount <= 0 ||
                _accountId.isEmpty ||
                _categoryId.isEmpty) {
              return;
            }
            final rule = RecurringTransaction(
              id: widget.existing?.id ?? _uuid.v4(),
              title: title,
              type: _type,
              amount: amount,
              accountId: _accountId,
              categoryId: _categoryId,
              frequency: _frequency,
              nextDueDate: _nextDueDate,
              autoLog: _autoLog,
              isActive: true,
            );
            await widget.viewModel.saveRecurringTransaction(rule);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
