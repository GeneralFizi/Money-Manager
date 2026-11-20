import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money_manager/data/services/biometric_service.dart';
import 'package:money_manager/data/services/database_service.dart';
import 'package:money_manager/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'renders eye-friendly shell, switches tabs, and logs expense',
    timeout: const Timeout(Duration(seconds: 30)),
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final dbService = DatabaseService(forceKeyValueStore: true);
      final viewModel = createDefaultAppViewModel(
        databaseService: dbService,
        biometricService: BiometricService(isSupportedOverride: false),
      );
      await viewModel.initialize();

      await tester.pumpWidget(MoneyManagerApp(viewModel: viewModel));
      await tester.pumpAndSettle();

      // Verify Overview tab renders Total Balance
      expect(find.text('Total Balance'), findsOneWidget);

      // Open Add Transaction bottom sheet
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('New Entry'), findsOneWidget);

      // Enter expense amount and save
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '42.50');
      await tester.ensureVisible(find.text('Save Entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Entry'));
      await tester.pumpAndSettle();

      // Verify balance, monthly expense pill, and transaction row updated
      expect(find.text('-\$42.50'), findsNWidgets(2));
      expect(find.text('\$42.50'), findsOneWidget);

      // Navigate through Wallets, Budgets, Reports, and Backup tabs
      await tester.tap(find.text('Wallets'));
      await tester.pumpAndSettle();
      expect(find.text('Cash Wallet'), findsOneWidget);
      expect(find.text('Main Bank'), findsOneWidget);

      await tester.tap(find.text('Budgets'));
      await tester.pumpAndSettle();
      expect(find.text('Monthly Budgets'), findsOneWidget);
      expect(find.text('Recurring Bills & Income'), findsOneWidget);

      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();
      expect(find.text('Spending by Category'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('6-Month Cashflow'), findsOneWidget);

      await tester.tap(find.text('Backup'));
      await tester.pumpAndSettle();
      expect(find.text('100% Local-First Privacy'), findsOneWidget);
      expect(find.text('Google Drive Backup (On-Demand)'), findsOneWidget);

      await dbService.close();
    },
  );
}
