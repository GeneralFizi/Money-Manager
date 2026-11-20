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
        // Monthly Category Budgets Header
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Monthly Budgets',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.mutedText,
                ),
              ),
            ),
            MinimalMonthSwitcher(
              month: viewModel.selectedMonth,
              onChangeMonth: viewModel.changeMonth,
            ),
            const SizedBox(width: 6),
            MinimalPill(
              label: '+ Set Budget',
              onTap: () => _showSetBudgetDialog(context),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (budgets.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No monthly category limits set for ${AppFormatters.monthYear(viewModel.selectedMonth)}. Tap "+ Set Budget" to track spending targets.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.mutedText,
                ),
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < budgets.length; i++) ...<Widget>[
                  if (i > 0) const Divider(height: 1),
                  _BudgetRow(
                    progress: budgets[i],
                    symbol: symbol,
                    onTap: () => _showSetBudgetDialog(
                      context,
                      existing: budgets[i].budget,
                    ),
                    onDelete: () => viewModel.deleteBudget(budgets[i].budget.id),
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Recurring Bills & Scheduled Transactions Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Recurring Bills & Income',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.mutedText,
              ),
            ),
            MinimalPill(
              label: '+ Add Rule',
              onTap: () => _showRecurringDialog(context),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
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
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.mutedText,
                ),
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < recurring.length; i++) ...<Widget>[
                  if (i > 0) const Divider(height: 1),
                  _RecurringRuleRow(
                    rule: recurring[i],
                    viewModel: viewModel,
                    symbol: symbol,
                    onEdit: () => _showRecurringDialog(
                      context,
                      existing: recurring[i],
                    ),
                  ),
                ],
              ],
            ),
          ),
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

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
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
    final barColor =
        progress.isOverBudget ? colors.expense : theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    progress.category.name,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${AppFormatters.money(progress.spentAmount, symbol)} / ${AppFormatters.money(progress.budget.limitAmount, symbol)}',
                  style: AppTheme.tabular(
                    TextStyle(
                      fontSize: 12,
                      color: progress.isOverBudget
                          ? colors.expense
                          : colors.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkResponse(
                  onTap: onDelete,
                  radius: 14,
                  child: Tooltip(
                    message: 'Remove Budget',
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: colors.mutedText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clampedRatio,
                minHeight: 6,
                backgroundColor: colors.softTint,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringRuleRow extends StatelessWidget {
  const _RecurringRuleRow({
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
    final colors = context.moneyColors;
    final account = viewModel.accountById(rule.accountId);
    final isIncome = rule.type == TransactionType.income;
    final amountColor = isIncome ? colors.income : colors.expense;

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    rule.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${rule.frequency.label} · ${account?.name ?? 'Wallet'} · Next ${AppFormatters.dateShort(rule.nextDueDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: colors.mutedText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  AppFormatters.money(
                    rule.amount,
                    symbol,
                    showPlusSign: isIncome,
                    showMinusSign: !isIncome,
                  ),
                  style: AppTheme.tabular(
                    TextStyle(
                      fontSize: 13.5,
                      color: amountColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () async {
                    await viewModel.logRecurringNow(rule);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Logged "${rule.title}" today.'),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      'Log now',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.mutedText,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
