import 'package:material_ui/material_ui.dart';

/// Category classification.
enum CategoryType {
  income('Income'),
  expense('Expense');

  const CategoryType(this.label);

  final String label;

  static CategoryType fromName(String? value) {
    return CategoryType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CategoryType.expense,
    );
  }
}

/// Constant icon registry so Flutter release tree-shaking retains all category icons.
class CategoryIcons {
  static const List<IconData> choices = <IconData>[
    Icons.restaurant_outlined,
    Icons.home_outlined,
    Icons.directions_car_outlined,
    Icons.shopping_bag_outlined,
    Icons.receipt_long_outlined,
    Icons.local_grocery_store_outlined,
    Icons.medical_services_outlined,
    Icons.movie_outlined,
    Icons.school_outlined,
    Icons.flight_outlined,
    Icons.pets_outlined,
    Icons.work_outline,
    Icons.laptop_mac_outlined,
    Icons.trending_up_outlined,
    Icons.card_giftcard_outlined,
    Icons.savings_outlined,
    Icons.category_outlined,
  ];

  static IconData resolve(int codePoint) {
    for (final icon in choices) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.category_outlined;
  }
}

/// Represents an income or expense category.
class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.colorValue,
    required this.iconCodePoint,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final CategoryType type;
  final int colorValue;
  final int iconCodePoint;
  final bool isDefault;

  Color get color => Color(colorValue);
  IconData get icon => CategoryIcons.resolve(iconCodePoint);

  CategoryItem copyWith({
    String? id,
    String? name,
    CategoryType? type,
    int? colorValue,
    int? iconCodePoint,
    bool? isDefault,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type.name,
      'color_value': colorValue,
      'icon_code_point': iconCodePoint,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    final rawDefault = map['is_default'] ?? map['isDefault'];
    final isDefault = rawDefault is bool ? rawDefault : (rawDefault as num? ?? 0) == 1;
    return CategoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      type: CategoryType.fromName(map['type'] as String?),
      colorValue: ((map['color_value'] ?? map['colorValue']) as num?)?.toInt() ?? 0xFF2D6A5B,
      iconCodePoint: ((map['icon_code_point'] ?? map['iconCodePoint']) as num?)?.toInt() ??
          Icons.category_outlined.codePoint,
      isDefault: isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type.name,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'isDefault': isDefault,
    };
  }

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem.fromMap(json);
}

/// Eye-friendly muted pastel category defaults.
class DefaultCategories {
  static final List<CategoryItem> all = <CategoryItem>[
    // Income
    CategoryItem(
      id: 'cat_salary',
      name: 'Salary',
      type: CategoryType.income,
      colorValue: 0xFF2D6A5B,
      iconCodePoint: Icons.work_outline.codePoint,
      isDefault: true,
    ),
    CategoryItem(
      id: 'cat_freelance',
      name: 'Freelance',
      type: CategoryType.income,
      colorValue: 0xFF4B8576,
      iconCodePoint: Icons.laptop_mac_outlined.codePoint,
      isDefault: true,
    ),
    CategoryItem(
      id: 'cat_investments',
      name: 'Investments',
      type: CategoryType.income,
      colorValue: 0xFF3A6B9C,
      iconCodePoint: Icons.trending_up_outlined.codePoint,
      isDefault: true,
    ),
    CategoryItem(
      id: 'cat_gift_in',
      name: 'Gift',
      type: CategoryType.income,
      colorValue: 0xFF6B8A62,
      iconCodePoint: Icons.card_giftcard_outlined.codePoint,
      isDefault: true,
    ),

    // Expense
    CategoryItem(
      id: 'cat_food',
      name: 'Food & Dining',
      type: CategoryType.expense,
      colorValue: 0xFFC56B53,
      iconCodePoint: Icons.restaurant_outlined.codePoint,
      isDefault: true,
    ),
    CategoryItem(
      id: 'cat_groceries',
      name: 'Groceries',
      type: CategoryType.expense,
      colorValue: 0xFF658B68,
      iconCodePoint: Icons.local_grocery_store_outlined.codePoint,
      isDefault: true,
    ),
    CategoryItem(
      id: 'cat_housing',
      name: 'Housing & Rent',
      type: CategoryType.expense,
      colorValue: 0xFF56748B,
      iconCodePoint: Icons.home_outlined.codePoint,
      isDefault: true,
    ),
    CategoryItem(
      id: 'cat_transport',
      name: 'Transport',
      type: CategoryType.expense,
      colorValue: 0xFF6D7B9B,
      iconCodePoint: Icons.directions_car_outlined.codePoint,
      isDefault: true,
    ),
    CategoryItem(
      id: 'cat_utilities',
      name: 'Utilities & Bills',
      type: CategoryType.expense,
      colorValue: 0xFFB88746,
      iconCodePoint: Icons.receipt_long_outlined.codePoint,
      isDefault: true,
    ),
    CategoryItem(
      id: 'cat_shopping',
      name: 'Shopping',
      type: CategoryType.expense,
      colorValue: 0xFF9E6B7B,
      iconCodePoint: Icons.shopping_bag_outlined.codePoint,
      isDefault: true,
    ),
    CategoryItem(
      id: 'cat_health',
      name: 'Health',
      type: CategoryType.expense,
      colorValue: 0xFF4C8E89,
      iconCodePoint: Icons.medical_services_outlined.codePoint,
      isDefault: true,
    ),
    CategoryItem(
      id: 'cat_entertainment',
      name: 'Entertainment',
      type: CategoryType.expense,
      colorValue: 0xFF7D6B91,
      iconCodePoint: Icons.movie_outlined.codePoint,
      isDefault: true,
    ),
  ];

  static const List<int> softPalette = <int>[
    0xFF2D6A5B,
    0xFF4B8576,
    0xFF3A6B9C,
    0xFF658B68,
    0xFFC56B53,
    0xFFB88746,
    0xFF56748B,
    0xFF6D7B9B,
    0xFF9E6B7B,
    0xFF7D6B91,
    0xFF4C8E89,
  ];
}
