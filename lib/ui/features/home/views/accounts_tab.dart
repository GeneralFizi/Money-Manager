import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/services/preferences_service.dart';
import '../../../../domain/models/account.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/transaction_item.dart';
import '../../../core/app_theme.dart';
import '../view_models/app_view_model.dart';
import 'transaction_form_sheet.dart';

/// Wallets / Accounts tab supporting Cash, Bank, Card, Savings, foreign currency wallets, and Transfers.
class AccountsTab extends StatelessWidget {
  const AccountsTab({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final baseSymbol = viewModel.settings.currencySymbol;
    final baseCode = viewModel.settings.currencyCode;
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
                        'Combined Net Worth ($baseCode)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppFormatters.money(viewModel.totalNetBalance, baseSymbol),
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
          _WalletCard(
            summary: summary,
            baseCode: baseCode,
            baseSymbol: baseSymbol,
            onTap: () => _showAccountDialog(context, existing: summary.account),
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

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.summary,
    required this.baseCode,
    required this.baseSymbol,
    required this.onTap,
  });

  final AccountSummary summary;
  final String baseCode;
  final String baseSymbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final acc = summary.account;
    final walletSymbol = acc.effectiveCurrencySymbol(baseSymbol);
    final walletCode = acc.effectiveCurrencyCode(baseCode);
    final isForeign = acc.isForeignCurrency(baseCode);

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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: acc.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(acc.icon, color: acc.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          acc.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          isForeign
                              ? '${acc.type.label} • $walletCode'
                              : acc.type.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        AppFormatters.money(
                          summary.currentBalance,
                          walletSymbol,
                        ),
                        style: AppTheme.tabular(
                          theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isForeign)
                        Text(
                          '≈ ${AppFormatters.money(summary.currentBalanceInBase, baseSymbol)}',
                          style: AppTheme.tabular(
                            theme.textTheme.bodySmall?.copyWith(
                              color: colors.mutedText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (isForeign) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  'Offline rate: 1 $walletCode = ${acc.exchangeRateToBase} $baseCode',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.mutedText,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'In: ${AppFormatters.money(summary.totalIncome, walletSymbol)}',
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
                      'Out: ${AppFormatters.money(summary.totalExpense, walletSymbol)}',
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
  late TextEditingController _rateController;
  late AccountType _type;
  late int _colorValue;
  late String _currencyCode;
  late String _currencySymbol;

  @override
  void initState() {
    super.initState();
    final baseCode = widget.viewModel.settings.currencyCode;
    final baseSymbol = widget.viewModel.settings.currencySymbol;
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _initialBalanceController = TextEditingController(
      text: (widget.existing?.initialBalance ?? 0.0).toStringAsFixed(2),
    );
    _type = widget.existing?.type ?? AccountType.bank;
    _colorValue =
        widget.existing?.colorValue ?? DefaultCategories.softPalette.first;
    _currencyCode = widget.existing?.effectiveCurrencyCode(baseCode) ?? baseCode;
    _currencySymbol =
        widget.existing?.effectiveCurrencySymbol(baseSymbol) ?? baseSymbol;
    final initialRate = widget.existing != null &&
            widget.existing!.isForeignCurrency(baseCode)
        ? widget.existing!.exchangeRateToBase
        : CurrencyOption.defaultRateToBase(
            walletCode: _currencyCode,
            baseCode: baseCode,
          );
    _rateController = TextEditingController(text: initialRate.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseCode = widget.viewModel.settings.currencyCode;
    final isForeign = _currencyCode != baseCode;
    final canDelete =
        widget.existing != null && widget.viewModel.accounts.length > 1;

    final presetCodes = <String>[
      for (final opt in CurrencyOption.presets) opt.code,
      if (!CurrencyOption.presets.any((o) => o.code == baseCode)) baseCode,
      if (!CurrencyOption.presets.any((o) => o.code == _currencyCode) &&
          _currencyCode != baseCode)
        _currencyCode,
    ];

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
                hintText: 'e.g., Euro Travel, Savings',
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
            DropdownButtonFormField<String>(
              initialValue: _currencyCode,
              decoration: const InputDecoration(labelText: 'Wallet Currency'),
              items: presetCodes.map((code) {
                final opt = CurrencyOption.findByCode(code);
                final label = opt != null
                    ? '${opt.code} (${opt.symbol}) — ${opt.label}'
                    : code;
                return DropdownMenuItem<String>(
                  value: code,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (code) {
                if (code == null) return;
                setState(() {
                  _currencyCode = code;
                  _currencySymbol = CurrencyOption.findByCode(code)?.symbol ??
                      (code == baseCode
                          ? widget.viewModel.settings.currencySymbol
                          : code);
                  final suggested = CurrencyOption.defaultRateToBase(
                    walletCode: code,
                    baseCode: baseCode,
                  );
                  _rateController.text = suggested.toString();
                });
              },
            ),
            if (isForeign) ...<Widget>[
              const SizedBox(height: 12),
              TextField(
                controller: _rateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Offline Rate (1 $_currencyCode in $baseCode)',
                  helperText: 'Editable anytime — 100% offline',
                ),
              ),
            ],
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
                prefixText: '$_currencySymbol ',
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
            final parsedRate = double.tryParse(_rateController.text.trim());
            final safeRate = isForeign
                ? ((parsedRate != null && parsedRate > 0) ? parsedRate : 1.0)
                : 1.0;

            final account = Account(
              id: widget.existing?.id ?? _uuid.v4(),
              name: name,
              type: _type,
              initialBalance: initial,
              colorValue: _colorValue,
              iconCodePoint: AccountIcons.forType(_type).codePoint,
              createdAt: widget.existing?.createdAt ?? DateTime.now(),
              currencyCode: isForeign ? _currencyCode : null,
              currencySymbol: isForeign ? _currencySymbol : null,
              exchangeRateToBase: safeRate,
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
