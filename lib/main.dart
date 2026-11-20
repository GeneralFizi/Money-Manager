import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';

import 'data/repositories/finance_repository.dart';
import 'data/services/biometric_service.dart';
import 'data/services/database_service.dart';
import 'data/services/google_drive_service.dart';
import 'data/services/local_export_service.dart';
import 'data/services/preferences_service.dart';
import 'ui/core/app_theme.dart';
import 'ui/features/home/view_models/app_view_model.dart';
import 'ui/features/home/views/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final viewModel = createDefaultAppViewModel()..initialize();
  runApp(MoneyManagerApp(viewModel: viewModel));
}

/// Builds the production [AppViewModel] backed by local-only storage.
AppViewModel createDefaultAppViewModel({
  DatabaseService? databaseService,
  BiometricService? biometricService,
}) {
  final dbService = databaseService ?? DatabaseService();
  return AppViewModel(
    repository: FinanceRepository(databaseService: dbService),
    preferencesService: PreferencesService(),
    biometricService: biometricService ?? BiometricService(),
    localExportService: LocalExportService(),
    googleDriveService: GoogleDriveService(),
  );
}

/// Root application widget with eye-friendly light/dark themes and optional Material You.
class MoneyManagerApp extends StatelessWidget {
  const MoneyManagerApp({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final useDynamic = viewModel.settings.useDynamicColor;
        if (!useDynamic) {
          return _buildMaterialApp();
        }
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return _buildMaterialApp(
              lightDynamic: lightDynamic,
              darkDynamic: darkDynamic,
            );
          },
        );
      },
    );
  }

  Widget _buildMaterialApp({
    ColorScheme? lightDynamic,
    ColorScheme? darkDynamic,
  }) {
    return MaterialApp(
      title: 'Money Manager',
      debugShowCheckedModeBanner: false,
      themeMode: viewModel.settings.themeMode,
      theme: AppTheme.light(dynamicColorScheme: lightDynamic),
      darkTheme: AppTheme.dark(dynamicColorScheme: darkDynamic),
      home: HomeShell(viewModel: viewModel),
    );
  }
}
