import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../view_models/app_view_model.dart';

/// Visual Reports & Analytics tab featuring category spending Donut and 6-month Cashflow Bar charts.
class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final symbol = viewModel.settings.currencySymbol;
    final slices = viewModel.expenseBreakdownByCategory;
    final cashflow = viewModel.sixMonthCashflow;

    final shades = <Color>[
      theme.colorScheme.primary,
      colors.transfer,
      colors.mutedText,
      colors.expense,
      colors.income,
      colors.warning,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: <Widget>[
        Center(
          child: MinimalMonthSwitcher(
            month: viewModel.selectedMonth,
            onChangeMonth: viewModel.changeMonth,
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Monthly Net Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _MetricColumn(
                    label: 'Income',
                    value: AppFormatters.money(viewModel.monthlyIncome, symbol),
                    color: colors.income,
                  ),
                ),
                Expanded(
                  child: _MetricColumn(
                    label: 'Expense',
                    value: AppFormatters.money(viewModel.monthlyExpense, symbol),
                    color: colors.expense,
                  ),
                ),
                Expanded(
                  child: _MetricColumn(
                    label: 'Net Saved',
                    value: AppFormatters.money(
                      viewModel.monthlyNet,
                      symbol,
                      showPlusSign: viewModel.monthlyNet > 0,
                    ),
                    color: viewModel.monthlyNet >= 0
                        ? colors.income
                        : colors.expense,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Expense Breakdown Donut Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Spending by Category',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.mutedText,
                  ),
                ),
                const SizedBox(height: 16),
                if (slices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No expenses recorded for ${AppFormatters.monthYear(viewModel.selectedMonth)}.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.mutedText,
                        ),
                      ),
                    ),
                  )
                else ...<Widget>[
                  SizedBox(
                    height: 168,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2.5,
                        centerSpaceRadius: 48,
                        sections: List<PieChartSectionData>.generate(
                          slices.length,
                          (idx) {
                            return PieChartSectionData(
                              value: slices[idx].amount,
                              color: shades[idx % shades.length],
                              radius: 24,
                              title: '',
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (int idx = 0; idx < slices.length; idx++) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: shades[idx % shades.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              slices[idx].category.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${slices[idx].percentage.toStringAsFixed(0)}% · ${AppFormatters.money(slices[idx].amount, symbol)}',
                            style: AppTheme.tabular(
                              const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 6-Month Cashflow Bar Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '6-Month Cashflow',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.mutedText,
                      ),
                    ),
                    Text(
                      '${AppFormatters.money(viewModel.monthlyNet, symbol, showPlusSign: viewModel.monthlyNet > 0)} net',
                      style: AppTheme.tabular(
                        TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: viewModel.monthlyNet >= 0
                              ? colors.income
                              : colors.expense,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _CashflowBarChart(
                  points: cashflow,
                  symbol: symbol,
                  incomeColor: theme.colorScheme.primary,
                  expenseColor: colors.mutedText.withValues(alpha: 0.45),
                  mutedText: colors.mutedText,
                  gridColor: colors.cardBorder,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.moneyColors.mutedText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.tabular(
            theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CashflowBarChart extends StatelessWidget {
  const _CashflowBarChart({
    required this.points,
    required this.symbol,
    required this.incomeColor,
    required this.expenseColor,
    required this.mutedText,
    required this.gridColor,
  });

  final List<MonthlyCashflowPoint> points;
  final String symbol;
  final Color incomeColor;
  final Color expenseColor;
  final Color mutedText;
  final Color gridColor;

  @override
  Widget build(BuildContext context) {
    double maxVal = 100;
    for (final pt in points) {
      maxVal = math.max(maxVal, math.max(pt.income, pt.expense));
    }
    final topY = maxVal * 1.2;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: topY,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: gridColor,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      AppFormatters.compactMoney(value, symbol),
                      style: TextStyle(fontSize: 10, color: mutedText),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      AppFormatters.shortMonth(points[idx].month),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: mutedText,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List<BarChartGroupData>.generate(points.length, (index) {
            final pt = points[index];
            return BarChartGroupData(
              x: index,
              barsSpace: 4,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: pt.income,
                  color: incomeColor,
                  width: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                BarChartRodData(
                  toY: pt.expense,
                  color: expenseColor,
                  width: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
