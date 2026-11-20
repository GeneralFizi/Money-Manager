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
        // Strict Offline Privacy Guarantee Banner
        Card(
          color: colors.softTint,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.shield_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '100% Local-First Privacy',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All accounts, budgets, and transactions are stored only on this device. '
                        'The app connects to the internet strictly when you tap a Google Drive backup or restore button below.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // On-Demand Google Drive Backup Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.cloud_upload_outlined, color: colors.transfer),
                    const SizedBox(width: 10),
                    Text(
                      'Google Drive Backup (On-Demand)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Saves a readable JSON file inside a visible "MoneyManagerBackups" folder in your Google Drive.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.mutedText,
                  ),
                ),
                if (settings.lastDriveBackupAt != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'Last Drive backup: ${AppFormatters.dateTimeShort(settings.lastDriveBackupAt!)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.income,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: viewModel.isSyncBusy
                            ? null
                            : () => _handleDriveBackup(context),
                        icon: viewModel.isSyncBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.backup_outlined),
                        label: const Text('Save to Drive'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: viewModel.isSyncBusy
                            ? null
                            : () => _handleDriveRestore(context),
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: const Text('Restore'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleShareBackup(context),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Share Backup File to Drive / Files App'),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showOAuthConfigDialog(context),
                    child: const Text('Configure Google OAuth Client ID'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Local Device Backup & Export Card
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.save_alt_rounded),
                title: const Text('Export JSON Backup to Device'),
                subtitle: settings.lastLocalExportAt != null
                    ? Text(
                        'Last local export: ${AppFormatters.dateTimeShort(settings.lastLocalExportAt!)}',
                      )
                    : const Text('Save a readable .json backup offline'),
                onTap: () async {
                  final saved = await viewModel.exportLocalJson();
                  if (context.mounted && saved) {
                    _showSnack(context, 'Local JSON backup saved.');
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.file_open_outlined),
                title: const Text('Import JSON Backup from Device'),
                subtitle: const Text('Restore from a local .json backup file'),
                onTap: () => _handleLocalImport(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('Export Transactions as CSV'),
                subtitle: const Text('Spreadsheet-ready transaction export'),
                onTap: () async {
                  final saved = await viewModel.exportLocalCsv();
                  if (context.mounted && saved) {
                    _showSnack(context, 'CSV transactions exported.');
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Appearance, Currency & Security
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.currency_exchange_rounded),
                title: const Text('Currency'),
                subtitle: Text(
                  '${settings.currencyCode} (${settings.currencySymbol})',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showCurrencyDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Appearance'),
                subtitle: Text(_themeLabel(settings.themeMode)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showThemeDialog(context),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.color_lens_outlined),
                title: const Text('Material You Dynamic Color'),
                subtitle: const Text('Blend system wallpaper colors on Android 12+'),
                value: settings.useDynamicColor,
                onChanged: viewModel.updateUseDynamicColor,
              ),
              if (viewModel.biometricAvailable) ...<Widget>[
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.fingerprint_rounded),
                  title: const Text('Biometric Lock (Fingerprint / Face ID)'),
                  subtitle:
                      const Text('Protect local financial records on launch'),
                  value: settings.biometricEnabled,
                  onChanged: viewModel.setBiometricEnabled,
                ),
              ],
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Manage Categories'),
                subtitle: Text('${viewModel.categories.length} categories'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showCategoriesManager(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Soft Light (Warm Sage)',
      ThemeMode.dark => 'Low-Glare Dark (Deep Slate)',
      ThemeMode.system => 'Follow Device System',
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
                title: Text('Soft Light (Warm Sage)'),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                title: Text('Low-Glare Dark (Deep Slate)'),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                title: Text('Follow Device System'),
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
