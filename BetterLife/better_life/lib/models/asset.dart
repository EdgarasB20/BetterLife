import 'package:flutter/material.dart';

enum AssetCategory { grynieji, santaupos, nt, kita }

extension AssetCategoryExt on AssetCategory {
  String get label {
    switch (this) {
      case AssetCategory.grynieji:
        return 'Grynieji';
      case AssetCategory.santaupos:
        return 'Santaupos';
      case AssetCategory.nt:
        return 'NT';
      case AssetCategory.kita:
        return 'Kita';
    }
  }

  IconData get icon {
    switch (this) {
      case AssetCategory.grynieji:
        return Icons.payments_rounded;
      case AssetCategory.santaupos:
        return Icons.savings_rounded;
      case AssetCategory.nt:
        return Icons.home_work_rounded;
      case AssetCategory.kita:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AssetCategory.grynieji:
        return Colors.teal.shade400;
      case AssetCategory.santaupos:
        return Colors.blue.shade400;
      case AssetCategory.nt:
        return Colors.orange.shade400;
      case AssetCategory.kita:
        return Colors.purple.shade300;
    }
  }
}

class AssetItem {
  final String name;
  final double value;
  final AssetCategory category;
  final DateTime createdAt;

  AssetItem({
    required this.name,
    required this.value,
    required this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

double totalAssetValue(List<AssetItem> assets) =>
    assets.fold(0.0, (sum, a) => sum + a.value);

Map<AssetCategory, double> categorySums(List<AssetItem> assets) {
  final sums = <AssetCategory, double>{
    for (final category in AssetCategory.values) category: 0.0,
  };
  for (final asset in assets) {
    sums[asset.category] = (sums[asset.category] ?? 0) + asset.value;
  }
  return sums;
}
