import 'package:flutter/material.dart';

/// Item categories from DATA_MODEL.md §5.2.
///
/// Each entry maps a stable database key to its Indonesian UI label
/// and a representative Material icon for quick visual scanning.
class ItemCategory {
  const ItemCategory({
    required this.key,
    required this.label,
    required this.icon,
  });

  /// Database key stored in the `category` column.
  final String key;

  /// Indonesian label shown in the UI.
  final String label;

  /// Representative icon for category chips and filters.
  final IconData icon;
}

/// Ordered list of all 10 MVP categories.
const List<ItemCategory> kCategories = [
  ItemCategory(
    key: 'electronics_gadgets',
    label: 'Elektronik & Gadget',
    icon: Icons.phone_android_outlined,
  ),
  ItemCategory(
    key: 'wallet_money',
    label: 'Dompet & Uang',
    icon: Icons.account_balance_wallet_outlined,
  ),
  ItemCategory(
    key: 'cards_documents',
    label: 'Kartu & Dokumen',
    icon: Icons.credit_card_outlined,
  ),
  ItemCategory(
    key: 'keys_access',
    label: 'Kunci & Akses',
    icon: Icons.key_outlined,
  ),
  ItemCategory(
    key: 'bags_pouches',
    label: 'Tas & Pouch',
    icon: Icons.shopping_bag_outlined,
  ),
  ItemCategory(
    key: 'books_stationery',
    label: 'Buku & Alat Tulis',
    icon: Icons.menu_book_outlined,
  ),
  ItemCategory(
    key: 'clothing_equipment',
    label: 'Pakaian & Perlengkapan',
    icon: Icons.checkroom_outlined,
  ),
  ItemCategory(
    key: 'personal_accessories',
    label: 'Aksesori Pribadi',
    icon: Icons.watch_outlined,
  ),
  ItemCategory(
    key: 'bottles_food_containers',
    label: 'Botol & Wadah Makanan',
    icon: Icons.local_cafe_outlined,
  ),
  ItemCategory(key: 'other', label: 'Lainnya', icon: Icons.more_horiz),
];

/// Look up a category by its database key.
/// Returns `null` if the key is not found.
ItemCategory? categoryByKey(String key) {
  for (final cat in kCategories) {
    if (cat.key == key) return cat;
  }
  return null;
}
