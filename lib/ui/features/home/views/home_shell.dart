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
          floatingActionButton: _selectedIndex <= 2
              ? FloatingActionButton.extended(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TransactionFormSheet(viewModel: vm),
                  ),
                  elevation: 2,
                  extendedPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Add',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                )
              : null,
          bottomNavigationBar: _MinimalBottomNav(
            selectedIndex: _selectedIndex,
            onSelect: (index) => setState(() => _selectedIndex = index),
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
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const List<String> _labels = <String>[
    'Overview',
    'Wallets',
    'Budgets',
    'Reports',
    'Backup',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final barColor = theme.colorScheme.surfaceContainerLowest;

    return Container(
      decoration: BoxDecoration(
        color: barColor,
        border: Border(top: BorderSide(color: colors.cardBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List<Widget>.generate(_labels.length, (i) {
              final selected = i == selectedIndex;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: _labels[i],
                    child: Material(
                      color: selected ? colors.softTint : Colors.transparent,
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onSelect(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w500,
                              color: selected
                                  ? theme.colorScheme.onSurface
                                  : colors.mutedText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
