import 'package:material_ui/material_ui.dart';

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
          'Budgets & Bills',
          'Reports',
          'Backup & Settings',
        ];

        final pages = <Widget>[
          OverviewTab(viewModel: vm),
          AccountsTab(viewModel: vm),
          BudgetsTab(viewModel: vm),
          ReportsTab(viewModel: vm),
          SettingsTab(viewModel: vm),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(titles[_selectedIndex]),
            actions: <Widget>[
              if (vm.settings.biometricEnabled && vm.biometricAvailable)
                IconButton(
                  tooltip: 'Lock App',
                  icon: const Icon(Icons.lock_outline_rounded),
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
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Overview',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Wallets',
              ),
              NavigationDestination(
                icon: Icon(Icons.pie_chart_outline_rounded),
                selectedIcon: Icon(Icons.track_changes_rounded),
                label: 'Budgets',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: 'Reports',
              ),
              NavigationDestination(
                icon: Icon(Icons.cloud_done_outlined),
                selectedIcon: Icon(Icons.cloud_done_rounded),
                label: 'Backup',
              ),
            ],
          ),
        );
      },
    );
  }
}
