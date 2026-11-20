import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Semantic colors tuned for readability and low eye strain in both themes.
@immutable
class MoneyColors extends ThemeExtension<MoneyColors> {
  const MoneyColors({
    required this.income,
    required this.expense,
    required this.transfer,
    required this.warning,
    required this.cardBorder,
    required this.softTint,
    required this.mutedText,
  });

  final Color income;
  final Color expense;
  final Color transfer;
  final Color warning;
  final Color cardBorder;
  final Color softTint;
  final Color mutedText;

  static const MoneyColors light = MoneyColors(
    income: Color(0xFF2B7A57),
    expense: Color(0xFFB54D45),
    transfer: Color(0xFF526478),
    warning: Color(0xFFB88746),
    cardBorder: Color(0xFFEAE8E1),
    softTint: Color(0xFFEFECE6),
    mutedText: Color(0xFF7A7872),
  );

  static const MoneyColors dark = MoneyColors(
    income: Color(0xFF63B891),
    expense: Color(0xFFE08076),
    transfer: Color(0xFF829AB1),
    warning: Color(0xFFE3B469),
    cardBorder: Color(0xFF262623),
    softTint: Color(0xFF242421),
    mutedText: Color(0xFF8C8A82),
  );

  @override
  MoneyColors copyWith({
    Color? income,
    Color? expense,
    Color? transfer,
    Color? warning,
    Color? cardBorder,
    Color? softTint,
    Color? mutedText,
  }) {
    return MoneyColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      transfer: transfer ?? this.transfer,
      warning: warning ?? this.warning,
      cardBorder: cardBorder ?? this.cardBorder,
      softTint: softTint ?? this.softTint,
      mutedText: mutedText ?? this.mutedText,
    );
  }

  @override
  MoneyColors lerp(ThemeExtension<MoneyColors>? other, double t) {
    if (other is! MoneyColors) return this;
    return MoneyColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      softTint: Color.lerp(softTint, other.softTint, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
    );
  }
}

/// Minimalist Warm Alabaster (Light) and Matte Obsidian (Dark) themes.
class AppTheme {
  static const Color lightBackground = Color(0xFFFAF9F6);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF181816);
  static const Color lightText = Color(0xFF181816);

  static const Color darkBackground = Color(0xFF111110);
  static const Color darkCard = Color(0xFF181816);
  static const Color darkPrimary = Color(0xFFF0EEE9);
  static const Color darkText = Color(0xFFF0EEE9);

  static ThemeData light({ColorScheme? dynamicColorScheme}) {
    final scheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: lightPrimary,
          brightness: Brightness.light,
          primary: lightPrimary,
          onPrimary: lightBackground,
          secondaryContainer: MoneyColors.light.softTint,
          onSecondaryContainer: lightText,
          surface: lightBackground,
          surfaceContainerLowest: lightCard,
          surfaceContainerLow: const Color(0xFFF3F1EC),
          surfaceContainer: const Color(0xFFEFECE6),
          surfaceContainerHighest: const Color(0xFFE8E5DE),
          onSurface: lightText,
          outlineVariant: MoneyColors.light.cardBorder,
        );

    return _buildTheme(
      scheme: scheme,
      scaffoldBg: lightBackground,
      cardBg: lightCard,
      moneyColors: MoneyColors.light,
    );
  }

  static ThemeData dark({ColorScheme? dynamicColorScheme}) {
    final scheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: darkPrimary,
          brightness: Brightness.dark,
          primary: darkPrimary,
          onPrimary: darkBackground,
          secondaryContainer: MoneyColors.dark.softTint,
          onSecondaryContainer: darkText,
          surface: darkBackground,
          surfaceContainerLowest: darkCard,
          surfaceContainerLow: const Color(0xFF181816),
          surfaceContainer: const Color(0xFF20201D),
          surfaceContainerHighest: const Color(0xFF2A2A27),
          onSurface: darkText,
          outlineVariant: MoneyColors.dark.cardBorder,
        );

    return _buildTheme(
      scheme: scheme,
      scaffoldBg: darkBackground,
      cardBg: darkCard,
      moneyColors: MoneyColors.dark,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required Color scaffoldBg,
    required Color cardBg,
    required MoneyColors moneyColors,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      extensions: <ThemeExtension<dynamic>>[moneyColors],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: moneyColors.cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: moneyColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: moneyColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        indicatorColor: moneyColors.softTint,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? scheme.primary : moneyColors.mutedText,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 1,
        shape: const StadiumBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardBg,
        selectedColor: moneyColors.softTint,
        side: BorderSide(color: moneyColors.cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          side: BorderSide(color: moneyColors.cardBorder),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: moneyColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Applies tabular numerals so financial figures align vertically.
  static TextStyle tabular(TextStyle? style) {
    return (style ?? const TextStyle()).copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }
}

extension MoneyThemeContext on BuildContext {
  MoneyColors get moneyColors =>
      Theme.of(this).extension<MoneyColors>() ?? MoneyColors.light;
}

/// Reusable minimalist pill button shared across filters, headers, and forms.
class MinimalPill extends StatelessWidget {
  const MinimalPill({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.filledInk = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool filledInk;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final bg = filledInk
        ? theme.colorScheme.primary
        : (selected
            ? colors.softTint
            : theme.colorScheme.surfaceContainerLowest);
    final fg = filledInk
        ? theme.colorScheme.onPrimary
        : (selected ? theme.colorScheme.onSurface : colors.mutedText);
    final borderColor =
        (filledInk || selected) ? theme.colorScheme.primary : colors.cardBorder;

    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: borderColor, width: 1)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  (filledInk || selected) ? FontWeight.w600 : FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact inline month switcher matching the minimalist header style.
class MinimalMonthSwitcher extends StatelessWidget {
  const MinimalMonthSwitcher({
    super.key,
    required this.month,
    required this.onChangeMonth,
    this.textStyle,
  });

  final DateTime month;
  final ValueChanged<int> onChangeMonth;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _chevronButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous Month',
          color: colors.mutedText,
          onTap: () => onChangeMonth(-1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            AppFormatters.monthYear(month),
            style: textStyle ??
                theme.textTheme.bodySmall?.copyWith(
                  color: colors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        _chevronButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next Month',
          color: colors.mutedText,
          onTap: () => onChangeMonth(1),
        ),
      ],
    );
  }

  Widget _chevronButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkResponse(
      onTap: onTap,
      radius: 16,
      child: Tooltip(
        message: tooltip,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

/// Formatting helpers for clean currency and date rendering.
class AppFormatters {
  static String money(
    double amount,
    String symbol, {
    bool showPlusSign = false,
    bool showMinusSign = false,
  }) {
    final absAmount = amount.abs();
    final formatter = NumberFormat('#,##0.00');
    final formatted = formatter.format(absAmount);
    final sign = amount < 0 || showMinusSign
        ? '-'
        : (showPlusSign && amount > 0 ? '+' : '');
    return '$sign$symbol$formatted';
  }

  static String compactMoney(double amount, String symbol) {
    final absAmount = amount.abs();
    final sign = amount < 0 ? '-' : '';
    if (absAmount >= 1000000) {
      return '$sign$symbol${(absAmount / 1000000).toStringAsFixed(1)}M';
    }
    if (absAmount >= 1000) {
      return '$sign$symbol${(absAmount / 1000).toStringAsFixed(1)}k';
    }
    return '$sign$symbol${absAmount.toStringAsFixed(0)}';
  }

  static String monthYear(DateTime date) => DateFormat('MMMM yyyy').format(date);

  static String shortMonth(DateTime date) => DateFormat('MMM').format(date);

  static String dayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return 'Today • ${DateFormat('MMM d').format(date)}';
    if (target == today.subtract(const Duration(days: 1))) {
      return 'Yesterday • ${DateFormat('MMM d').format(date)}';
    }
    return DateFormat('EEE, MMM d').format(date);
  }

  static String dateShort(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  static String dateTimeShort(DateTime date) =>
      DateFormat('MMM d, yyyy • h:mm a').format(date);
}
