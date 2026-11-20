import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../auth/views/lock_screen.dart';
import '../view_models/app_view_model.dart';
import 'accounts_tab.dart';
import 'budgets_tab.dart';
import 'overview_tab.dart';
import 'reports_tab.dart';
import 'settings_tab.dart';
import 'transaction_form_sheet.dart';

/// Main responsive application shell with 5 tabs and quick transaction entry FAB.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      widget.viewModel.lockIfEnabled();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        if (vm.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.isLocked) {
          return LockScreen(viewModel: vm);
        }

        final statusMsg = vm.statusMessage;
        if (statusMsg != null) {
          vm.clearStatusMessage();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(statusMsg)),
              );
            }
          });
        }

        const titles = <String>[
          'Money Manager',
          'Wallets',
          'Budgets',
          'Reports',
          'Sync & Backup',
        ];

        final pages = <Widget>[
          OverviewTab(viewModel: vm),
          AccountsTab(viewModel: vm),
          BudgetsTab(viewModel: vm),
          ReportsTab(viewModel: vm),
          SettingsTab(viewModel: vm),
        ];

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colors = context.moneyColors;

        return Scaffold(
          appBar: AppBar(
            title: Text(titles[_selectedIndex]),
            actions: <Widget>[
              IconButton(
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                icon: Icon(
                  isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  size: 20,
                  color: colors.mutedText,
                ),
                onPressed: () => vm.updateThemeMode(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                ),
              ),
              if (vm.settings.biometricEnabled && vm.biometricAvailable)
                IconButton(
                  tooltip: 'Lock App',
                  icon: Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: colors.mutedText,
                  ),
                  onPressed: vm.lockIfEnabled,
                ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: _MinimalBottomNav(
            selectedIndex: _selectedIndex,
            onSelect: (index) => setState(() => _selectedIndex = index),
            onAddTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => TransactionFormSheet(viewModel: vm),
            ),
          ),
        );
      },
    );
  }
}

class _MinimalBottomNav extends StatelessWidget {
  const _MinimalBottomNav({
    required this.selectedIndex,
    required this.onSelect,
    required this.onAddTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddTap;

  static const List<({String label, IconData icon})> _items =
      <({String label, IconData icon})>[
    (label: 'Overview', icon: Icons.home_outlined),
    (label: 'Wallets', icon: Icons.account_balance_wallet_outlined),
    (label: 'Budgets', icon: Icons.pie_chart_outline_rounded),
    (label: 'Reports', icon: Icons.bar_chart_rounded),
    (label: 'Backup', icon: Icons.cloud_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final dockColor = theme.colorScheme.surfaceContainerLowest;
    final isDark = theme.brightness == Brightness.dark;

    Widget buildTab(int i) {
      final selected = i == selectedIndex;
      final item = _items[i];
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Semantics(
            button: true,
            selected: selected,
            label: item.label,
            child: Material(
              color: selected ? colors.softTint : Colors.transparent,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelect(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        item.icon,
                        size: 17,
                        color: selected
                            ? theme.colorScheme.onSurface
                            : colors.mutedText,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.1,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected
                              ? theme.colorScheme.onSurface
                              : colors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: dockColor,
            shape: StadiumBorder(
              side: BorderSide(color: colors.cardBorder, width: 1),
            ),
            shadows: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: <Widget>[
                buildTab(0),
                buildTab(1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Material(
                      color: theme.colorScheme.primary,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: Tooltip(
                        message: 'Add',
                        child: InkWell(
                          onTap: onAddTap,
                          child: Icon(
                            Icons.add_rounded,
                            size: 20,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                buildTab(2),
                buildTab(3),
                buildTab(4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
