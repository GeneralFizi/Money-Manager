import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/services/preferences_service.dart';
import '../../../../domain/models/category.dart';
import '../../../core/app_theme.dart';
import '../view_models/app_view_model.dart';

/// Backup (On-Demand Google Drive + Local JSON/CSV), Currency, Theme, Security & Categories tab.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final settings = viewModel.settings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: <Widget>[
        // On-Demand Google Drive Backup + Local Privacy Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Google Drive Backup (On-Demand)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  '100% Local-First Privacy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.income,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'All records stay offline on your device. Internet is used only when you tap Save or Restore to your Drive folder "MoneyManagerBackups".',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: colors.mutedText,
                  ),
                ),
                if (settings.lastDriveBackupAt != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'Last Drive backup: ${AppFormatters.dateTimeShort(settings.lastDriveBackupAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.income,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Material(
                        color: theme.colorScheme.primary,
                        shape: const StadiumBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: viewModel.isSyncBusy
                              ? null
                              : () => _handleDriveBackup(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            child: Center(
                              child: viewModel.isSyncBusy
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    )
                                  : Text(
                                      'Save to Drive',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        shape: StadiumBorder(
                          side: BorderSide(color: colors.cardBorder, width: 1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: viewModel.isSyncBusy
                              ? null
                              : () => _handleDriveRestore(context),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 11),
                            child: Center(
                              child: Text(
                                'Restore',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
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
        const SizedBox(height: 14),

        // Unified Local Backup, Currency, Appearance & Security List
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              _SettingsRow(
                label: 'Export JSON',
                trailingText: settings.lastLocalExportAt != null
                    ? 'Saved ${AppFormatters.dateShort(settings.lastLocalExportAt!)}'
                    : 'Local',
                onTap: () async {
                  final saved = await viewModel.exportLocalJson();
                  if (context.mounted && saved) {
                    _showSnack(context, 'Local JSON backup saved.');
                  }
                },
              ),
              const Divider(height: 1),
              _SettingsRow(
                label: 'Import JSON',
                trailingText: 'Restore',
                onTap: () => _handleLocalImport(context),
              ),
              const Divider(height: 1),
              _SettingsRow(
                label: 'Export CSV',
                trailingText: 'Local',
                onTap: () async {
                  final saved = await viewModel.exportLocalCsv();
                  if (context.mounted && saved) {
                    _showSnack(context, 'CSV transactions exported.');
                  }
                },
              ),
              const Divider(height: 1),
              _SettingsRow(
                label: 'Share Backup File',
                trailingText: 'Drive / Files',
                onTap: () => _handleShareBackup(context),
              ),
              const Divider(height: 1),
              _SettingsRow(
                label: 'Base Currency',
                trailingText:
                    '${settings.currencyCode} (${settings.currencySymbol})',
                onTap: () => _showCurrencyDialog(context),
              ),
              const Divider(height: 1),
              _SettingsRow(
                label: 'Appearance',
                trailingText: _themeLabel(settings.themeMode),
                onTap: () => _showThemeDialog(context),
              ),
              if (viewModel.biometricAvailable) ...<Widget>[
                const Divider(height: 1),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Biometric Lock (Face ID / Fingerprint)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: settings.biometricEnabled,
                        onChanged: viewModel.setBiometricEnabled,
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 1),
              _SettingsRow(
                label: 'Manage Categories',
                trailingText: '${viewModel.categories.length}',
                onTap: () => _showCategoriesManager(context),
              ),
              const Divider(height: 1),
              _SettingsRow(
                label: 'Google OAuth Client ID',
                trailingText: 'Configure',
                onTap: () => _showOAuthConfigDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Warm Alabaster (Light)',
      ThemeMode.dark => 'Matte Obsidian (Dark)',
      ThemeMode.system => 'System',
    };
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleDriveBackup(BuildContext context) async {
    try {
      final msg = await viewModel.backupToGoogleDrive();
      if (context.mounted) _showSnack(context, msg);
    } catch (e) {
      if (context.mounted) _showSnack(context, e.toString());
    }
  }

  Future<void> _handleDriveRestore(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore from Google Drive?'),
        content: const Text(
          'This replaces current local accounts, transactions, budgets, and recurring rules with the latest backup from Google Drive.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      final msg = await viewModel.restoreFromGoogleDrive();
      if (context.mounted) _showSnack(context, msg);
    } catch (e) {
      if (context.mounted) _showSnack(context, e.toString());
    }
  }

  Future<void> _handleShareBackup(BuildContext context) async {
    try {
      await viewModel.shareBackupToApps();
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Could not share backup: $e');
    }
  }

  Future<void> _handleLocalImport(BuildContext context) async {
    try {
      final count = await viewModel.importLocalJson();
      if (count != null && context.mounted) {
        _showSnack(context, 'Restored $count transactions from local JSON.');
      }
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Invalid backup file: $e');
    }
  }

  Future<void> _showCurrencyDialog(BuildContext context) async {
    final customCodeCtrl = TextEditingController();
    final customSymCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final opt in CurrencyOption.presets)
                  ListTile(
                    title: Text('${opt.code} (${opt.symbol})'),
                    subtitle: Text(opt.label),
                    trailing:
                        viewModel.settings.currencyCode == opt.code
                            ? Icon(
                                Icons.check_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                    onTap: () async {
                      await viewModel.updateCurrency(opt.code, opt.symbol);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                  ),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: customCodeCtrl,
                        decoration: const InputDecoration(labelText: 'Code (e.g. CHF)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: customSymCtrl,
                        decoration: const InputDecoration(labelText: 'Symbol'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              final code = customCodeCtrl.text.trim().toUpperCase();
              final sym = customSymCtrl.text.trim();
              if (code.isNotEmpty && sym.isNotEmpty) {
                await viewModel.updateCurrency(code, sym);
              }
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Use Custom'),
          ),
        ],
      ),
    );
  }

  Future<void> _showThemeDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Appearance'),
        content: RadioGroup<ThemeMode>(
          groupValue: viewModel.settings.themeMode,
          onChanged: (mode) async {
            if (mode == null) return;
            await viewModel.updateThemeMode(mode);
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                title: Text('Warm Alabaster (Light)'),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                title: Text('Matte Obsidian (Dark)'),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                title: Text('System'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showOAuthConfigDialog(BuildContext context) async {
    final controller =
        TextEditingController(text: viewModel.settings.googleClientId ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Google OAuth Client ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Optional: Enter your Google Cloud OAuth Client ID for direct Google Drive API login (or leave blank to use native platform config / Share to Drive App).',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'OAuth Client ID',
                hintText: 'xxxx.apps.googleusercontent.com',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await viewModel.updateGoogleClientId(controller.text);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoriesManager(BuildContext context) async {
    const uuid = Uuid();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AnimatedBuilder(
          animation: viewModel,
          builder: (context, _) {
            return AlertDialog(
              title: const Text('Categories'),
              content: SizedBox(
                width: double.maxFinite,
                height: 360,
                child: ListView(
                  children: <Widget>[
                    for (final cat in viewModel.categories)
                      ListTile(
                        dense: true,
                        leading: Icon(cat.icon, color: cat.color),
                        title: Text(cat.name),
                        subtitle: Text(cat.type.label),
                        trailing: cat.isDefault
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () =>
                                    viewModel.deleteCategory(cat.id),
                              ),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Done'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New Category'),
                  onPressed: () async {
                    final nameCtrl = TextEditingController();
                    var type = CategoryType.expense;
                    var colorVal = DefaultCategories.softPalette.first;
                    await showDialog<void>(
                      context: dialogContext,
                      builder: (addCtx) => StatefulBuilder(
                        builder: (context, setState) => AlertDialog(
                          title: const Text('Add Category'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SegmentedButton<CategoryType>(
                                segments: const <ButtonSegment<CategoryType>>[
                                  ButtonSegment<CategoryType>(
                                    value: CategoryType.expense,
                                    label: Text('Expense'),
                                  ),
                                  ButtonSegment<CategoryType>(
                                    value: CategoryType.income,
                                    label: Text('Income'),
                                  ),
                                ],
                                selected: <CategoryType>{type},
                                onSelectionChanged: (s) =>
                                    setState(() => type = s.first),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Category Name',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: DefaultCategories.softPalette
                                    .map((c) => GestureDetector(
                                          onTap: () =>
                                              setState(() => colorVal = c),
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Color(c),
                                              shape: BoxShape.circle,
                                              border: c == colorVal
                                                  ? Border.all(width: 2)
                                                  : null,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(addCtx).pop(),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () async {
                                final name = nameCtrl.text.trim();
                                if (name.isEmpty) return;
                                await viewModel.saveCategory(
                                  CategoryItem(
                                    id: uuid.v4(),
                                    name: name,
                                    type: type,
                                    colorValue: colorVal,
                                    iconCodePoint:
                                        Icons.category_outlined.codePoint,
                                    isDefault: false,
                                  ),
                                );
                                if (addCtx.mounted) {
                                  Navigator.of(addCtx).pop();
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.trailingText,
    required this.onTap,
  });

  final String label;
  final String trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              trailingText,
              style: TextStyle(fontSize: 12, color: colors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
