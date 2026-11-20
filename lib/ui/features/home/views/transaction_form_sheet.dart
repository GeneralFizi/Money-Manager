import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain/models/category.dart';
import '../../../../domain/models/transaction_item.dart';
import '../../../core/app_theme.dart';
import '../view_models/app_view_model.dart';

/// Clean 3-tap bottom sheet to add or edit an Expense, Income, or Account Transfer.
class TransactionFormSheet extends StatefulWidget {
  const TransactionFormSheet({
    super.key,
    required this.viewModel,
    this.existing,
    this.initialType = TransactionType.expense,
  });

  final AppViewModel viewModel;
  final TransactionItem? existing;
  final TransactionType initialType;

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  static const Uuid _uuid = Uuid();

  late TransactionType _type;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late String _accountId;
  String? _toAccountId;
  String? _categoryId;
  late DateTime _date;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? widget.initialType;
    _amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: existing?.note ?? '');

    final accounts = widget.viewModel.accounts;
    _accountId = existing?.accountId ??
        (accounts.isNotEmpty ? accounts.first.id : '');
    _toAccountId = existing?.toAccountId ??
        (accounts.length > 1
            ? accounts.firstWhere((a) => a.id != _accountId).id
            : null);
    _categoryId = existing?.categoryId;
    _date = existing?.date ?? DateTime.now();
    _ensureValidCategory();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _ensureValidCategory() {
    if (_type == TransactionType.transfer) {
      _categoryId = null;
      return;
    }
    final list = _type == TransactionType.income
        ? widget.viewModel.incomeCategories
        : widget.viewModel.expenseCategories;
    if (list.isEmpty) {
      _categoryId = null;
    } else if (_categoryId == null || !list.any((c) => c.id == _categoryId)) {
      _categoryId = list.first.id;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed == null || parsed <= 0) {
      setState(() => _error = 'Please enter an amount greater than 0.');
      return;
    }
    if (_accountId.isEmpty) {
      setState(() => _error = 'Please create a wallet first.');
      return;
    }
    if (_type == TransactionType.transfer) {
      if (_toAccountId == null || _toAccountId == _accountId) {
        setState(() => _error = 'Select a different destination wallet.');
        return;
      }
    } else if (_categoryId == null) {
      setState(() => _error = 'Please choose a category.');
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    final item = TransactionItem(
      id: widget.existing?.id ?? _uuid.v4(),
      type: _type,
      amount: parsed,
      accountId: _accountId,
      toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
      categoryId: _type == TransactionType.transfer ? null : _categoryId,
      date: _date,
      note: _noteController.text.trim(),
      recurringRuleId: widget.existing?.recurringRuleId,
    );

    await widget.viewModel.saveTransaction(item);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final baseSymbol = widget.viewModel.settings.currencySymbol;
    final baseCode = widget.viewModel.settings.currencyCode;
    final selectedAccount = widget.viewModel.accountById(_accountId);
    final walletSymbol =
        selectedAccount?.effectiveCurrencySymbol(baseSymbol) ?? baseSymbol;
    final isForeign = selectedAccount?.isForeignCurrency(baseCode) ?? false;
    final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final convertedBase = selectedAccount != null
        ? selectedAccount.toBaseAmount(enteredAmount, baseCode)
        : enteredAmount;
    final accounts = widget.viewModel.accounts;
    final categories = _type == TransactionType.income
        ? widget.viewModel.incomeCategories
        : widget.viewModel.expenseCategories;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.cardBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existing == null ? 'New Entry' : 'Edit Entry',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<TransactionType>(
              segments: const <ButtonSegment<TransactionType>>[
                ButtonSegment<TransactionType>(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward_rounded, size: 18),
                ),
                ButtonSegment<TransactionType>(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward_rounded, size: 18),
                ),
                ButtonSegment<TransactionType>(
                  value: TransactionType.transfer,
                  label: Text('Transfer'),
                  icon: Icon(Icons.swap_horiz_rounded, size: 18),
                ),
              ],
              selected: <TransactionType>{_type},
              onSelectionChanged: (set) {
                setState(() {
                  _type = set.first;
                  _error = null;
                  _ensureValidCategory();
                });
              },
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountController,
              autofocus: widget.existing == null,
              onChanged: (_) => setState(() {}),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: AppTheme.tabular(
                theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '$walletSymbol ',
                hintText: '0.00',
              ),
            ),
            if (isForeign && selectedAccount != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                '≈ ${AppFormatters.money(convertedBase, baseSymbol)} ($baseCode at 1 ${selectedAccount.currencyCode} = ${selectedAccount.exchangeRateToBase} $baseCode)',
                style: AppTheme.tabular(
                  theme.textTheme.bodySmall?.copyWith(
                    color: colors.mutedText,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              _type == TransactionType.transfer ? 'From Wallet' : 'Wallet',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.mutedText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: accounts.map((acc) {
                final selected = acc.id == _accountId;
                return ChoiceChip(
                  avatar: Icon(acc.icon, size: 18),
                  label: Text(acc.name),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _accountId = acc.id;
                      if (_toAccountId == _accountId && accounts.length > 1) {
                        _toAccountId = accounts
                            .firstWhere((a) => a.id != _accountId)
                            .id;
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_type == TransactionType.transfer) ...<Widget>[
              Text(
                'To Wallet',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.mutedText,
                ),
              ),
              const SizedBox(height: 8),
              if (accounts.length < 2)
                Text(
                  'Create a second wallet in the Accounts tab to log transfers.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.expense,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: accounts
                      .where((a) => a.id != _accountId)
                      .map((acc) {
                    return ChoiceChip(
                      avatar: Icon(acc.icon, size: 18),
                      label: Text(acc.name),
                      selected: acc.id == _toAccountId,
                      onSelected: (_) => setState(() => _toAccountId = acc.id),
                    );
                  }).toList(),
                ),
            ] else ...<Widget>[
              Text(
                'Category',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.mutedText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((CategoryItem cat) {
                  final selected = cat.id == _categoryId;
                  return ChoiceChip(
                    avatar: Icon(cat.icon, size: 18, color: cat.color),
                    label: Text(cat.name),
                    selected: selected,
                    onSelected: (_) => setState(() => _categoryId = cat.id),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(AppFormatters.dateShort(_date)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g., Lunch with team',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.expense,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(widget.existing == null ? 'Save Entry' : 'Update Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
