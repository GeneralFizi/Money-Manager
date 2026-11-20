import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain/models/account.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/transaction_item.dart';
import '../../../core/app_theme.dart';
import '../view_models/app_view_model.dart';
import 'transaction_form_sheet.dart';

/// Wallets / Accounts tab supporting Cash, Bank, Card, Savings, and Transfers.
class AccountsTab extends StatelessWidget {
  const AccountsTab({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final symbol = viewModel.settings.currencySymbol;
    final summaries = viewModel.accountSummaries;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Combined Net Worth',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppFormatters.money(viewModel.totalNetBalance, symbol),
                        style: AppTheme.tabular(
                          theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TransactionFormSheet(
                      viewModel: viewModel,
                      initialType: TransactionType.transfer,
                    ),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Transfer'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Your Wallets (${summaries.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAccountDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Wallet'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final summary in summaries) ...<Widget>[
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _showAccountDialog(context, existing: summary.account),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: summary.account.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            summary.account.icon,
                            color: summary.account.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                summary.account.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                summary.account.type.label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          AppFormatters.money(summary.currentBalance, symbol),
                          style: AppTheme.tabular(
                            theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'In: ${AppFormatters.money(summary.totalIncome, symbol)}',
                            style: AppTheme.tabular(
                              theme.textTheme.bodySmall?.copyWith(
                                color: colors.income,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Out: ${AppFormatters.money(summary.totalExpense, symbol)}',
                            textAlign: TextAlign.end,
                            style: AppTheme.tabular(
                              theme.textTheme.bodySmall?.copyWith(
                                color: colors.expense,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Future<void> _showAccountDialog(
    BuildContext context, {
    Account? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AccountEditorDialog(
        viewModel: viewModel,
        existing: existing,
      ),
    );
  }
}

class _AccountEditorDialog extends StatefulWidget {
  const _AccountEditorDialog({
    required this.viewModel,
    this.existing,
  });

  final AppViewModel viewModel;
  final Account? existing;

  @override
  State<_AccountEditorDialog> createState() => _AccountEditorDialogState();
}

class _AccountEditorDialogState extends State<_AccountEditorDialog> {
  static const Uuid _uuid = Uuid();

  late TextEditingController _nameController;
  late TextEditingController _initialBalanceController;
  late AccountType _type;
  late int _colorValue;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _initialBalanceController = TextEditingController(
      text: (widget.existing?.initialBalance ?? 0.0).toStringAsFixed(2),
    );
    _type = widget.existing?.type ?? AccountType.bank;
    _colorValue =
        widget.existing?.colorValue ?? DefaultCategories.softPalette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDelete =
        widget.existing != null && widget.viewModel.accounts.length > 1;

    return AlertDialog(
      title: Text(widget.existing == null ? 'New Wallet' : 'Edit Wallet'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Wallet Name',
                hintText: 'e.g., Savings, Visa Card',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: AccountType.values
                  .map(
                    (t) => DropdownMenuItem<AccountType>(
                      value: t,
                      child: Row(
                        children: <Widget>[
                          Icon(AccountIcons.forType(t), size: 18),
                          const SizedBox(width: 8),
                          Text(t.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _type = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _initialBalanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Starting Balance',
                prefixText: '${widget.viewModel.settings.currencySymbol} ',
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DefaultCategories.softPalette.map((val) {
                final selected = val == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = val),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(val),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 2.5,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        if (canDelete)
          TextButton(
            onPressed: () async {
              await widget.viewModel.deleteAccount(widget.existing!.id);
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
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            final initial =
                double.tryParse(_initialBalanceController.text.trim()) ?? 0.0;
            final account = Account(
              id: widget.existing?.id ?? _uuid.v4(),
              name: name,
              type: _type,
              initialBalance: initial,
              colorValue: _colorValue,
              iconCodePoint: AccountIcons.forType(_type).codePoint,
              createdAt: widget.existing?.createdAt ?? DateTime.now(),
            );
            await widget.viewModel.saveAccount(account);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
