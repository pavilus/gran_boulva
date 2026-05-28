import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'app_interactions.dart';

// Static tabs that always appear first, before DB categories
const _kStaticTabs = [
  _StaticTab(label: 'Popilè', asset: 'assets/images/fire.png'),
  _StaticTab(label: 'Tout', asset: 'assets/images/star.png'),
];

class _StaticTab {
  final String label;
  final String asset;
  const _StaticTab({required this.label, required this.asset});
}

class CategoryTabs extends StatelessWidget {
  final String activeCategory;
  final ValueChanged<String> onSelect;
  /// Live categories from the DB. When provided, replaces the old hardcoded list.
  final List<CategoryModel>? categories;

  const CategoryTabs({
    super.key,
    required this.activeCategory,
    required this.onSelect,
    this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Static tabs: Popilè + Tout
          ..._kStaticTabs.map((tab) {
            final isActive = tab.label == activeCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: isActive
                  ? _ActiveTab(
                      label: tab.label,
                      asset: tab.asset,
                      onTap: () => onSelect(tab.label),
                    )
                  : _InactiveTab(
                      label: tab.label,
                      onTap: () => onSelect(tab.label),
                    ),
            );
          }),

          // Dynamic DB categories
          if (categories != null)
            ...categories!.map((cat) {
              final isActive = cat.nameHt == activeCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: isActive
                    ? _ActiveTab(
                        label: cat.nameHt,
                        emoji: cat.icon ?? '📂',
                        onTap: () => onSelect(cat.nameHt),
                      )
                    : _InactiveTab(
                        label: cat.nameHt,
                        onTap: () => onSelect(cat.nameHt),
                      ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Tab widgets ───────────────────────────────────────────────────────────────

class _ActiveTab extends StatelessWidget {
  final String label;
  final String? asset;
  final String? emoji;
  final VoidCallback onTap;

  const _ActiveTab({
    required this.label,
    required this.onTap,
    this.asset,
    this.emoji,
  });

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
              if (asset != null)
                Image.asset(asset!, width: 15, height: 15, fit: BoxFit.contain)
              else if (emoji != null)
                Text(emoji!, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(
                label,
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
  final String label;
  final VoidCallback onTap;

  const _InactiveTab({required this.label, required this.onTap});

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
          label,
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
