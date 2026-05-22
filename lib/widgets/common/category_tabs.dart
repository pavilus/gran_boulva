import 'package:flutter/material.dart';

import 'app_interactions.dart';

class CategoryItem {
  final String label;
  final String icon;
  final String? asset;
  const CategoryItem({required this.label, required this.icon, this.asset});
}

const List<CategoryItem> kCategories = [
  CategoryItem(label: 'Popilè', icon: '🔥', asset: 'assets/images/fire.png'),
  CategoryItem(label: 'Tout', icon: '⭐', asset: 'assets/images/star.png'),
  CategoryItem(
      label: 'Sosyete', icon: '👥', asset: 'assets/images/society.png'),
  CategoryItem(
      label: 'Divètisman',
      icon: '🎬',
      asset: 'assets/images/entertainment.png'),
  CategoryItem(label: 'Sport', icon: '⚽', asset: 'assets/images/sport.png'),
  CategoryItem(
      label: 'Politik', icon: '🏛️', asset: 'assets/images/politics.png'),
];

class CategoryTabs extends StatelessWidget {
  final String activeCategory;
  final ValueChanged<String> onSelect;

  const CategoryTabs({
    super.key,
    required this.activeCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kCategories.map((cat) {
          final isActive = cat.label == activeCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: isActive
                ? _ActiveTab(cat: cat, onTap: () => onSelect(cat.label))
                : _InactiveTab(cat: cat, onTap: () => onSelect(cat.label)),
          );
        }).toList(),
      ),
    );
  }
}

class _ActiveTab extends StatelessWidget {
  final CategoryItem cat;
  final VoidCallback onTap;

  const _ActiveTab({required this.cat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: AppHaptic.selection,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(1.5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0826),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cat.asset != null)
                Image.asset(cat.asset!,
                    width: 15, height: 15, fit: BoxFit.contain)
              else
                Text(cat.icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(
                cat.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InactiveTab extends StatelessWidget {
  final CategoryItem cat;
  final VoidCallback onTap;

  const _InactiveTab({required this.cat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: AppHaptic.selection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF11112A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Text(
          cat.label,
          style: const TextStyle(
            color: Color(0xFF9999BB),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
