import 'package:flutter/material.dart';

class IconHelpers {
  static const Map<String, IconData> iconMap = {
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'train': Icons.train,
    'flight': Icons.flight,
    'hotel': Icons.hotel,
    'shopping_bag': Icons.shopping_bag,
    'movie': Icons.movie,
    'museum': Icons.museum,
    'directions_bus': Icons.directions_bus,
    'local_taxi': Icons.local_taxi,
    'local_gas_station': Icons.local_gas_station,
    'local_grocery_store': Icons.local_grocery_store,
    'local_pharmacy': Icons.local_pharmacy,
    'beach_access': Icons.beach_access,
    'pool': Icons.pool,
    'kitchen': Icons.kitchen,
    'fastfood': Icons.fastfood,
    'local_bar': Icons.local_bar,
    'attach_money': Icons.attach_money,
    'category': Icons.category,
    'directions_boat': Icons.directions_boat,
    'directions_car': Icons.directions_car,
    'local_activity': Icons.local_activity,
    'swap_horiz': Icons.swap_horiz,
  };

  static IconData getIcon(String? name) {
    if (name == null || !iconMap.containsKey(name)) {
      return Icons.category; // Default icon
    }
    return iconMap[name]!;
  }

  static String? getName(IconData icon) {
    // Reverse lookup (ineffcient but map is small)
    for (var entry in iconMap.entries) {
      if (entry.value == icon) return entry.key;
    }
    return null;
  }
}
